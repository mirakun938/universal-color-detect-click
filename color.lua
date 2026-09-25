local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- กำหนดระยะตรวจจับ NPC (150 Studs)
local NPC_SAFE_DISTANCE = 150

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

-- 1. ฟังก์ชันเช็กว่ากล้องของผู้เล่นอื่นมองมาทางรถเราอยู่หรือไม่ (SCP-173 Style)
local function isAnyPlayerLookingAtUs()
    local _, myRoot = getVehicleModel()
    if not myRoot then return false end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
            if pRoot then
                -- เช็กระยะทางเบื้องต้น (ถ้าระยะไกลเกิน 300 Studs กล้องจะมองไม่เห็นตัวรถชัด)
                local dist = (pRoot.Position - myRoot.Position).Magnitude
                if dist <= 300 then
                    -- คำนวณทิศทางที่ Player หันหน้าไป
                    local lookVector = pRoot.CFrame.LookVector
                    local dirToUs = (myRoot.Position - pRoot.Position).Unit
                    
                    -- Dot Product: ถ้าค่า > 0.3 แสดงว่ามุมมองหันมาทางเรา (FOV ~ 140 องศา)
                    local dot = lookVector:Dot(dirToUs)
                    if dot > 0.3 then
                        -- ใช้ Raycast เช็กว่ามีตึก/กำแพง บังอยู่หรือไม่
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {player.Character, myRoot.Parent}
                        
                        local rayResult = Workspace:Raycast(pRoot.Position, (myRoot.Position - pRoot.Position), rayParams)
                        
                        -- ถ้าไม่มีอะไรบัง Raycast แสดงว่าผู้เล่นคนนั้นมองเห็นเราตรงๆ!
                        if not rayResult then
                            return true 
                        end
                    end
                end
            end
        end
    end
    return false
end

-- 2. ฟังก์ชันเช็กระยะ NPC (ใช้ระยะ 150 Studs เดิม)
local function isPlayerNearNPC(npcPos)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
            if pRoot then
                if (pRoot.Position - npcPos).Magnitude <= NPC_SAFE_DISTANCE then
                    return true
                end
            end
        end
    end
    return false
end

-- รอจนกว่าจะไม่มีใครมองมาทางเรา (SCP-173 Mechanism)
local function waitUntilUnseen()
    while autoFarmActive and isAnyPlayerLookingAtUs() do
        task.wait(0.5)
    end
end

-- Safe Teleport (เช็กการมองเห็นก่อนวาร์ป)
local function safeTeleport(targetPos)
    waitUntilUnseen() -- รอจนกว่าจะไม่มีใครมอง
    
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
                    
                    if string.find(txt, "perfect delivery") or string.find(txt, "go to") or string.find(txt, "deliver") then
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

-- 3. ฟังก์ชันค้นหาและรับผู้โดยสาร (ใช้ร่วมกันทั้งตอนเริ่มต้นและหลังส่งงานเสร็จ)
local function tryPickupPassenger()
    local vehicle, rootPart = getVehicleModel()
    if not rootPart then return false end

    local npcsFolder = Workspace:FindFirstChild("npcs")
    if not npcsFolder then return false end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if not autoFarmActive then break end
        
        local isCustomer = (npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer"))
        if isCustomer then
            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
            
            -- เช็กว่าไม่มี Player คนอื่นอยู่ในระยะ 150 Studs รอบตัว NPC
            if npcPart and not isPlayerNearNPC(npcPart.Position) then
                
                -- วาร์ปไปจอดข้าง NPC
                safeTeleport(npcPart.Position + Vector3.new(3, 0, 0))
                
                -- จอดนิ่งรอผู้โดยสารขึ้นรถ (Timeout 15 วินาที)
                local startTime = tick()
                while (tick() - startTime) < 15 and autoFarmActive do
                    task.wait(0.5)
                    if rootPart then
                        rootPart.AssemblyLinearVelocity = Vector3.zero
                        rootPart.AssemblyAngularVelocity = Vector3.zero
                    end

                    local qStatus = checkQuestStatus()
                    if qStatus.hasPassengerOnBoard then
                        return true -- รับผู้โดยสารสำเร็จ!
                    end
                end
            end
        end
    end
    return false
end

-- Main Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if autoFarmActive do
            local vehicle, rootPart = getVehicleModel()
            if rootPart then
                
                -- เช็กก่อนว่ามีผู้โดยสารบนรถอยู่แล้วหรือไม่ (กรณีรับจากจุดส่งงานเดิม)
                local qStatus = checkQuestStatus()
                local passengerSeated = qStatus.hasPassengerOnBoard

                -- ถ้ารถยังว่างอยู่ ให้ไปรับผู้โดยสาร
                if not passengerSeated then
                    passengerSeated = tryPickupPassenger()
                end

                -- ถ้ามีผู้โดยสารขึ้นรถแล้ว ให้เริ่มทำเควสและส่งงาน
                if autoFarmActive and passengerSeated then
                    local attempts = 0
                    while autoFarmActive and attempts < 12 do
                        qStatus = checkQuestStatus()
                        
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

                    -- วาร์ปไปส่งงานปลายทาง
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
                            
                            task.wait(0.5)
                            
                            -- หลังส่งผู้โดยสารเสร็จ ตรวจหาผู้โดยสารใกล้ๆ จุดส่งเพื่อรับต่อเนื่องทันที!
                            tryPickupPassenger()
                        end
                    end
                end

                task.wait(1.0)
            end
        end
    end
end)

-- UI Toggle Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "SCP173ChainedTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPSCPBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 210, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "SCP-173 CHAIN TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "SCP-173 CHAIN TP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "SCP-173 CHAIN TP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
    
