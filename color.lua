local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

local SCALE_FACTOR = Vector3.new(3, 3, 3) 
local HITBOX_TRANSPARENCY = 0.5
local isScriptEnabled = true -- สถานะ เปิด/ปิด

-- รายชื่อชิ้นส่วนร่างกายของมนุษย์ (กรองคนขับออก)
local HUMAN_PARTS = {
    ["head"] = true, ["torso"] = true, ["humanoidrootpart"] = true,
    ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true,
    ["upperleg"] = true, ["lowerleg"] = true, ["foot"] = true,
    ["upperarm"] = true, ["lowerarm"] = true, ["hand"] = true,
    ["uppertorso"] = true, ["lowertorso"] = true
}

-- ฟังก์ชันขยาย/คืนค่า Part
local function updatePartHitbox(part, enable)
    if not part:IsA("BasePart") then return end
    local partName = string.lower(part.Name)
    
    local isHumanPart = HUMAN_PARTS[partName] or false
    local isInsideCharacter = part:FindFirstAncestorOfClass("Accessory") or part.Parent:FindFirstChildOfClass("Humanoid")
    
    if not isHumanPart and not isInsideCharacter then
        if enable then
            if not part:GetAttribute("OriginalSize") then
                part:SetAttribute("OriginalSize", part.Size)
                part:SetAttribute("OriginalTrans", part.Transparency)
                part:SetAttribute("OriginalColor", part.BrickColor)
                part:SetAttribute("OriginalMat", part.Material)
            end
            
            part.Size = part:GetAttribute("OriginalSize") * SCALE_FACTOR
            part.Transparency = HITBOX_TRANSPARENCY
            part.BrickColor = BrickColor.new("Bright blue")
            part.Material = Enum.Material.Neon
            part.CanCollide = false
            part.CanQuery = true
        else
            -- คืนค่าเดิมเมื่อปิดสวิตช์
            if part:GetAttribute("OriginalSize") then
                part.Size = part:GetAttribute("OriginalSize")
                part.Transparency = part:GetAttribute("OriginalTrans")
                part.BrickColor = part:GetAttribute("OriginalColor")
                part.Material = part:GetAttribute("OriginalMat")
            end
        end
    end
end

-- ฟังก์ชันสแกนยานพาหนะทั้งหมด
local function refreshAllVehicles()
    if not enemiesFolder then return end
    for _, model in ipairs(enemiesFolder:GetChildren()) do
        if model:IsA("Model") then
            for _, part in ipairs(model:GetDescendants()) do
                updatePartHitbox(part, isScriptEnabled)
            end
        end
    end
end

-- สร้าง UI สวิตช์ Toggle
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

-- ป้องกัน UI หายเมื่อตัวละครตาย
ScreenGui.Name = "VehicleHitboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127) -- สีเขียว (ON)
ToggleButton.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 140, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Vehicle Hitbox: ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16.00
ToggleButton.Active = true
ToggleButton.Draggable = true -- สามารถลากปุ่มย้ายตำแหน่งบนหน้าจอได้

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

-- ระบบคลิกเปิด-ปิด
ToggleButton.MouseButton1Click:Connect(function()
    isScriptEnabled = not isScriptEnabled
    
    if isScriptEnabled then
        ToggleButton.Text = "Vehicle Hitbox: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127) -- สีเขียว
    else
        ToggleButton.Text = "Vehicle Hitbox: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- สีแดง
    end
    
    refreshAllVehicles()
end)

-- ดักจับเมื่อมียานพาหนะเกิดใหม่
if enemiesFolder then
    enemiesFolder.ChildAdded:Connect(function(newChild)
        task.wait(0.2)
        if newChild:IsA("Model") then
            for _, part in ipairs(newChild:GetDescendants()) do
                updatePartHitbox(part, isScriptEnabled)
            end
        end
    end)
end

print("Vehicle Hitbox UI Loaded Successfully!")
