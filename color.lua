local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

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

-- Safe Teleport
local function safeTeleport(targetPos)
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

-- ตรวจสอบเงื่อนไขเควสจาก Text Label บน UI
local function checkQuestRequirements()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local reqs = {
        shortcut = "none",
        needsTopSpeed = false
    }

    if not playerGui then return reqs end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local txt = desc.Text:lower()
                    
                    -- เช็คเควส Top Speed
                    if string.find(txt, "top speed") or string.find(txt, "maximum speed") or string.find(txt, "reach your taxi") then
                        reqs.needsTopSpeed = true
                    end
                    
                    -- เช็คเควส Shortcut
                    if string.find(txt, "don't take any shortcuts") or string.find(txt, "dont take") then
                        reqs.shortcut = "no_shortcut"
                    elseif string.find(txt, "take a shortcut") then
                        reqs.shortcut = "use_shortcut"
                    end
                end
            end
        end
    end
    return reqs
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
                -- 1. วาร์ปไปรับ NPC
                local npcsFolder = Workspace:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            if npcPart then
                                safeTeleport(npcPart.Position)
                                task.wait(1.5)
                                break
                            end
                        end
                    end
                end

                -- 2. เช็คเควส & ทำตามเงื่อนไข
                if autoFarmActive then
                    local reqs = checkQuestRequirements()
                    
                    -- ทำเควส Top Speed ด้วยการวาร์ปขึ้นฟ้าแล้วดิ่งลงมา
                    if reqs.needsTopSpeed then
                        local currentPos = rootPart.Position
                        safeTeleport(currentPos + Vector3.new(0, 800, 0))
                        
                        -- เร่งความเร็วตกตามธรรมชาติ
                        task.wait(0.2)
                        for _, part in ipairs(vehicle and vehicle:GetDescendants() or {rootPart}) do
                            if part:IsA("BasePart") then
                                part.AssemblyLinearVelocity = Vector3.new(0, -350, 0)
                            end
                        end
                        task.wait(0.8)
                    end

                    -- ทำเควส Shortcut
                    if reqs.shortcut == "use_shortcut" then
                        safeTeleport(SHORTCUT_POS)
                        task.wait(0.5)
                    end
                end

                -- 3. วาร์ปไปจุดส่งงาน
                if autoFarmActive then
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            safeTeleport(targetPart.Position)
                            task.wait(0.6)

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

ScreenGui.Name = "AutoPerfectFarmGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPPerfectBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 200, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "AUTO PERFECT TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "AUTO PERFECT TP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "AUTO PERFECT TP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
