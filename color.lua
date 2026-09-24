local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== ค้นหา Remote Event ====================
local function getDeliveryRemote()
    return ReplicatedStorage:FindFirstChild("deliveryfinserv", true)
        or ReplicatedStorage:FindFirstChild("deliveryfin", true)
        or Workspace:FindFirstChild("deliveryfinserv", true)
        or Workspace:FindFirstChild("deliveryfin", true)
end

-- ==================== ดึงชื่อสถานที่เป้าหมายจาก UI ====================
local function getCurrentDestination()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    
    -- วนลูปสแกนหาข้อความบอกสถานที่บนหน้าจอผู้เล่น
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local text = desc.Text
                    -- ถ้าเจอข้อความเช่น "Go to Taxi Headquarters" หรือ "Go to The Tree Store"
                    if string.find(string.lower(text), "go to ") then
                        local destination = string.gsub(text, "[Gg][Oo] [Tt][Oo] ", "")
                        return destination
                    end
                end
            end
        end
    end
    return nil
end

-- ==================== ฟังก์ชันส่งผู้โดยสารอัตโนมัติ ====================
local function sendInstantDelivery()
    local remote = getDeliveryRemote()
    
    if not remote then
        warn("ไม่พบ Remote deliveryfinserv หรือ deliveryfin!")
        return
    end

    -- หาชื่อสถานที่อัตโนมัติ
    local destination = getCurrentDestination()
    
    if not destination or destination == "" then
        print("ไม่พบข้อความบอกสถานที่บนหน้าจอ กำลังลองส่งค่าแบบ Auto Scan...")
        -- กรณีหาไม่เจอจริงๆ จะใช้คำว่า "Taxi Headquarters" เป็น fallback
        destination = "Taxi Headquarters"
    else
        print("พบสถานที่ส่งจากหน้าจอ:", destination)
    end

    -- ยิง Remote จบงาน
    if remote:IsA("RemoteEvent") then
        remote:FireServer(destination)
        print("ส่ง RemoteEvent ไปยัง:", destination)
    elseif remote:IsA("BindableEvent") then
        remote:Fire(destination)
        print("ส่ง BindableEvent ไปยัง:", destination)
    end
end

-- ==================== UI Controls ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "SmartDeliveryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "DeliveryButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
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

ToggleButton.MouseButton1Click:Connect(function()
    sendInstantDelivery()
end)

print("Smart Instant Delivery Script Loaded!")
