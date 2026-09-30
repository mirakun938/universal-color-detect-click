local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- ตั้งค่าระบบ (CONFIG & MODES)
--------------------------------------------------------------------------------
local TARGET_SOUND_IDS = {
    ["108688312097046"] = "Smoke_Teleport_Poof_4", --[span_0](start_span)[span_0](end_span)
    ["108156925383225"] = "SidestepEnd"              --[span_1](start_span)[span_1](end_span)
}

-- กำหนดตารางโปรไฟล์โหมดการสู้
local MODES = {
    ["Normal"] = {
        Name = "⚔️ Normal Mode (สู้ปกติ)",
        ClosePause = 0.6,
        FarPause = 0.8
    },
    ["Cautious"] = {
        Name = "🛡️ Cautious Mode (สู้แบบระวัง)",
        ClosePause = 0.7,
        FarPause = 1.0
    }
}

local currentModeKey = "Normal"               -- โหมดเริ่มต้น (Normal)
local SPAM_SPEED = 0.03                       -- ความเร็วในการสแปมคลิก (วินาที)
local FAR_DISTANCE = 15.0                     -- ระยะห่างที่นับว่าเป็นระยะไกล (Studs)

-- การปลด Pause เมื่อบอสวาร์ปรัวๆ (Burst Teleport)
local BURST_COUNT_THRESHOLD = 3              -- จำนวนครั้งการเล่นเสียงติดกัน
local BURST_TIME_WINDOW = 0.6                -- กรอบเวลานับเสียงรัว (วินาที)

-- การหมุนหันมอง (Auto Look At)
local LOCK_DURATION = 0.5                    -- ระยะเวลาในการหมุนตัว/กล้องมองบอส (วินาที)

--------------------------------------------------------------------------------
-- ตัวแปรระบบ
--------------------------------------------------------------------------------
local isHolding = false
local isLocked = true
local pauseEndTime = 0
local soundTimestamps = {}
local trackedSounds = {}

local isLockingLook = false
local lockLookEndTime = 0
local currentTargetRoot = nil
local lastFaceTime = 0

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
    isLockingLook = false
    currentTargetRoot = nil
end)

--------------------------------------------------------------------------------
-- จัดการ UI (Main Menu & Controls)
--------------------------------------------------------------------------------
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("ComboSpamMenuGui")) or CoreGui:FindFirstChild("ComboSpamMenuGui")
    if oldGui then oldGui:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ComboSpamMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. แถบแสดงสถานะหลัก
local StatusLabel = Instance.new("TextLabel")
local StatusCorner = Instance.new("UICorner")

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.05, 0)
StatusLabel.Size = UDim2.new(0, 310, 0, 35)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.25
StatusLabel.Text = "🛡️ NORMAL MODE READY"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSansBold

StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

-- 2. ปุ่มสแปมหลัก (HOLD TO SPAM)
local HoldButton = Instance.new("TextButton")
local HoldCorner = Instance.new("UICorner")

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

-- 3. ปุ่ม ล็อค/ปลดล็อก ปุ่มหลัก
local LockButton = Instance.new("TextButton")
local LockCorner = Instance.new("UICorner")

LockButton.Name = "LockToggleBtn"
LockButton.Parent = ScreenGui
LockButton.AnchorPoint = Vector2.new(0.5, 0)
LockButton.Position = UDim2.new(0.5, -40, 0.5, 55)
LockButton.Size = UDim2.new(0, 75, 0, 25)
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
    LockButton.Text = isLocked and "🔒 Lock" or "🔓 Unlock"
    LockButton.BackgroundColor3 = isLocked and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(200, 120, 0)
end)

-- 4. ปุ่มเปิด/ปิด Main Menu
local MenuToggleButton = Instance.new("TextButton")
local MenuToggleCorner = Instance.new("UICorner")

MenuToggleButton.Name = "MenuToggleBtn"
MenuToggleButton.Parent = ScreenGui
MenuToggleButton.AnchorPoint = Vector2.new(0.5, 0)
MenuToggleButton.Position = UDim2.new(0.5, 45, 0.5, 55)
MenuToggleButton.Size = UDim2.new(0, 75, 0, 25)
MenuToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
MenuToggleButton.BackgroundTransparency = 0.2
MenuToggleButton.Text = "⚙️ Menu"
MenuToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuToggleButton.TextSize = 12
MenuToggleButton.Font = Enum.Font.SourceSansBold

