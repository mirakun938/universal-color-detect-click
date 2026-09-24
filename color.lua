local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- ค่าปรับแต่งการขับขี่
local TARGET_SPEED = 60 -- ความเร็วในการขับขี่ (ปรับเพิ่ม-ลดตามความเหมาะ)
local RAY_CAST_DISTANCE = 25 -- ระยะตรวจจับสิ่งกีดขวางข้างหน้า (ยิ่งเยอะยิ่งเบรกไว)

-- ฟังก์ชันดึง VehicleSeat ของรถที่เรานั่งอยู่
local function getVehicleSeat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.SeatPart
end

-- ฟังก์ชันยิง Raycast ตรวจจับสิ่งกีดขวางข้างหน้าป้องกันรถพัง
local function isObstacleAhead(vehiclePart)
    local rayOrigin = vehiclePart.Position + Vector3.new(0, 1, 0)
    local rayDirection = vehiclePart.CFrame.LookVector * RAY_CAST_DISTANCE
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {vehiclePart.Parent, LocalPlayer.Character}
    
    local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return result ~= nil
end

-- ฟังก์ชันขับรถไปยังจุดหมายอย่างเรียบเนียน (Autopilot Core)
local function driveToDestination(destinationPos)
    local seat = getVehicleSeat()
    if not seat or not seat:IsA("VehicleSeat") then return false end
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    local primaryPart = seat

    -- 1. สร้างเส้นทาง Pathfinding ตาม roads/terrain
    local path = PathfindingService:CreatePath({
        AgentRadius = 7, -- ขนาดตัวรถ
        AgentHeight = 6,
        AgentCanJump = false,
    })

    local success = pcall(function()
        path:ComputeAsync(primaryPart.Position, destinationPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()
    local currentWaypointIndex = 1
    local lastPos = primaryPart.Position
    local stuckTimer = 0

    -- ลูปควบคุมการขับขี่
    while autoFarmActive and currentWaypointIndex <= #waypoints do
        RunService.Heartbeat:Wait()
        seat = getVehicleSeat()
        if not seat then break end

        local targetWaypoint = waypoints[currentWaypointIndex]
        local wayPointPos = targetWaypoint.Position
        local currentPos = primaryPart.Position
        
        -- คำนวณระยะห่างระหว่างจุด Waypoint
        local distToWaypoint = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(wayPointPos.X, 0, wayPointPos.Z)).Magnitude

        -- ตรวจสอบว่ารถติดหรือไม่ (Stuck Detection)
        if (currentPos - lastPos).Magnitude < 0.5 then
            stuckTimer = stuckTimer + 0.1
        else
            stuckTimer = 0
        end
        lastPos = currentPos

        -- ถ้ารถติดสิ่งกีดขวาง ให้ใส่เกียร์ถอยหลังแก้ตำแหน่ง (Stuck Recovery)
        if stuckTimer > 2.5 then
            seat.ThrottleFloat = -1 -- ถอยหลัง
            seat.SteerFloat = -1
            task.wait(1.5)
            seat.ThrottleFloat = 1 -- เดินหน้าตั้งหลักใหม่
            seat.SteerFloat = 1
            task.wait(0.5)
            stuckTimer = 0
            break -- คำนวณคำสั่งใหม่
        end

        -- ระบบเบรกอัตโนมัติเมื่อเจอสิ่งกีดขวาง
        if isObstacleAhead(primaryPart) then
            seat.ThrottleFloat = 0.2 -- ชะลอความเร็วลง
        else
            seat.ThrottleFloat = 1.0 -- เหยียบคันเร่งตามปกติ
        end

        -- บังคับพวงมาลัยเลี้ยวเข้าหา Waypoint
        local relativeVector = primaryPart.CFrame:VectorToObjectSpace(wayPointPos - currentPos)
        local angle = math.atan2(-relativeVector.X, -relativeVector.Z)
        seat.SteerFloat = math.clamp(angle * 2, -1, 1)

        -- เมื่อขับถึงโหนดนี้แล้ว ให้เปลี่ยนไปโหนดถัดไป
        if distToWaypoint < 12 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
    end

    -- จอดรถเมื่อถึงจุดหมาย
    if seat then
        seat.ThrottleFloat = 0
        seat.SteerFloat = 0
    end
    return true
end

-- ฟังก์ชันค้นหาจุดส่งของ (Location)
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

-- Main Autopilot Farm Loop
task.spawn(function()
    while true do
        task.wait(1)
        if autoFarmActive then
            local seat = getVehicleSeat()
            if seat then
                -- 1. ขับไปรับผู้โดยสาร (NPC Customer)
                local npcsFolder = Workspace:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            if npcPart then
                                driveToDestination(npcPart.Position)
                                task.wait(2) -- รอให้ผู้โดยสารขึ้นรถ
                                break
                            end
                        end
                    end
                end

                -- 2. ขับไปส่งที่จุดหมาย
                if autoFarmActive then
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            driveToDestination(targetPart.Position)

                            -- ส่งสัญญาณจบงาน
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

ScreenGui.Name = "AutopilotTaxiGui"
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
        local seat = getVehicleSeat()
        if seat then
            seat.ThrottleFloat = 0
            seat.SteerFloat = 0
        end
    end
end)

print("Legit Autopilot Loaded!")
