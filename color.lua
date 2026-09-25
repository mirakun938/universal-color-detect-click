local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- พิกัดจุดทางลัด (Shortcut Coordinate)
local SHORTCUT_POS = Vector3.new(-135.0, 5.7, 3447.1)

-- ฟังก์ชันค้นหา Root Part ของรถ
local function getVehicleRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    
    local seat = hum.SeatPart
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    
    if vehicle then
        if vehicle.PrimaryPart then return vehicle.PrimaryPart end
        for _, part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("frame") or part.Name:lower():find("body") or part.Name:lower():find("chassis")) then
                return part
            end
        end
    end
    return seat
end

-- ฟังก์ชัน Teleport
local function teleportVehicle(targetPos)
    local rootPart = getVehicleRoot()
    if rootPart then
        rootPart.CFrame = CFrame.new(targetPos)
        return true
    end
    return false
end

-- ฟังก์ชันตรวจจับเงื่อนไข (Shortcut หรือ No Shortcut)
local function checkShortcutRequirement()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return "none" end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local txt = desc.Text:lower()
                    if string.find(txt, "don't take any shortcuts") or string.find(txt, "dont take") then
                        return "no_shortcut"
                    elseif string.find(txt, "take a shortcut") then
                        return "use_shortcut"
                    end
                end
            end
        end
    end
    return "none"
end

-- ฟังก์ชันหาจุดส่งปลายทาง
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
            local rootPart = getVehicleRoot()
            if rootPart then
                -- 1. วาร์ปไปรับ NPC
                local npcsFolder = Workspace:FindFirstChild("npcs")
                if npcsFolder then
                    for _, npc in ipairs(npcsFolder:GetChildren()) do
                        if not autoFarmActive then break end
                        if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                            local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                            if npcPart then
                                teleportVehicle(npcPart.Position + Vector3.new(0, 3, 0))
                                task.wait(1.5) -- รอผู้โดยสารขึ้นรถ
                                break
                            end
                        end
                    end
                end

                -- 2. เช็คเงื่อนไขว่าต้องไปทางลัดหรือไม่
                if autoFarmActive then
                    local req = checkShortcutRequirement()
                    
                    if req == "use_shortcut" then
                        -- ถ้ารีเควสให้ไปทางลัด -> วาร์ปไปจุดทางลัด
                        teleportVehicle(SHORTCUT_POS)
                        task.wait(0.5)
                    end
                    -- ถ้าเป็น "no_shortcut" สคริปต์จะข้ามขั้นตอนนี้ทันที!
                end

                -- 3. วาร์ปไปส่งงานปลายทาง
                if autoFarmActive then
                    local targetObj = getTargetLocation()
                    if targetObj then
                        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            teleportVehicle(targetPart.Position + Vector3.new(0, 3, 0))
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

ScreenGui.Name = "SmartPerfectTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPPerfectBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 200, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "SMART PERFECT TP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "SMART PERFECT TP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "SMART PERFECT TP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)
