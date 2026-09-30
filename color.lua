local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- รวม Sound ID ที่ใช้ดักจับหันมอง
local TARGET_SOUND_IDS = {
    ["108688312097046"] = "Smoke_Teleport_Poof_4", --[span_2](start_span)[span_2](end_span)
    ["108156925383225"] = "SidestepEnd"              --[span_3](start_span)[span_3](end_span)
}
local LOCK_DURATION = 0.5                  -- ระยะเวลาในการล็อคมอง (วินาที)

local isLocking = false
local lockEndTime = 0
local currentTargetRoot = nil
local lastFaceTime = 0
local trackedSounds = {}                   -- บันทึก Event เสียงที่ผูกไว้แล้ว

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)

-- อัปเดตเมื่อเกิดใหม่
LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
    isLocking = false
    currentTargetRoot = nil
end)

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("BossTrackerMultiAudioGui")) or CoreGui:FindFirstChild("BossTrackerMultiAudioGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI แสดงสถานะ
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "BossTrackerMultiAudioGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Size = UDim2.new(0, 260, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "🔍 WAITING FOR SOUND..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansBold

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusLabel

-- ค้นหาบอสใน Workspace.Misc.AI
local function getBossRoot()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil, nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil, nil end

    for _, child in ipairs(aiFolder:GetChildren()) do
        if child:IsA("Model") then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                if root then
                    return root, child.Name
                end
            end
        end
    end
    return nil, nil
end

-- ฟังก์ชันหมุนมุมมองเข้าหาบอส
local function safeFaceTarget(targetRoot)
    if not myRoot or not myRoot.Parent or not targetRoot or not targetRoot.Parent then return end
    
    local targetPos = targetRoot.Position
    local currentCam = Workspace.CurrentCamera or Camera
    
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
    
    if currentCam then
        currentCam.CFrame = CFrame.lookAt(currentCam.CFrame.Position, targetPos)
    end
end

-- ฟังก์ชันเมื่อตรวจจับพบเสียงวาร์ป
local function onSoundDetected()
    local bossRoot, bossName = getBossRoot()
    if bossRoot then
        isLocking = true
        lockEndTime = tick() + LOCK_DURATION
        currentTargetRoot = bossRoot
        
        StatusLabel.Text = "⚡ " .. bossName:upper() .. " SOUND TELEPORT!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
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
                    onSoundDetected()
                end)
                
                if inst.IsPlaying then
                    onSoundDetected()
                end
                break
            end
        end
    end
end

-- สแกนเสียงทั้งหมดใน Workspace และ SoundService
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

-- ลูปควบคุมกล้องและการหันมอง
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    if not myRoot or not myRoot.Parent then
        if LocalPlayer.Character then
            myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    if isLocking then
        if currentTime < lockEndTime and currentTargetRoot and currentTargetRoot.Parent then
            if currentTime - lastFaceTime >= 0.02 then
                lastFaceTime = currentTime
                safeFaceTarget(currentTargetRoot)
            end
        else
            isLocking = false
            currentTargetRoot = nil
        end
    else
        local bossRoot, bossName = getBossRoot()
        if bossRoot then
            StatusLabel.Text = "🎯 TRACKING: " .. bossName:upper()
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        else
            StatusLabel.Text = "🔍 WAITING FOR BOSS..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
end)
