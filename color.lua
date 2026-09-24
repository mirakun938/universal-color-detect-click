local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- ฟังก์ชันจำลองการกดปุ่มคีย์บอร์ด (W, A, S, D)
local function setPedal(key, isPressed)
    VirtualInputManager:SendKeyEvent(isPressed, key, false, game)
end

-- ฟังก์ชันหยุดรถ (ปล่อยทุกปุ่ม)
local function stopVehicle()
    setPedal(Enum.KeyCode.W, false)
    setPedal(Enum.KeyCode.S, false)
    setPedal(Enum.KeyCode.A, false)
    setPedal(Enum.KeyCode.D, false)
end

-- ฟังก์ชันหาตำแหน่งรถ / HumanoidRootPart
local function getVehiclePart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    
    local vehicle = hum.SeatPart:FindFirstAncestorOfClass("Model")
    return vehicle and (vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")) or char:FindFirstChild("HumanoidRootPart")
end

-- ฟังก์ชันขับรถด้วย Pathfinding + กดปุ่ม W A S D
local function driveToDestination(destinationPos)
    local vehiclePart = getVehiclePart()
    if not vehiclePart then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 8,
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
    local currentWaypointIndex = 1
    local lastPos = vehiclePart.Position
    local stuckTimer = 0

    while autoFarmActive and currentWaypointIndex <= #waypoints do
        RunService.Heartbeat:Wait()
        vehiclePart = getVehiclePart()
        if not vehiclePart then break end

        local targetWaypoint = waypoints[currentWaypointIndex]
        local wayPointPos = targetWaypoint.Position
        local currentPos = vehiclePart.Position

        local distToWaypoint = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(wayPointPos.X, 0, wayPointPos.Z)).Magnitude

        -- ระบบเช็คว่ารถติดหรือไม่
        if (currentPos - lastPos).Magnitude < 0.5 then
            stuckTimer = stuckTimer + 0.1
        else
            stuckTimer = 0
        end
        lastPos = currentPos

        -- ถ้ารถติด ให้ถอยหลังแก้ตำแหน่ง
        if stuckTimer > 2.5 then
            stopVehicle()
            setPedal(Enum.KeyCode.S, true) -- กด S ถอยหลัง
            setPedal(Enum.KeyCode.A, true)
            task.wait(1.5)
            stopVehicle()
            setPedal(Enum.KeyCode.W, true) -- กด W ตั้งหลัก
            task.wait(0.5)
            stuckTimer = 0
            break
        end

        -- บังคับทิศทางเลี้ยว (A / D)
        local relativeVector = vehiclePart.CFrame:VectorToObjectSpace(wayPointPos - currentPos)
        if relativeVector.X < -1.5 then
            setPedal(Enum.KeyCode.A, true)
            setPedal(Enum.KeyCode.D, false)
        elseif relativeVector.X > 1.5 then
            setPedal(Enum.KeyCode.D, true)
            setPedal(Enum.KeyCode.A, false)
        else
            setPedal(Enum.KeyCode.A, false)
            setPedal(Enum.KeyCode.D, false)
        end

        -- เหยียบคันเร่งเดินหน้า (W)
        setPedal(Enum.KeyCode.W, true)

        -- เมื่อถึงจุด Waypoint ถัดไป
        if distToWaypoint < 14 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
    end

    stopVehicle()
    return true
end

-- ฟังก์ชันค้นหาจุดส่ง (Location)
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
            local vehiclePart = getVehiclePart()
            if vehiclePart then
                -- 1. ไปรับ NPC
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

                -- 2. ไปส่ง NPC
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

ScreenGui.Name = "CustomTaxiAutopilotGui"
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
        stopVehicle()
    end
end)