MenuToggleCorner.CornerRadius = UDim.new(0, 6)
MenuToggleCorner.Parent = MenuToggleButton

-- 5. หน้าต่าง Main Menu Frame
local MainMenuFrame = Instance.new("Frame")
local MenuCorner = Instance.new("UICorner")
local MenuTitle = Instance.new("TextLabel")
local NormalModeBtn = Instance.new("TextButton")
local NormalBtnCorner = Instance.new("UICorner")
local CautiousModeBtn = Instance.new("TextButton")
local CautiousBtnCorner = Instance.new("UICorner")

MainMenuFrame.Name = "MainMenuFrame"
MainMenuFrame.Parent = ScreenGui
MainMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainMenuFrame.Position = UDim2.new(0.5, 0, 0.5, -90)
MainMenuFrame.Size = UDim2.new(0, 240, 0, 130)
MainMenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainMenuFrame.BackgroundTransparency = 0.15
MainMenuFrame.Visible = false

MenuCorner.CornerRadius = UDim.new(0, 10)
MenuCorner.Parent = MainMenuFrame

MenuTitle.Name = "MenuTitle"
MenuTitle.Parent = MainMenuFrame
MenuTitle.Size = UDim2.new(1, 0, 0, 30)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "⚙️ SELECT COMBAT MODE"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.TextSize = 13
MenuTitle.Font = Enum.Font.SourceSansBold

-- ปุ่ม Normal Mode
NormalModeBtn.Name = "NormalModeBtn"
NormalModeBtn.Parent = MainMenuFrame
NormalModeBtn.Position = UDim2.new(0.08, 0, 0.3, 0)
NormalModeBtn.Size = UDim2.new(0.84, 0, 0, 35)
NormalModeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
NormalModeBtn.Text = "⚔️ Normal (Close 0.6s)"
NormalModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NormalModeBtn.TextSize = 12
NormalModeBtn.Font = Enum.Font.SourceSansBold

NormalBtnCorner.CornerRadius = UDim.new(0, 6)
NormalBtnCorner.Parent = NormalModeBtn

-- ปุ่ม Cautious Mode
CautiousModeBtn.Name = "CautiousModeBtn"
CautiousModeBtn.Parent = MainMenuFrame
CautiousModeBtn.Position = UDim2.new(0.08, 0, 0.63, 0)
CautiousModeBtn.Size = UDim2.new(0.84, 0, 0, 35)
CautiousModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CautiousModeBtn.Text = "🛡️ Cautious (Close 0.7s)"
CautiousModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CautiousModeBtn.TextSize = 12
CautiousModeBtn.Font = Enum.Font.SourceSansBold

CautiousBtnCorner.CornerRadius = UDim.new(0, 6)
CautiousBtnCorner.Parent = CautiousModeBtn

-- ควบคุมการเปิด/ปิด เมนู
MenuToggleButton.MouseButton1Click:Connect(function()
    MainMenuFrame.Visible = not MainMenuFrame.Visible
end)

-- ฟังก์ชันสำหรับอัปเดตปุ่มโหมด
local function setCombatMode(modeKey)
    currentModeKey = modeKey
    if modeKey == "Normal" then
        NormalModeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        NormalModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CautiousModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        CautiousModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        NormalModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        NormalModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        CautiousModeBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        CautiousModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    StatusLabel.Text = MODES[modeKey].Name:upper() .. " READY"
    StatusLabel.TextColor3 = (modeKey == "Normal") and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 180, 0)
end

NormalModeBtn.MouseButton1Click:Connect(function() setCombatMode("Normal") end)
CautiousModeBtn.MouseButton1Click:Connect(function() setCombatMode("Cautious") end)

--------------------------------------------------------------------------------
-- ฟังก์ชันค้นหาและหมุนมุมมอง (Auto Look At)
--------------------------------------------------------------------------------
local function getBossRoot()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil, nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil, nil end

    for _, child in ipairs(aiFolder:GetChildren()) do
        if child:IsA("Model") then
            local hum = child:FindFirstChildOfClass("Humanoid")
            local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
            if hum and hum.Health > 0 and root then
                return root, child.Name
            end
        end
    end
    return nil, nil
end

