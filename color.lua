local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local locationsFolder = Workspace:WaitForChild("locations", 5)

-- ฟังก์ชันดึงชื่อสถานที่จาก UI หน้าจอ
local function getCurrentTargetName()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local text = desc.Text
                    if string.find(string.lower(text), "go to ") then
                        -- ตัดคำว่า "Go to " ออกเพื่อเอาเฉพาะชื่อสถานที่
                        return string.gsub(text, "[Gg][Oo] [Tt][Oo] ", "")
                    end
                end
            end
        end
    end
    return nil
end

-- ฟังก์ชันค้นหา Part/Model ในโฟลเดอร์ locations
local function findLocationObject(targetName)
    if not locationsFolder or not targetName then return nil end
    
    local cleanTarget = string.lower(targetName)
    
    for _, child in ipairs(locationsFolder:GetChildren()) do
        local childName = string.lower(child.Name)
        if string.find(childName, cleanTarget) or string.find(cleanTarget, childName) then
            return child
        end
    end
    return nil
end

-- ฟังก์ชันวาร์ปรถไปสถานที่ส่ง
local function tpToDeliveryLocation()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local seat = humanoid and humanoid.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    
    if not vehicle then
        warn("คุณต้องนั่งอยู่บนรถก่อน!")
        return
    end

    local targetName = getCurrentTargetName()
    if not targetName then
        warn("ไม่พบชื่อเป้าหมายบนหน้าจอ")
        return
    end

    local locObj = findLocationObject(targetName)
    if locObj then
        local targetCFrame
        if locObj:IsA("Model") then
            targetCFrame = locObj:GetPivot()
        elseif locObj:IsA("BasePart") then
            targetCFrame = locObj.CFrame
        end

        if targetCFrame then
            -- วาร์ปรถไปตำแหน่งจุดส่ง (ยกสูงขึ้นเล็กน้อย +3 กันจมดิน)
            vehicle:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
            print("วาร์ปรถไปส่งผู้โดยสารที่:", locObj.Name)
        end
    else
        warn("ไม่พบสถานที่ชื่อ:", targetName, "ในโฟลเดอร์ locations")
    end
end

-- UI Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "LocationTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.Position = UDim2.new(0.02, 0, 0.6, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "TP to Location"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    tpToDeliveryLocation()
end)

print("Location Auto TP Script Loaded!")
