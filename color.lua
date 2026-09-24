local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false
local MAGNET_SPEED = 40 -- ความเร็วแม่เหล็ก (30-50 กำลังเนียน)

-- ฟังก์ชันค้นหาชิ้นส่วนหลักของรถทุกรูปแบบ
local function getVehicleRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    
    local seat = hum.SeatPart
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    
    -- ค้นหา BasePart ที่ใหญ่ที่สุดในตัวรถ หรือใช้ Seat โดยตรง
    if vehicle then
        if vehicle.PrimaryPart then return vehicle.PrimaryPart end
        for _, part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") and part.Name:lower():find("frame") or part.Name:lower():find("body") or part.Name:lower():find("chassis") then
                return part
            end
        end
    end
    return seat
end

-- ฟังก์ชันแม่เหล็กนำทางแบบบังคับตำแหน่ง (Direct Magnet Drive)
local function magnetDriveTo(destinationPos)
    local rootPart = getVehicleRoot()
    if not rootPart then return false end

    -- คำนวณเส้นทางตามถนน
    local path = PathfindingService:CreatePath({
        AgentRadius = 12,
        AgentHeight = 6,
        AgentCanJump = false,
    })

    local success = pcall(function()
        path:ComputeAsync(rootPart.Position, destinationPos)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()

    -- ลูปเคลื่อนที่แม่เหล็กไปตามจุด Waypoint
    for _, wp in ipairs(waypoints) do
        if not autoFarmActive then break end
        
        rootPart = getVehicleRoot()
        if not rootPart or not rootPart.Parent then break end

        local targetPos = wp.Position + Vector3.new(0, 1.2, 0) -- ยกสูงเล็กน้อยกันติดพื้น
        local startPos = rootPart.Position
        local distance = (startPos - targetPos).Magnitude
        local duration = distance / MAGNET_SPEED

        local startTime = tick()
        while (tick() - startTime) < duration and autoFarmActive do
            RunService.Heartbeat:Wait()
            rootPart = getVehicleRoot()
            if not rootPart then break end

            local alpha = math.min((tick() - startTime) / duration, 1)
            local currentPos = startPos:Lerp(targetPos, alpha)
            
            -- ปรับทิศทางหัวรถและดูดไปยังตำแหน่งแม่เหล็ก
            local lookAtCFrame = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
            
            -- ถ้าทิศทางตรงกัน ให้หันหัวรถไปข้างหน้า
            if (targetPos - currentPos).Magnitude > 0.1 then
                rootPart.CFrame = lookAtCFrame
            else
                rootPart.CFrame = CFrame.new(currentPos) * rootPart.CFrame.Rotation
            end
        end
    end
    return true
end

-- ฟังก์ชันค้นหาจุดส่ง
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
            local rootPart = getVehicleRoot()
            if rootPart then
                -- 1. ขับไปรับ NPC
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

                -- 2. ขับไปส่ง NPC
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

ScreenGui.Name = "DirectMagnetTaxiGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "MagnetBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 190, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "DIRECT MAGNET: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "DIRECT MAGNET: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "DIRECT MAGNET: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
