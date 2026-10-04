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
local SOUND_TYPES = {
    ["108688312097046"] = "TELEPORT", -- Smoke_Teleport_Poof_4
    ["108156925383225"] = "TELEPORT", -- SidestepEnd
    ["120714138513879"] = "TELEPORT", -- Cursed energy
    ["105373583781618"] = "KICK_HIT"  -- tk8_kick_hit (ท่าเตะบอส)
}

local MODES = {
    ["Normal"] = {
        Name = "⚔️ Normal Mode (สู้ปกติ)",
        ClosePause = 0.6,
        FarPause = 0.8,
        QDelay = 0.25 -- Normal Mode หน่วงเวลา 0.25 วินาทีก่อนกด Q
    },
    ["Cautious"] = {
        Name = "🛡️ Cautious Mode (สู้แบบระวัง)",
        ClosePause = 0.7,
        FarPause = 1.0,
        QDelay = 0.0 -- Cautious Mode กด Q ทันที
    }
}

local currentModeKey = "Normal"               
local SPAM_SPEED = 0.03                       
local FAR_DISTANCE = 15.0                     

local KICK_HIT_PAUSE = 0.5                    -- ระยะเวลา Pause เมื่อโดนท่าเตะ (วินาที)
local BURST2_PAUSE_DURATION = 0.25            -- Burst 2 ให้ Pause 0.25 วินาที
local BURST3_PAUSE_DURATION = 0.5             -- Burst 3 ให้ Pause 0.5 วินาทีก่อนเริ่มตี
local RETREAT_DURATION = 1.0                  -- ระยะเวลาถอยหลังรวม (วินาที)

local PRESS_BURST_THRESHOLD = 3               -- วาร์ป 3 ครั้ง = ถอยหลังสร้างระยะห่าง
local BURST_TIME_WINDOW = 0.6                -- กรอบเวลานับเสียงรัว (วินาที)
local SOUND_DEBOUNCE_TIME = 0.10             -- คูลดาวน์กันนับเสียงเบิ้ล (วินาที)
local LOCK_DURATION = 0.5                    

-- ตั้งค่าระบบตรวจจับการโดนดาเมจ
local DAMAGE_HIT_THRESHOLD = 2                -- ต้องโดนดาเมจอย่างน้อย 2 ครั้ง (ห้ามกดเมื่อโดนครั้งแรก)
local DAMAGE_TIME_WINDOW = 0.4                -- กรอบเวลานับการโดนรัวๆ (วินาที)
local Q_EVADE_COOLDOWN = 1.0                  -- คูลดาวน์ปุ่ม Q หลบ (วินาที)

--------------------------------------------------------------------------------
-- ตัวแปรระบบ
--------------------------------------------------------------------------------
local isHolding = false
local isLocked = true
local pauseEndTime = 0
local soundTimestamps = {}
local trackedSounds = {}
local lastSoundTriggerTime = {}

local isLockingLook = false
local lockLookEndTime = 0
local currentTargetRoot = nil
local lastFaceTime = 0

local damageTimestamps = {}
local lastQEvadeTime = 0
local lastHealth = 100

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)
local myHumanoid = myChar:WaitForChild("Humanoid", 5)

