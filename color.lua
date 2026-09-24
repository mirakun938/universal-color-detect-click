local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== ค้นหา Remote Event ====================
local function getDeliveryRemote()
    -- ค้นหา deliveryfinserv หรือ deliveryfin จาก ReplicatedStorage และ Workspace
    return ReplicatedStorage:FindFirstChild("deliveryfinserv", true)
        or ReplicatedStorage:FindFirstChild("deliveryfin", true)
        or Workspace:FindFirstChild("deliveryfinserv", true)
        or Workspace:FindFirstChild("deliveryfin", true)
end

-- ==================== ฟังก์ชันยิง Remote ส่งงาน ====================
local function sendInstantDelivery()
    local remote = getDeliveryRemote()
    
    if not remote then
        warn("ไม่พบ Remote deliveryfinserv หรือ deliveryfin!")
        return
    end

    -- ดึงชื่อสถานที่ปลายทาง (ถ้ามี) หรือส่งค่าเปล่า/ชื่อสถานที่ยอดนิยม
    -- จากคลิป Event รับค่า Argument เป็น string ชื่อสถานที่ เช่น "Taxi Headquarters" หรือ "the Tree Store"
    local targetLocation = "Taxi Headquarters" 

    if remote:IsA("RemoteEvent") then
        remote:FireServer(targetLocation)
        print("ยิง RemoteEvent deliveryfinserv สำเร็จ!")
    elseif remote:IsA("BindableEvent") then
        remote:Fire(targetLocation)
        print("ยิง BindableEvent deliveryfinserv สำเร็จ!")
    end
end

-- ==================== UI สร้างปุ่มกดส่งงาน ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "InstantDeliveryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "DeliveryButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100) -- สีเขียว
ToggleButton.Position = UDim2.new(0.02, 0, 0.6, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Instant Finish Delivery"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

-- เมื่อคลิกปุ่ม ให้ยิง Remote ทันที
ToggleButton.MouseButton1Click:Connect(function()
    sendInstantDelivery()
end)

print("Instant Delivery Remote Script Loaded!")
