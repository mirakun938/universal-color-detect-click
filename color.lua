local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบ
local MIN_TELEPORT_DIST = 6.0   -- ระยะขยับที่นับว่าวาร์ป
local LOCK_DURATION = 0.5       -- ระยะเวลาตั้งต้นในการมอง
local CHECK_INTERVAL = 0.04     -- ปรับความถี่เช็กพิกัดให้ปลอดภัยจาก Anti-Cheat (ป้องกันหลุด)

local lastPosition = nil
local isLocking = false
local lockEndTime = 0
local currentTargetRoot = nil
local lastCheckTime = 0
local lastFaceTime = 0

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)

-- อัปเดตเมื่อเกิดใหม่
LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
    lastPosition = nil
    isLocking = false
    currentTargetRoot = nil
end)

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("BossTrackerSafeGui")) or CoreGui:FindFirstChild("BossTrackerSafeGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI แสดงสถานะ
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "BossTrackerSafeGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Size = UDim2.new(0, 260, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "🔍 WAITING FOR BOSS..."
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

-- ฟังก์ชันหมุนมุมมองที่เสถียรและไม่โดน Anti-Cheat เตะ
local function safeFaceTarget(targetRoot)
    if not myRoot or not myRoot.Parent or not targetRoot or not targetRoot.Parent then return end
    
    local targetPos = targetRoot.Position
    local currentCam = Workspace.CurrentCamera or Camera
    
    -- 1. หมุนตัวละครไปหาทิศทางของบอส
    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
    
    -- 2. หมุนกล้องตามทันที
    if currentCam then
        currentCam.CFrame = CFrame.lookAt(currentCam.CFrame.Position, targetPos)
    end
end

-- ลูปการทำงานหลัก
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    if not myRoot or not myRoot.Parent then
        if LocalPlayer.Character then
            myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    -- ตรวจสอบพิกัดตามรอบ CHECK_INTERVAL
    if currentTime - lastCheckTime >= CHECK_INTERVAL then
        lastCheckTime = currentTime
        
        local bossRoot, bossName = getBossRoot()
        
        if bossRoot then
            local currentPos = bossRoot.Position
            
            if lastPosition then
                local movedDistance = (currentPos - lastPosition).Magnitude
                
                -- ตรวจจับการวาร์ป
                if movedDistance >= MIN_TELEPORT_DIST then
                    -- อัปเดตเป้าหมายใหม่ทันที และรีเซ็ตเวลาล็อค 0.5 วินาทีใหม่รองรับการวาร์ปรัวๆ ช่วงโกรธ
                    isLocking = true
                    lockEndTime = currentTime + LOCK_DURATION
                    currentTargetRoot = bossRoot
                    
                    StatusLabel.Text = "⚡ " .. bossName:upper() .. " TELEPORTED!"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                end
            end
            
            lastPosition = currentPos
            
            if not isLocking then
                StatusLabel.Text = "🎯 TRACKING: " .. bossName:upper()
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            end
        else
            lastPosition = nil
            if not isLocking then
                StatusLabel.Text = "🔍 WAITING FOR BOSS..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end
    end

    -- หันมองบอสเมื่ออยู่ในสถานะล็อค
    if isLocking then
        if currentTime < lockEndTime and currentTargetRoot and currentTargetRoot.Parent then
            -- ป้องกันการส่ง Packet หมุนกล้องถี่เกินไปจนหลุดออกจากเกม (จำกัดให้หมุนทุกๆ 0.02 วินาที)
            if currentTime - lastFaceTime >= 0.02 then
                lastFaceTime = currentTime
                safeFaceTarget(currentTargetRoot)
            end
        else
            isLocking = false
            currentTargetRoot = nil
        end
    end
end)