--------------------------------------------------------------------------------
-- ฟังก์ชันกดปุ่ม Q เพื่อหลบ (ตามเงื่อนไขของแต่ละโหมด)
--------------------------------------------------------------------------------
local function triggerQEvade()
    task.spawn(function()
        local activeProfile = MODES[currentModeKey]
        local delayTime = activeProfile.QDelay or 0
        
        -- หากตั้งค่าให้หน่วงเวลา (Normal Mode) จะรอตามกำหนดก่อนกด Q
        if delayTime > 0 then
            task.wait(delayTime)
        end
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

--------------------------------------------------------------------------------
-- ระบบ ตรวจจับ Health/Damage
--------------------------------------------------------------------------------
local function setupHealthListener(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    myHumanoid = hum
    lastHealth = hum.Health

    hum.HealthChanged:Connect(function(newHealth)
        local now = tick()
        
        -- ตรวจจับกรณีเลือดลดลง (โดนดาเมจ)
        if newHealth < lastHealth then
            table.insert(damageTimestamps, now)
            
            -- ลบค่า timestamp ที่เก่าเกินกรอบเวลา DAMAGE_TIME_WINDOW
            for i = #damageTimestamps, 1, -1 do
                if now - damageTimestamps[i] > DAMAGE_TIME_WINDOW then
                    table.remove(damageTimestamps, i)
                end
            end
            
            -- เงื่อนไข: โดนรัวๆ (2 ครั้งขึ้นไป) + ไม่อยู่ใน Cooldown ของ Q
            if #damageTimestamps >= DAMAGE_HIT_THRESHOLD and (now - lastQEvadeTime >= Q_EVADE_COOLDOWN) then
                lastQEvadeTime = now
                damageTimestamps = {} -- รีเซ็ตคาวต์
                
                triggerQEvade() -- เรียกใช้ฟังก์ชันหลบด้วย Q
                
                local modeName = (currentModeKey == "Normal") and "NORMAL (DELAY 0.25s)" or "CAUTIOUS (INSTANT)"
                StatusLabel.Text = "🚨 RAPID DAMAGE! Q EVADE [" .. modeName .. "]"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 100)
            end
        end
        
        lastHealth = newHealth
    end)
end

if myChar then setupHealthListener(myChar) end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
    isLockingLook = false
    currentTargetRoot = nil
    damageTimestamps = {}
    setupHealthListener(newChar)
end)

--------------------------------------------------------------------------------
-- จัดการ UI
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
StatusLabel.Position = UDim2.new(0.5, 0, 0.04, 0)
StatusLabel.Size = UDim2.new(0, 310, 0, 32)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.25
StatusLabel.Text = "🛡️ NORMAL MODE READY"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSansBold

StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusLabel

-- 1.5 หลอดสะสมค่า Burst Progress Bar
local BurstBarBg = Instance.new("Frame")
local BurstBarBgCorner = Instance.new("UICorner")
local BurstBarFill = Instance.new("Frame")
local BurstBarFillCorner = Instance.new("UICorner")
local BurstText = Instance.new("TextLabel")

BurstBarBg.Name = "BurstBarBg"
BurstBarBg.Parent = ScreenGui
BurstBarBg.AnchorPoint = Vector2.new(0.5, 0)
BurstBarBg.Position = UDim2.new(0.5, 0, 0.082, 0)
BurstBarBg.Size = UDim2.new(0, 310, 0, 14)
BurstBarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BurstBarBg.BackgroundTransparency = 0.3

BurstBarBgCorner.CornerRadius = UDim.new(0, 4)
BurstBarBgCorner.Parent = BurstBarBg

BurstBarFill.Name = "BurstBarFill"
BurstBarFill.Parent = BurstBarBg
BurstBarFill.Position = UDim2.new(0, 0, 0, 0)
BurstBarFill.Size = UDim2.new(0, 0, 1, 0)
BurstBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)

BurstBarFillCorner.CornerRadius = UDim.new(0, 4)
BurstBarFillCorner.Parent = BurstBarFill

BurstText.Name = "BurstText"
BurstText.Parent = BurstBarBg
BurstText.Size = UDim2.new(1, 0, 1, 0)
BurstText.BackgroundTransparency = 1
BurstText.Text = "BURST COUNT: 0/3"
BurstText.TextColor3 = Color3.fromRGB(255, 255, 255)
BurstText.TextSize = 10
BurstText.Font = Enum.Font.SourceSansBold

