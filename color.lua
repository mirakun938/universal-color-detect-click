local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 1. ค้นหา RemoteEvent deliveryfinserv ที่เห็นใน Dex
local function getDeliveryRemote()
    return ReplicatedStorage:FindFirstChild("deliveryfinserv", true) 
        or Workspace:FindFirstChild("deliveryfinserv", true)
end

-- 2. อ่านชื่อเป้าหมายสถานที่ส่งจาก UI
local function getTargetLocationName()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local txt = desc.Text
                    -- ถ้ามีข้อความบอกสถานที่
                    if string.find(string.lower(txt), "go to") or string.find(string.lower(txt), "deliver") then
                        local clean = string.gsub(txt, "[Gg][Oo] [Tt][Oo] ", "")
                        clean = string.gsub(clean, "[Dd][Ee][Ll][Ii][Vv][Ee][Rr] [Tt][Oo] ", "")
                        return clean
                    end
                end
            end
        end
    end
    return nil
end

-- 3. ค้นหา Object ตำแหน่งจริงใน Workspace.locations
local function getTargetObject(targetName)
    local locationsFolder = Workspace:FindFirstChild("locations")
    if not locationsFolder then return nil end

    if targetName then
        local cleanTarget = string.lower(targetName)
        for _, child in ipairs(locationsFolder:GetChildren()) do
            if string.find(string.lower(child.Name), cleanTarget) or string.find(cleanTarget, string.lower(child.Name)) then
                return child
            end
        end
    end
    -- ถ้าหาจากชื่อบน UI ไม่เจอ ให้ดึงสถานที่อันแรกในโฟลเดอร์ locations มาใช้สำรอง
    return locationsFolder:GetChildren()[1]
end

-- ฟังก์ชันหลักเมื่อกดปุ่ม
local function executeDelivery()
    local targetName = getTargetLocationName()
    local targetObj = getTargetObject(targetName)
    local remote = getDeliveryRemote()

    -- [วิธีที่ 1] ยิง Remote deliveryfinserv เพื่อจบงานทันที
    if remote then
        if targetObj then
            remote:FireServer(targetObj.Name)
            remote:FireServer(targetObj)
        else
            remote:FireServer()
        end
        print("ส่ง Remote deliveryfinserv เรียบร้อยแล้ว!")
    end

    -- [วิธีที่ 2] วาร์ปตัวละคร/รถไปแตะจุดส่งใน locations
    if targetObj then
        local targetCFrame
        if targetObj:IsA("BasePart") then
            targetCFrame = targetObj.CFrame
        elseif targetObj:IsA("Model") then
            targetCFrame = targetObj:GetPivot()
        end

        if targetCFrame then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local seat = humanoid and humanoid.SeatPart
                local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
                
                local tpTarget = vehicle or character
                tpTarget:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
                print("วาร์ปไปยังสถานที่:", targetObj.Name)
            end
        end
    end
end

-- สร้างปุ่มใช้งานบนหน้าจอ
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "AutoDeliveryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "DeliveryBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 120, 0)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 170, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "FINISH DELIVERY NOW"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    executeDelivery()
end)

print("Auto Delivery Script Ready!")