local function safeFaceTarget(targetRoot)
    if not myRoot or not myRoot.Parent or not targetRoot or not targetRoot.Parent then return end
    
    local targetPos = targetRoot.Position
    local currentCam = Workspace.CurrentCamera or Camera
    
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
    
    if currentCam then
        currentCam.CFrame = CFrame.lookAt(currentCam.CFrame.Position, targetPos)
    end
end

--------------------------------------------------------------------------------
-- ประมวลผลเมื่อตรวจพบเสียงวาร์ป (Sound Event Processor)
--------------------------------------------------------------------------------
local function onSoundTriggered()
    local now = tick()
    local activeProfile = MODES[currentModeKey]
    
    -- === 1. Auto Look At ===
    local bossRoot, bossName = getBossRoot()
    if bossRoot then
        isLockingLook = true
        lockLookEndTime = now + LOCK_DURATION
        currentTargetRoot = bossRoot
    end

    -- === 2. LMB Spam Pause / Burst ===
    table.insert(soundTimestamps, now)
    
    for i = #soundTimestamps, 1, -1 do
        if now - soundTimestamps[i] > BURST_TIME_WINDOW then
            table.remove(soundTimestamps, i)
        end
    end

    -- ตรวจพบเสียงวาร์ปรัวครบ 3 ครั้ง -> ปลด Pause
    if #soundTimestamps >= BURST_COUNT_THRESHOLD then
        pauseEndTime = 0
        soundTimestamps = {}
        
        StatusLabel.Text = "⚡ BURST x3! UNPAUSE & LOOKING!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
        if isHolding then
            HoldButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        end
        return
    end

    -- วาร์ปปกติ -> ดึงค่า Pause จากโหมดปัจจุบันที่เลือก
    local duration = activeProfile.ClosePause
    local distanceType = "CLOSE"

    if bossRoot and myRoot and myRoot.Parent then
        local dist = (bossRoot.Position - myRoot.Position).Magnitude
        if dist >= FAR_DISTANCE then
            duration = activeProfile.FarPause
            distanceType = "FAR"
        end
    end

    pauseEndTime = now + duration

    StatusLabel.Text = "👀 LOOK + ⚠️ " .. distanceType .. " PAUSE (" .. string.format("%.1f", duration) .. "s)"
    StatusLabel.TextColor3 = (distanceType == "FAR") and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 150, 0)
    
    if isHolding then
        HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    end
end

--------------------------------------------------------------------------------
-- ตรวจจับและสแกน Sound Instance
--------------------------------------------------------------------------------
local function checkAndTrackSound(inst)
    if inst:IsA("Sound") and not trackedSounds[inst] then
        local soundIdStr = tostring(inst.SoundId)
        
        for targetId, _ in pairs(TARGET_SOUND_IDS) do
            if soundIdStr:find(targetId) then
                trackedSounds[inst] = true
                
                inst.Played:Connect(function()
                    onSoundTriggered()
                end)
                
                if inst.IsPlaying then
                    onSoundTriggered()
                end
                break
            end
        end
    end
end

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

--------------------------------------------------------------------------------
-- Heartbeat Loop (ควบคุม Auto Look At + อัปเดต UI)
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if not myRoot or not myRoot.Parent then
        if LocalPlayer.Character then
            myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    -- 1. ล็อคมุมมอง
    if isLockingLook then
        if now < lockLookEndTime and currentTargetRoot and currentTargetRoot.Parent then
            if now - lastFaceTime >= 0.02 then
                lastFaceTime = now
                safeFaceTarget(currentTargetRoot)
            end
        else
            isLockingLook = false
            currentTargetRoot = nil
        end
    end

    -- 2. อัปเดตข้อความเมื่ออยู่นอกสถานะ Pause
    if not isHolding and now >= pauseEndTime and not isLockingLook then
        local bossRoot, bossName = getBossRoot()
        if bossRoot then
            StatusLabel.Text = "🎯 [" .. currentModeKey:upper() .. "] TRACKING: " .. bossName:upper()
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        else
            StatusLabel.Text = "🛡️ " .. currentModeKey:upper() .. " MODE READY"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        end
    end
end)

--------------------------------------------------------------------------------
-- ลูปสแปมเมาส์ซ้าย (LMB Attack Loop)
--------------------------------------------------------------------------------
local function clickLMB()
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

local function startSpam()
    task.spawn(function()
        while isHolding do
            local currentTime = tick()

            if currentTime < pauseEndTime then
                HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            else
                StatusLabel.Text = "⚔️️ SPAMMING ATTACK..."
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
