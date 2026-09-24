local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false
local MOVE_SPEED = 50 -- ความเร็วรถ (ปรับตามต้องการ 40-70 กำลังเนียน)

-- ฟังก์ชันดึง Part หลักของรถ
local function getVehiclePrimaryPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    
    local vehicle = hum.SeatPart:FindFirstAncestorOfClass("Model")
    return vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")) or hum.SeatPart
end

-- ฟังก์ชันขับรถไปตาม Path โดยใช้แรงขับเคลื่อน (Physics Driven)
local function driveToDestination(destinationPos)
    local vehiclePart = getVehiclePrimaryPart()
    if not vehiclePart then return false end

    -- สร้าง Pathfinding บนถนน
    local path = PathfindingService:CreatePath({
        AgentRadius = 7,
        AgentHeight = 5,
        AgentCanJump = false,
    })

    local success = pcall(function()
        path:ComputeAsync(vehiclePart.Position, destinationPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()
    local currentWaypointIndex = 1

    -- สร้าง BodyVelocity และ BodyGyro บังคับรถ
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = vehiclePart

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(0, 1e5, 0)
    bg.P = 10000
    bg.CFrame = vehiclePart.CFrame
    bg.Parent = vehiclePart

    while autoFarmActive and currentWaypointIndex <= #waypoints do
        RunService.Heartbeat:Wait()
        vehiclePart = getVehiclePrimaryPart()
        if not vehiclePart or not vehiclePart.Parent then break end

        local targetWaypoint = waypoints[currentWaypointIndex]
        local wayPointPos = targetWaypoint.Position
        local currentPos = vehiclePart.Position

        -- คำนวณทิศทางเดินรถ
        local direction = (Vector3.new(wayPointPos.X, currentPos.Y, wayPointPos.Z) - currentPos).Unit
        local distToWaypoint = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(wayPointPos.X, 0, wayPointPos.Z)).Magnitude

        -- สั่งแรงดันหมุนหัวรถและวิ่งไปข้างหน้า
        bg.CFrame = CFrame.lookAt(currentPos, Vector3.new(wayPointPos.X, currentPos.Y, wayPointPos.Z))
        bv.Velocity = direction * MOVE_SPEED

        -- เมื่อถึง Waypoint ถัดไป
        if distToWaypoint < 10 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
    end

    -- หยุดรถและลบ Force ออก
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    return true
end

-- ฟังก์ชันดึงจุดส่งงาน
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
                -- 1. ขับไปรับ NPC
                local npcsFolder = Workspace:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            if npcPart then
                                driveToDestination(npcPart.Position)
                                task.wait(2)
                                break
                            end
                        end
                    end
                end

                -- 2. ขับไปส่ง NPC
                if autoFarmActive then
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            driveToDestination(targetPart.Position)

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

-- GUI Toggle Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "PhysicsAutopilotGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "AutopilotBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 190, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "AUTOPILOT FARM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "AUTOPILOT FARM: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "AUTOPILOT FARM: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
