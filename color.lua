local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- รวม Sound ID ที่ใช้ตรวจจับวาร์ปทั้ง 2 ตัว
local TARGET_SOUND_IDS = {
    ["108688312097046"] = "Smoke_Teleport_Poof_4", --[span_3](start_span)[span_3](end_span)
    ["108156925383225"] = "SidestepEnd"              --[span_4](start_span)[span_4](end_span)
}

local SPAM_SPEED = 0.03                     -- ความเร็วในการสแปมคลิก (วินาที)

-- แยกการ Pause ระยะใกล้ และ ระยะไกล
local CLOSE_PAUSE_DURATION = 0.35           -- ระยะเวลาพักการสแปมกรณี "อยู่ใกล้" (วินาที)
local FAR_PAUSE_DURATION = 1.0              -- ระยะเวลาพักการสแปมกรณี "อยู่ไกล" (วินาที)
local FAR_DISTANCE = 15.0                   -- ระยะห่างที่นับว่าเป็นระยะไกล (Studs)

-- ตัวแปรระบบ Burst Teleport
local TP_BURST_COUNT = 3                    -- จำนวนครั้งการเล่นเสียงรัว
local TP_BURST_WINDOW = 0.45                -- กรอบเวลาการเล่นเสียงรัว (วินาที)

local isHolding = false
local isLocked = true
local pauseEndTime = 0
local soundHistory = {}                     -- ประวัติเวลาเล่นเสียง
local trackedSounds = {}                    -- บันทึก Event เสียงที่ผูกไว้แล้ว

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
end)

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("LMBSpamMultiAudioGui")) or CoreGui:FindFirstChild("LMBSpamMultiAudioGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local HoldCorner = Instance.new("UICorner")

local LockButton = Instance.new("TextButton")
local LockCorner = Instance.new("UICorner")

local StatusLabel = Instance.new("TextLabel")
local StatusCorner = Instance.new("UICorner")

ScreenGui.Name = "LMBSpamMultiAudioGui"
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
StatusLabel.Text = "🛡️ SOUND SYSTEM READY"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSansBold

StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

-- ค้นหาบอสใน Workspace.Misc.AI
local function getBossRoot()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil end

    for _, child in ipairs(aiFolder:GetChildren()) do
        if child:IsA("Model") then
            local hum = child:FindFirstChildOfClass("Humanoid")
            local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
            if hum and hum.Health > 0 and root then
                return root
            end
        end
    end
    return nil
end

-- สั่ง Trigger Pause ระยะไกล
local function triggerFarPause()
    pauseEndTime = tick() + FAR_PAUSE_DURATION
    StatusLabel.Text = "🛑 SOUND: TOO FAR! (" .. FAR_PAUSE_DURATION .. "s)"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    if isHolding then
        HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    end
end

-- สั่ง Trigger Pause ระยะใกล้
local function triggerClosePause()
    pauseEndTime = tick() + CLOSE_PAUSE_DURATION
    StatusLabel.Text = "⚠️ SOUND: CLOSE RANGE! (" .. CLOSE_PAUSE_DURATION .. "s)"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    if isHolding then
        HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    end
end

-- สั่ง ยกเลิก Pause ทันที
local function cancelPause(reasonText)
    pauseEndTime = 0
    StatusLabel.Text = "⚡ " .. reasonText
    StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    if isHolding then
        HoldButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    end
end

-- ฟังก์ชันประมวลผลเมื่อตรวจพบการเล่นเสียง
local function onSoundTriggered(soundObj)
    local now = tick()
    table.insert(soundHistory, now)
    
    for i = #soundHistory, 1, -1 do
        if now - soundHistory[i] > TP_BURST_WINDOW then
            table.remove(soundHistory, i)
        end
    end

    if #soundHistory >= TP_BURST_COUNT then
        cancelPause("BURST SOUND! CANCEL PAUSE")
        soundHistory = {}
    else
        local bossRoot = getBossRoot()
        if bossRoot and myRoot and myRoot.Parent then
            local dist = (bossRoot.Position - myRoot.Position).Magnitude
            if dist >= FAR_DISTANCE then
                triggerFarPause()
            else
                triggerClosePause()
            end
        else
            triggerClosePause()
        end
    end
end

-- ตรวจสอบและลงทะเบียน Sound Instance
local function checkAndTrackSound(inst)
    if inst:IsA("Sound") and not trackedSounds[inst] then
        local soundIdStr = tostring(inst.SoundId)
        
        for targetId, _ in pairs(TARGET_SOUND_IDS) do
            if soundIdStr:find(targetId) then
                trackedSounds[inst] = true
                
                inst.Played:Connect(function()
                    onSoundTriggered(inst)
                end)
                
                if inst.IsPlaying then
                    onSoundTriggered(inst)
                end
                break
            end
        end
    end
end

-- สแกนเสียงทั้งหมด
local function scanAllSounds()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        checkAndTrackSound(obj)
    end
    for _, obj in ipairs(SoundService:GetDescendants()) do
        checkAndTrackSound(obj)
    end
end

Workspace.DescendantAdded:Connect(checkAndTrackSound)
SoundService.DescendantAdded:Connect(checkAndTrackSound)

scanAllSounds()

-- ลูปอัปเดต UI หน้าจอ
RunService.Heartbeat:Connect(function()
    local now = tick()
    if not isHolding and now >= pauseEndTime then
        StatusLabel.Text = "🛡️ SOUND SYSTEM READY"
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
