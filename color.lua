local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบ
local TARGET_ANIM_ID = "75098348371396" -- ID Animation วาร์ป/อมตะ
local SPAM_SPEED = 0.03                  -- ความเร็วในการสแปมคลิก
local PAUSE_DURATION = 1.0               -- ระยะเวลาพักการสแปม (วินาที)

local isHolding = false
local isLocked = true
local isPausedByAnim = false
local pauseEndTime = 0

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("LMBSpamPureGui")) or CoreGui:FindFirstChild("LMBSpamPureGui")
    if oldGui then oldGui:Destroy() end
end)

-- UI แสดงสถานะและปุ่มกด
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local HoldCorner = Instance.new("UICorner")

local LockButton = Instance.new("TextButton")
local LockCorner = Instance.new("UICorner")

local StatusLabel = Instance.new("TextLabel")
local StatusCorner = Instance.new("UICorner")

ScreenGui.Name = "LMBSpamPureGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มสแปมหลัก (ตรงกลางหน้าจอ)
HoldButton.Name = "HoldSpamBtn"
HoldButton.Parent = ScreenGui
HoldButton.AnchorPoint = Vector2.new(0.5, 0.5)
HoldButton.Position = UDim2.new(0.5, 0, 0.5, 0)
HoldButton.Size = UDim2.new(0, 90, 0, 90)
HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
HoldButton.BackgroundTransparency = 0.3
HoldButton.Text = "HOLD TO\nSPAM LMB"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 14
HoldButton.Font = Enum.Font.SourceSansBold
HoldButton.Active = true
HoldButton.Draggable = not isLocked

HoldCorner.CornerRadius = UDim.new(0, 45)
HoldCorner.Parent = HoldButton

-- 2. ปุ่มเล็กสำหรับ ล็อค/ปลดล็อก การลาก
LockButton.Name = "LockToggleBtn"
LockButton.Parent = ScreenGui
LockButton.AnchorPoint = Vector2.new(0.5, 0)
LockButton.Position = UDim2.new(0.5, 0, 0.5, 55)
LockButton.Size = UDim2.new(0, 70, 0, 25)
LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LockButton.BackgroundTransparency = 0.2
LockButton.Text = "🔒 Lock"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 12
LockButton.Font = Enum.Font.SourceSansBold
LockButton.Active = true

LockCorner.CornerRadius = UDim.new(0, 6)
LockCorner.Parent = LockButton

LockButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    HoldButton.Draggable = not isLocked
    
    if isLocked then
        LockButton.Text = "🔒 Lock"
        LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        LockButton.Text = "🔓 Unlock"
        LockButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    end
end)

-- 3. แถบแสดงสถานะ
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Size = UDim2.new(0, 260, 0, 35)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "🛡️ SYSTEM READY"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSansBold

StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

-- ค้นหาบอสใน Workspace.Misc.AI
local function getBossHumanoid()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil end

    for _, child in ipairs(aiFolder:GetChildren()) do
        if child:IsA("Model") then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return hum
            end
        end
    end
    return nil
end

-- เช็กว่าบอสเล่น Animation 75098348371396 หรือไม่
local function isBossPlayingAnim(hum)
    if not hum then return false end
    
    local animator = hum:FindFirstChildOfClass("Animator") or hum
    local playingTracks = animator:GetPlayingAnimationTracks()

    for _, track in ipairs(playingTracks) do
        if track.Animation and track.Animation.AnimationId then
            if track.Animation.AnimationId:find(TARGET_ANIM_ID) then
                return true
            end
        end
    end
    return false
end

-- จำลองการคลิกเมาส์ซ้าย (LMB)
local function clickLMB()
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- ลูปสแปม LMB + เช็ก Animation เพื่อหยุดชั่วคราว
local function startSpam()
    task.spawn(function()
        while isHolding do
            local currentTime = tick()
            local bossHum = getBossHumanoid()

            -- 1. ตรวจจับ Animation
            if bossHum and isBossPlayingAnim(bossHum) then
                isPausedByAnim = true
                pauseEndTime = currentTime + PAUSE_DURATION
            end

            -- 2. จัดการการหยุดสแปม 1 วินาที
            if isPausedByAnim then
                if currentTime < pauseEndTime then
                    StatusLabel.Text = "🛑 ANIM DETECTED! PAUSED (1s)"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
                else
                    isPausedByAnim = false
                end
            end

            -- 3. ยิงสแปมเมื่อไม่ติดสถานะพัก
            if not isPausedByAnim then
                StatusLabel.Text = "⚔️ SPAMMING ATTACK..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                HoldButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
                
                clickLMB()
            end

            task.wait(SPAM_SPEED)
        end
    end)
end

-- ตรวจจับการกดค้าง
HoldButton.MouseButton1Down:Connect(function()
    if not isHolding then
        isHolding = true
        startSpam()
    end
end)

HoldButton.MouseButton1Up:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    StatusLabel.Text = "🛡️ SYSTEM READY"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
end)

HoldButton.MouseLeave:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    StatusLabel.Text = "🛡️ SYSTEM READY"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
end)
