local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autoFarmActive = false

-- 1. ฟังก์ชันค้นหาและวาร์ปไปรับ Customer (Auto Pick Up)
local function getCustomerAndPickUp()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    local tpTarget = vehicle or char

    local npcsFolder = Workspace:FindFirstChild("npcs")
    if npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            if npc.Name == "Customer" or string.find(string.lower(npc.Name), "customer") then
                local npcPart = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
                if npcPart then
                    -- วาร์ปไปจอดทับตัว NPC เพื่อรับ
                    tpTarget:PivotTo(npcPart.CFrame + Vector3.new(0, 2, 0))
                    
                    -- จำลอง Touch ถ้าจำเป็น
                    local rootPart = char:FindFirstChild("HumanoidRootPart")
                    if firetouchinterest and rootPart then
                        firetouchinterest(rootPart, npcPart, 0)
                        task.wait(0.1)
                        firetouchinterest(rootPart, npcPart, 1)
                    end
                    return true
                end
            end
        end
    end
    return false
end

-- 2. ฟังก์ชันค้นหาจุดส่งของ (Location)
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

-- 3. ฟังก์ชันวาร์ปส่งของและยิง Remote (Auto Deliver)
local function deliverCustomer()
    local char = LocalPlayer.Character
    if not char then return end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    local tpTarget = vehicle or char

    local targetObj = getTargetLocation()
    if targetObj then
        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
        if targetPart then
            -- วาร์ปไปจุดส่ง
            tpTarget:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
            
            -- Touch Simulation
            if firetouchinterest and rootPart then
                firetouchinterest(rootPart, targetPart, 0)
                task.wait(0.1)
                firetouchinterest(rootPart, targetPart, 1)
                if seat then
                    firetouchinterest(seat, targetPart, 0)
                    task.wait(0.1)
                    firetouchinterest(seat, targetPart, 1)
                end
            end
        end
    end

    -- ยิง Remote ยืนยันการส่งงาน
    local remotes = {"deliveryfinserv", "deliveryfin", "delinterrupt"}
    for _, remoteName in ipairs(remotes) do
        local remote = ReplicatedStorage:FindFirstChild(remoteName, true) or Workspace:FindFirstChild(remoteName, true)
        if remote and remote:IsA("RemoteEvent") then
            if targetObj then
                remote:FireServer(targetObj.Name)
                remote:FireServer(targetObj)
            end
            remote:FireServer()
        end
    end
end

-- ลูป Auto Farm ทำงานอัตโนมัติ
task.spawn(function()
    while true do
        task.wait(1)
        if autoFarmActive then
            -- ขั้นตอนที่ 1: วาร์ปไปรับผู้โดยสาร
            local pickedUp = getCustomerAndPickUp()
            
            -- รอผู้โดยสารขึ้นรถเล็กน้อย
            task.wait(1.5)
            
            -- ขั้นตอนที่ 2: วาร์ปไปส่งผู้โดยสาร + จบงาน
            if autoFarmActive then
                deliverCustomer()
            end
            
            -- ดีเลย์กันเกมหลุด/รีเซ็ตก่อนเริ่มรอบใหม่
            task.wait(2)
        end
    end
end)

-- สร้าง GUI ปุ่มเปิด/ปิด Auto Farm
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "FullAutoFarmTaxiGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "AutoFarmBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 170, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "AUTO FARM: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        ToggleButton.Text = "AUTO FARM: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        ToggleButton.Text = "AUTO FARM: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

print("Full Auto Farm Loaded!")
