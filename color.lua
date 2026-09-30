local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบ
local TELEPORT_THRESHOLD = 5  -- ระยะการขยับที่นับว่าวาร์ป (Studs)
local LOCK_DURATION = 0.5     -- ระยะเวลาล็อคมอง (วินาที)
local CHECK_INTERVAL = 0.05   -- ความหน่วงเวลาเช็กตำแหน่ง (ช่วยลดอาการกระตุก)

local lastPosition = nil
local isLocking = false
local lockEndTime = 0
local currentTargetRoot = nil
local lastCheckTime = 0

-- ลบ UI เก่าออก
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("BossTeleportTrackerGui")) or CoreGui:FindFirstChild("BossTeleportTrackerGui")
    if oldGui then oldGui:Destroy() end
end)

-- UI แสดงสถานะ
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
StatusLabel.Size = UDim2.new(0, 250, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "🔍 WAITING FOR BOSS (AI)..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansBold

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusLabel

-- ฟังก์ชันดึงตัว RootPart ของบอส/NPC ในโฟลเดอร์ Workspace.Misc.AI
local function getBossRoot()
    local miscFolder = Workspace:FindFirstChild("Misc")
    if not miscFolder then return nil end
    local aiFolder = miscFolder:FindFirstChild("AI")
    if not aiFolder then return nil end

    -- ค้นหาบอส/NPC ตัวแรกที่อยู่ในโฟลเดอร์ AI
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

-- ฟังก์ชันหมุนกล้องและตัวละคร
local function faceTarget(targetRoot)
    local char = LocalPlayer.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    
    if myRoot and targetRoot then
        local targetPos = targetRoot.Position
        
        -- หันตัวละคร
        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
        -- หันกล้อง
        if Camera then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end

-- ลูปตรวจจับการวาร์ป
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    
    -- หน่วงรอบการเช็กพิกัดเพื่อประหยัดสเปกเครื่อง
    if currentTime - lastCheckTime >= CHECK_INTERVAL then
        lastCheckTime = currentTime
        
        local bossRoot, bossName = getBossRoot()
        
        if bossRoot then
            local currentPos = bossRoot.Position
            
            if lastPosition then
                local movedDistance = (currentPos - lastPosition).Magnitude
                
                -- ถ้าขยับเกิน Threshold = วาร์ป
                if movedDistance >= TELEPORT_THRESHOLD then
                    isLocking = true
                    lockEndTime = currentTime + LOCK_DURATION
                    currentTargetRoot = bossRoot
                    
                    StatusLabel.Text = "⚠️️ " .. bossName:upper() .. " TELEPORTED!"
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

    -- ล็อคมองบอส 0.5 วินาที
    if isLocking then
        if currentTime < lockEndTime and currentTargetRoot and currentTargetRoot.Parent then
            faceTarget(currentTargetRoot)
        else
            isLocking = false
            currentTargetRoot = nil
        end
    end
end)
