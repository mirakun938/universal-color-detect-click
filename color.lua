local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ตั้งค่าระบบ
local TELEPORT_THRESHOLD = 5 -- ระยะการขยับขั้นต่ำที่นับว่าเป็น Teleport (Studs)
local LOCK_DURATION = 0.5    -- ระยะเวลาล็อคมอง NPC (วินาที)
local MAX_DETECTION_DIST = 150 -- ระยะตรวจจับ NPC รอบตัว

local lastPositions = {}
local isLocking = false
local lockEndTime = 0
local currentTargetRoot = nil

-- ลบ UI เก่าออกหากมีอยู่
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("TeleportTrackerGui")) or CoreGui:FindFirstChild("TeleportTrackerGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI แสดงสถานะแจ้งเตือน
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "TeleportTrackerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0)
StatusLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
StatusLabel.Size = UDim2.new(0, 220, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "👁️ Teleport Tracker: READY"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSansBold

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusLabel

-- ฟังก์ชันค้นหา NPC ทั้งหมดในระยะ
local function getNearbyNPCs()
    local npcs = {}
    local char = LocalPlayer.Character
    if not char then return npcs end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return npcs end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= char and obj.Health > 0 then
            local targetChar = obj.Parent
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChildWhichIsA("BasePart")
            
            local isOtherPlayer = Players:GetPlayerFromCharacter(targetChar)
            if targetRoot and not isOtherPlayer then
                local dist = (targetRoot.Position - myRoot.Position).Magnitude
                if dist <= MAX_DETECTION_DIST then
                    table.insert(npcs, targetRoot)
                end
            end
        end
    end
    return npcs
end

-- ฟังก์ชันหมุนกล้องและตัวละครไปหาเป้าหมาย
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

-- ลูปตรวจจับการ Teleport และจัดการการมอง (RenderStepped)
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    local currentNPCs = getNearbyNPCs()
    local currentFramePositions = {}

    for _, root in ipairs(currentNPCs) do
        local instanceId = root:GetDebugId()
        local currentPos = root.Position
        currentFramePositions[instanceId] = currentPos

        -- ตรวจสอบว่ามีตำแหน่งเก่าเก็บไว้หรือไม่
        if lastPositions[instanceId] then
            local previousPos = lastPositions[instanceId]
            local movedDistance = (currentPos - previousPos).Magnitude

            -- ตรวจจับว่าตำแหน่งเปลี่ยนกะทันหันเกินค่า Threshold (การ Teleport)
            if movedDistance >= TELEPORT_THRESHOLD then
                isLocking = true
                lockEndTime = currentTime + LOCK_DURATION
                currentTargetRoot = root
                
                -- อัปเดต UI แจ้งเตือน
                StatusLabel.Text = "⚠️ TELEPORT DETECTED!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end

    -- บันทึกตำแหน่งล่าสุดไว้เปรียบเทียบในเฟรมถัดไป
    lastPositions = currentFramePositions

    -- หากอยู่ในช่วงเวลา ล็อคมอง 0.5 วินาที
    if isLocking then
        if currentTime < lockEndTime and currentTargetRoot and currentTargetRoot.Parent then
            faceTarget(currentTargetRoot)
        else
            isLocking = false
            currentTargetRoot = nil
            StatusLabel.Text = "👁️ Teleport Tracker: READY"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        end
    end
end)
