local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบ
local TARGET_ANIM_ID = "75098348371396" -- ID Animation วาร์ป/อมตะ
local SPAM_SPEED = 0.03                  -- ความเร็วในการสแปมคลิก
local PAUSE_DURATION = 1.0               -- ระยะเวลาพักการสแปม (วินาที)
local TELEPORT_THRESHOLD = 6.0           -- ระยะขยับกะทันหันที่นับว่าวาร์ป (กัน Endlag กระตุกสั้นๆ)

local isHolding = false
local isLocked = true
local pauseEndTime = 0

local currentBossHum = nil
local lastBossPos = nil
local animConnection = nil

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("LMBSpamUltraGui")) or CoreGui:FindFirstChild("LMBSpamUltraGui")
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

ScreenGui.Name = "LMBSpamUltraGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มสแปมหลัก
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

-- 2. ปุ่ม ล็อค/ปลดล็อก
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
local function getBossInfo()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil, nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil, nil end

    for _, child in ipairs(aiFolder:GetChildren()) do
        if child:IsA("Model") then
            local hum = child:FindFirstChildOfClass("Humanoid")
            local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
            if hum and hum.Health > 0 and root then
                return hum, root
            end
        end
    end
    return nil, nil
end

-- สั่ง Trigger Pause 1 วินาที
local function triggerPause(reasonText)
    pauseEndTime = tick() + PAUSE_DURATION
    StatusLabel.Text = "🛑 " .. reasonText .. " (1s)"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    if isHolding then
        HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    end
end

-- ระบบตรวจจับ Animation ตลอดเวลา (Background Listener)
local function updateAnimationTracker(bossHum)
    if bossHum and bossHum ~= currentBossHum then
        currentBossHum = bossHum
        if animConnection then animConnection:Disconnect() end
        
        local animator = bossHum:FindFirstChildOfClass("Animator") or bossHum
        
        animConnection = animator.AnimationPlayed:Connect(function(track)
            if track.Animation and track.Animation.AnimationId then
                if track.Animation.AnimationId:find(TARGET_ANIM_ID) then
                    triggerPause("ANIM DETECTED!")
                end
            end
        end)
    end
end

-- ลูปตรวจจับตำแหน่งวาร์ปสำรอง + รัน Tracker ตลอดเวลา (Heartbeat)
RunService.Heartbeat:Connect(function()
    local bossHum, bossRoot = getBossInfo()
    
    if bossHum and bossRoot then
        -- 1. ผูก Event ตรวจ Animation ตลอดเวลา (ไม่ว่าจะกดปุ่มอยู่หรือไม่)
        updateAnimationTracker(bossHum)
        
        -- 2. ระบบตรวจการ Teleport สำรอง (กรณีไม่เล่น Animation)
        local currentPos = bossRoot.Position
        if lastBossPos then
            local movedDist = (currentPos - lastBossPos).Magnitude
            if movedDist >= TELEPORT_THRESHOLD then
                triggerPause("TELEPORT DETECTED!")
            end
        end
        lastBossPos = currentPos
    else
        lastBossPos = nil
        currentBossHum = nil
    end

    -- อัปเดต UI เมื่อไม่ได้กดปุ่มและหมดระยะเวลา Pause
    if not isHolding and tick() >= pauseEndTime then
        StatusLabel.Text = "🛡️ SYSTEM READY"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    end
end)

-- จำลองการคลิกเมาส์ซ้าย (LMB)
local function clickLMB()
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- ลูปสแปม LMB
local function startSpam()
    task.spawn(function()
        while isHolding do
            local currentTime = tick()

            -- ถ้ายังไม่พ้นช่วง Pause สคริปต์จะไม่ยิงคลิก
            if currentTime < pauseEndTime then
                HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            else
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
end)

HoldButton.MouseLeave:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)
