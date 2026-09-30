local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบการตรวจจับ
local MIN_TELEPORT_DIST = 8.0  -- ระยะขั้นต่ำที่นับว่าวาร์ปหนีจริง (แก้ปัญหาโดนฟันแล้วขยับนิดหน่อย)
local LOCK_DURATION = 0.5      -- ระยะเวลาล็อคมอง (วินาที)
local CHECK_INTERVAL = 0.03    -- ความถี่ในการเช็กพิกัด

local lastPosition = nil
local isLocking = false
local lockEndTime = 0
local currentTargetRoot = nil
local lastCheckTime = 0

-- ตัวแปรเก็บ Character & HumanoidRootPart ล่าสุด
local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local myRoot = myChar:WaitForChild("HumanoidRootPart", 5)

-- อัปเดตตัวละครอัตโนมัติเมื่อเกิดใหม่ (ตายแล้วสปอว์นใหม่)
LocalPlayer.CharacterAdded:Connect(function(newChar)
    myChar = newChar
    myRoot = newChar:WaitForChild("HumanoidRootPart", 5)
    Camera = Workspace.CurrentCamera
    lastPosition = nil
    isLocking = false
end)

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("BossTeleportTrackerGui")) or CoreGui:FindFirstChild("BossTeleportTrackerGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI แสดงสถานะ
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "BossTeleportTrackerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Size = UDim2.new(0, 260, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "🔍 WAITING FOR BOSS (AI)..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansBold

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusLabel

-- ฟังก์ชันค้นหาบอส/NPC ใน Workspace.Misc.AI
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

-- ฟังก์ชันหมุนกล้องและตัวละครนุ่มนวล (Lerp)
local function smoothFaceTarget(targetRoot)
    if not myRoot or not myRoot.Parent or not targetRoot or not targetRoot.Parent then return end
    
    local targetPos = targetRoot.Position
    local currentCam = Workspace.CurrentCamera or Camera
    
    -- 1. หมุนตัวละครไปหาเป้าหมาย
    local lookAtCFrame = CFrame.new(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
    myRoot.CFrame = myRoot.CFrame:Lerp(lookAtCFrame, 0.4)
    
    -- 2. หมุนกล้องไปหาเป้าหมายอย่างราบรื่น
    if currentCam then
        local targetCamCFrame = CFrame.new(currentCam.CFrame.Position, targetPos)
        currentCam.CFrame = currentCam.CFrame:Lerp(targetCamCFrame, 0.4)
    end
end

-- ลูปตรวจจับการวาร์ปและควบคุมการมอง
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    
    -- ตรวจสอบและอัปเดตตัวละครให้ชัวร์
    if not myRoot or not myRoot.Parent then
        if LocalPlayer.Character then
            myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
    end

    -- เช็กพิกัดบอสตามรอบเวลา
    if currentTime - lastCheckTime >= CHECK_INTERVAL then
        lastCheckTime = currentTime
        
        local bossRoot, bossName = getBossRoot()
        
        if bossRoot then
            local currentPos = bossRoot.Position
            
            if lastPosition then
                local movedDistance = (currentPos - lastPosition).Magnitude
                
                -- ตรวจจับการวาร์ป (ต้องไกลกว่า MIN_TELEPORT_DIST เพื่อกันจังหวะฟันแล้วชักกระตุก)
                if movedDistance >= MIN_TELEPORT_DIST then
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
                StatusLabel.Text = "🔍 WAITING FOR BOSS (AI)..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end
    end

    -- ทำการหันมองบอสแบบนุ่มนวลเมื่ออยู่ในช่วงเวลาล็อค 0.5 วินาที
    if isLocking then
        if currentTime < lockEndTime and currentTargetRoot and currentTargetRoot.Parent then
            smoothFaceTarget(currentTargetRoot)
        else
            isLocking = false
            currentTargetRoot = nil
        end
    end
end)