local function updateBurstBar(count)
    local percentage = math.clamp(count / PRESS_BURST_THRESHOLD, 0, 1)
    BurstBarFill:TweenSize(UDim2.new(percentage, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
    
    if count == 2 then
        BurstText.Text = "⚡ BURST x2 (PAUSE 0.25s)"
        BurstBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    elseif count >= 3 then
        BurstText.Text = "💥 BURST x3 (RETREAT + ATTACK)"
        BurstBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        BurstText.Text = "BURST COUNT: " .. count .. "/3"
        BurstBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    end
end

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

-- 3. ปุ่ม ล็อค/ปลดล็อก
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

NormalModeBtn.Name = "NormalModeBtn"
NormalModeBtn.Parent = MainMenuFrame
NormalModeBtn.Position = UDim2.new(0.08, 0, 0.3, 0)
NormalModeBtn.Size = UDim2.new(0.84, 0, 0, 35)
NormalModeBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
NormalModeBtn.Text = "⚔️ Normal (Q Delay 0.25s)"
NormalModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NormalModeBtn.TextSize = 12
NormalModeBtn.Font = Enum.Font.SourceSansBold

NormalBtnCorner.CornerRadius = UDim.new(0, 6)
NormalBtnCorner.Parent = NormalModeBtn

CautiousModeBtn.Name = "CautiousModeBtn"
CautiousModeBtn.Parent = MainMenuFrame
CautiousModeBtn.Position = UDim2.new(0.08, 0, 0.63, 0)
CautiousModeBtn.Size = UDim2.new(0.84, 0, 0, 35)
CautiousModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CautiousModeBtn.Text = "🛡️ Cautious (Q Instant)"
CautiousModeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CautiousModeBtn.TextSize = 12
CautiousBtnCorner.Parent = CautiousModeBtn

MenuToggleButton.MouseButton1Click:Connect(function()
    MainMenuFrame.Visible = not MainMenuFrame.Visible
end)

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
-- ฟังก์ชันจำลองการเดินถอยหลังหนีบอส
--------------------------------------------------------------------------------
local function retreatFromTarget()
    task.spawn(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
        task.wait(RETREAT_DURATION)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
    end)
end

--------------------------------------------------------------------------------
-- ฟังก์ชันค้นหาและหมุนมุมมอง
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
-- ประมวลผลเมื่อตรวจพบเสียง
--------------------------------------------------------------------------------
local function onSoundTriggered(soundCategory)
    local now = tick()
    
    local lastTrigger = lastSoundTriggerTime[soundCategory] or 0
    if now - lastTrigger < SOUND_DEBOUNCE_TIME then
        return 
    end
    lastSoundTriggerTime[soundCategory] = now

    local bossRoot, bossName = getBossRoot()
    if bossRoot then
        isLockingLook = true
        lockLookEndTime = now + LOCK_DURATION
        currentTargetRoot = bossRoot
    end

    if soundCategory == "KICK_HIT" then
        pauseEndTime = now + KICK_HIT_PAUSE
        
        StatusLabel.Text = "🦶 KICK DETECTED! PAUSE (" .. string.format("%.1f", KICK_HIT_PAUSE) .. "s)"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
        if isHolding then
            HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        end
        return
    end

    table.insert(soundTimestamps, now)
    
    for i = #soundTimestamps, 1, -1 do
        if now - soundTimestamps[i] > BURST_TIME_WINDOW then
            table.remove(soundTimestamps, i)
        end
    end

    local currentBurstCount = #soundTimestamps
    updateBurstBar(currentBurstCount)

    if currentBurstCount >= PRESS_BURST_THRESHOLD then
        soundTimestamps = {}
        
        retreatFromTarget()
        pauseEndTime = now + BURST3_PAUSE_DURATION
        
        StatusLabel.Text = "💥 BURST x3! RETREAT (PAUSE 0.5s -> ATTACK)"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        if isHolding then
            HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        end
        return
    end

    if currentBurstCount == 2 then
        pauseEndTime = now + BURST2_PAUSE_DURATION
        
        StatusLabel.Text = "⚡ BURST x2! PAUSE 0.25s"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
        if isHolding then
            HoldButton.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        end
        return
    end

    local activeProfile = MODES[currentModeKey]
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
        
        for targetId, category in pairs(SOUND_TYPES) do
            if soundIdStr:find(targetId) then
                trackedSounds[inst] = true
                
                inst.Played:Connect(function()
                    onSoundTriggered(category)
                end)
                
                if inst.IsPlaying then
                    onSoundTriggered(category)
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
-- Heartbeat Loop
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if not myRoot or not myRoot.Parent then
        if LocalPlayer.Character then
            myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    for i = #soundTimestamps, 1, -1 do
        if now - soundTimestamps[i] > BURST_TIME_WINDOW then
            table.remove(soundTimestamps, i)
            updateBurstBar(#soundTimestamps)
        end
    end

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

    if not isHolding and now >= pauseEndTime and not isLockingLook and (now - lastQEvadeTime > 1.2) then
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
                StatusLabel.Text = "⚔ SPAMMING ATTACK..."
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
