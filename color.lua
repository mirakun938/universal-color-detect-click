local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false
local MAGNET_SPEED = 45 -- ความเร็วในการเคลื่อนที่ของแม่เหล็ก (30-60 กำลังเนียน)

-- ฟังก์ชันหา Part หลักของรถ
local function getVehiclePrimaryPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    
    local vehicle = hum.SeatPart:FindFirstAncestorOfClass("Model")
    return vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")) or hum.SeatPart
end

-- ฟังก์ชันขับเคลื่อนด้วยระบบแม่เหล็กนำทาง
local function magnetDriveTo(destinationPos)
    local vehiclePart = getVehiclePrimaryPart()
    if not vehiclePart then return false end

    -- คำนวณเส้นทาง
    local path = PathfindingService:CreatePath({
        AgentRadius = 15,
        AgentHeight = 6,
        AgentCanJump = false,
    })

    local success = pcall(function()
        path:ComputeAsync(vehiclePart.Position, destinationPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()

    -- สร้างจุดแม่เหล็ก (Magnet Node)
    local magnetPart = Instance.new("Part")
    magnetPart.Name = "TaxiMagnetNode"
    magnetPart.Size = Vector3.new(2, 2, 2)
    magnetPart.Transparency = 1
    magnetPart.CanCollide = false
    magnetPart.Anchored = true
    magnetPart.CFrame = vehiclePart.CFrame
    magnetPart.Parent = Workspace

    -- สร้างระบบแรงดูดแม่เหล็กติดกับตัวรถ
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.P = 12500 -- ความแรงในการดึงดูด
    bp.D = 1000  -- ลดการสั่นสะเทือน
    bp.Position = magnetPart.Position
    bp.Parent = vehiclePart

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(0, math.huge, 0)
    bg.P = 15000
    bg.CFrame = vehiclePart.CFrame
    bg.Parent = vehiclePart

    -- เลื่อนแม่เหล็กนำทางไปตาม Waypoints
    for i, wp in ipairs(waypoints) do
        if not autoFarmActive or not vehiclePart or not vehiclePart.Parent then break end

        local targetPos = wp.Position + Vector3.new(0, 1.5, 0) -- ยกสูงจากพื้นเล็กน้อยป้องกันใต้ท้องรถขูด
        local startPos = magnetPart.Position
        local distance = (startPos - targetPos).Magnitude
        local duration = distance / MAGNET_SPEED

        local startTime = tick()
        while (tick() - startTime) < duration and autoFarmActive do
            RunService.Heartbeat:Wait()
            local alpha = math.min((tick() - startTime) / duration, 1)
            local currentPos = startPos:Lerp(targetPos, alpha)
            
            magnetPart.Position = currentPos
            bp.Position = currentPos
            bg.CFrame = CFrame.lookAt(vehiclePart.Position, Vector3.new(targetPos.X, vehiclePart.Position.Y, targetPos.Z))
        end
    end

    -- ทำความสะอาดเมื่อถึงจุดหมาย
    if bp then bp:Destroy() end
    if bg then bg:Destroy() end
    if magnetPart then magnetPart:Destroy() end
    return true
end

-- ฟังก์ชันค้นหาเป้าหมายส่งงาน
local function getTargetLocation()
    local locationsFolder = Workspace:FindFirstChild("locations")
    if not locationsFolder then return nil end

    local targetName = nil
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                        local txt = desc.Text
                        if string.find(string.lower(txt), "go to") or string.find(string.lower(txt), "deliver") then
                            targetName = string.gsub(txt, "[Gg][Oo] [Tt][Oo] ", "")
                            targetName = string.gsub(targetName, "[Dd][Ee][Ll][Ii][Vv][Ee][Rr] [Tt][Oo] ", "")
                            break
                        end
                    end
                end
            end
        end
    end

    if targetName then
        local cleanTarget = string.lower(targetName)
        for _, child in ipairs(locationsFolder:GetChildren()) do
            if string.find(string.lower(child.Name), cleanTarget) or string.find(cleanTarget, string.lower(child.Name)) then
                return child
            end
        end
    end

    return locationsFolder:GetChildren()[1]
end

-- Main Loop
task.spawn(function()
    while true do
        task.wait(1)
        if autoFarmActive then
            local vehiclePart = getVehiclePrimaryPart()
            if vehiclePart then
                -- 1. ไปรับ NPC
                local npcsFolder = Workspace:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            if npcPart then
                                magnetDriveTo(npcPart.Position)
                                task.wait(2)
                                break
                            end
                        end
                    end
                end

                -- 2. ไปส่ง NPC
                if autoFarmActive then
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            magnetDriveTo(targetPart.Position)

                            -- ยิง Remote จบงาน
                            local remotes = {"deliveryfinserv", "deliveryfin", "delinterrupt"}
                            for _, remoteName in ipairs(remotes) do
                                local remote = ReplicatedStorage:FindFirstChild(remoteName, true) or Workspace:FindFirstChild(remoteName, true)
                                if remote and remote:IsA("RemoteEvent") then
                                    remote:FireServer(targetObj.Name)
                                    remote:FireServer()
                                end
                            end
                        end
                    end
                end
                task.wait(2)
            end
        end
    end
end)

-- UI Toggle Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "MagnetTaxiGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "MagnetBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 190, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "MAGNET FARM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "MAGNET FARM: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "MAGNET FARM: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
