local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- กำหนดระยะตรวจจับ Player คนอื่น (150 Studs)
local PLAYER_SAFE_DISTANCE = 150

-- พิกัดจุดทางลัด
local SHORTCUT_POS = Vector3.new(-135.0, 5.7, 3447.1)

-- ค้นหาตัวรถ
local function getVehicleModel()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil, nil end
    
    local seat = hum.SeatPart
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    local rootPart = seat
    
    if vehicle then
        if vehicle.PrimaryPart then 
            rootPart = vehicle.PrimaryPart 
        else
            for _, part in ipairs(vehicle:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("frame") or part.Name:lower():find("body") or part.Name:lower():find("chassis")) then
                    rootPart = part
                    break
                end
            end
        end
    end
    return vehicle, rootPart
end

-- ฟังก์ชันเช็กว่ามี Player คนอื่นอยู่ใกล้ตำแหน่งที่กำหนดหรือไม่ (ระยะ 150 Studs)
local function isPlayerNearbyPos(targetPos, range)
    range = range or PLAYER_SAFE_DISTANCE
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
            if pRoot then
                local dist = (pRoot.Position - targetPos).Magnitude
                if dist <= range then
                    return true -- มี Player คนอื่นอยู่ใกล้
                end
            end
        end
    end
    return false
end

-- ฟังก์ชันเช็กว่ารอบตัวเรามี Player คนอื่นอยู่ใกล้ไหม (ถ้ามี ให้รอจนกว่าจะไป)
local function waitUntilAreaClear()
    local _, rootPart = getVehicleModel()
    if not rootPart then return end

    while autoFarmActive and isPlayerNearbyPos(rootPart.Position, PLAYER_SAFE_DISTANCE) do
        task.wait(1) -- รอตราบใดที่มี Player อยู่ใกล้เราในระยะ 150 Studs
    end
end

-- Safe Teleport (พร้อมระบบรอพื้นที่เคลียร์)
local function safeTeleport(targetPos)
    -- เช็กว่ารอบตัวเราไม่มีใครอยู่ใกล้ก่อนวาร์ป
    waitUntilAreaClear()
    
    local vehicle, rootPart = getVehicleModel()
    if not rootPart then return false end

    local partsToDisable = {}
    if vehicle then
        for _, part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                table.insert(partsToDisable, part)
                part.CanCollide = false
            end
        end
    end

    for _, part in ipairs(vehicle and vehicle:GetDescendants() or {rootPart}) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    local safeCFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 0))
    if vehicle and vehicle.PrimaryPart then
        vehicle:SetPrimaryPartCFrame(safeCFrame)
    else
        rootPart.CFrame = safeCFrame
    end

    task.wait(0.1)

    for _, part in ipairs(partsToDisable) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end

    return true
end

-- ฟังก์ชันเช็กว่า NPC ตัวนี้โดนรับไปแล้วหรือยัง
local function isNPCTaken(npc)
    if npc:FindFirstChild("Occupied") or npc:FindFirstChild("Car") or npc:FindFirstChild("InVehicle") then
        return true
    end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        return true
    end
    return false
end

-- ตรวจจับสถานะเควส (เช็ก UI)
local function checkQuestStatus()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local status = {
        hasPassengerOnBoard = false,
        hasTopSpeedQuest = false,
        isTopSpeedDone = false,
        hasShortcutQuest = false,
        isShortcutDone = false
    }

    if not playerGui then return status end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local txt = desc.Text:lower()
                    
                    if string.find(txt, "perfect delivery") or string.find(txt, "go to") or string.find(txt, "deliver to") then
                        status.hasPassengerOnBoard = true
                    end

                    if string.find(txt, "top speed") or string.find(txt, "maximum speed") or string.find(txt, "reach your taxi") then
                        status.hasTopSpeedQuest = true
                        if desc.TextColor3.G > 0.5 and desc.TextColor3.R < 0.5 then
                            status.isTopSpeedDone = true
                        end
                    end
                    
                    if string.find(txt, "take a shortcut") and not string.find(txt, "don't") and not string.find(txt, "dont") then
                        status.hasShortcutQuest = true
                        if desc.TextColor3.G > 0.5 and desc.TextColor3.R < 0.5 then
                            status.isShortcutDone = true
                        end
                    end
                end
            end
        end
    end
    return status
end

-- ค้นหาจุดหมายปลายทาง
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
        task.wait(0.5)
        if autoFarmActive then
            local vehicle, rootPart = getVehicleModel()
            if rootPart then
                
                -- Step 1: วาร์ปไปรับ NPC (เช็กระยะ 150 Studs ป้องกันโดนแย่ง/เห็น)
                local passengerSeated = false
                local npcsFolder = Workspace:FindFirstChild("npcs")
                
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        
                        local isCustomer = (npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer"))
                        
                        if isCustomer and not isNPCTaken(npc) then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            
                            -- เช็กว่าไม่มี Player คนอื่นอยู่ในระยะ 150 Studs รอบตัว NPC
                            if npcPart and not isPlayerNearbyPos(npcPart.Position, 150) then
                                
                                -- วาร์ปไปหา NPC (จะรอจนกว่ารอบตัวเราจะเคลียร์ก่อนด้วย)
                                safeTeleport(npcPart.Position)
                                
                                -- Step 2: รอผู้โดยสารขึ้นรถ (Timeout 15 วินาที)
                                local startTime = tick()
                                while (tick() - startTime) < 15 and autoFarmActive do
                                    task.wait(0.5)
                                    local qStatus = checkQuestStatus()
                                    if qStatus.hasPassengerOnBoard then
                                        passengerSeated = true
                                        break
                                    end
                                end

                                if passengerSeated then
                                    break
                                end
                            end
                        end
                    end
                end

                -- Step 3: ทำเควสจนกว่าข้อความจะเปลี่ยนเป็นสีเขียว
                if autoFarmActive and passengerSeated then
                    local attempts = 0
                    while autoFarmActive and attempts < 12 do
                        local qStatus = checkQuestStatus()
                        
                        local topSpeedReady = not qStatus.hasTopSpeedQuest or qStatus.isTopSpeedDone
                        local shortcutReady = not qStatus.hasShortcutQuest or qStatus.isShortcutDone
                        
                        if topSpeedReady and shortcutReady then
                            break
                        end

                        -- ทำเควส Top Speed
                        if qStatus.hasTopSpeedQuest and not qStatus.isTopSpeedDone then
                            local currentPos = rootPart.Position
                            safeTeleport(currentPos + Vector3.new(0, 850, 0))
                            task.wait(0.2)
                            for _, part in ipairs(vehicle and vehicle:GetDescendants() or {rootPart}) do
                                if part:IsA("BasePart") then
                                    part.AssemblyLinearVelocity = Vector3.new(0, -400, 0)
                                end
                            end
                            task.wait(0.8)
                        end

                        -- ทำเควส Shortcut
                        if qStatus.hasShortcutQuest and not qStatus.isShortcutDone then
                            safeTeleport(SHORTCUT_POS)
                            task.wait(0.5)
                        end

                        attempts = attempts + 1
                        task.wait(0.3)
                    end

                    -- Step 4: วาร์ปไปส่งงานทันทีหลังเควสเขียว
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            safeTeleport(targetPart.Position)
                            task.wait(0.5)

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

                task.wait(1.5)
            end
        end
    end
end)

-- UI Toggle Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "Stealth150PerfectTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPStealthBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 210, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "STEALTH 150m TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "STEALTH 150m TP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "STEALTH 150m TP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
