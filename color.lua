local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

-- ==================== ตั้งค่า (CONFIG) ====================
local SCALE_FACTOR = Vector3.new(3, 3, 3)        -- ขนาดขยายยานพาหนะทั่วไป
local PROJECTILE_SIZE = Vector3.new(12, 12, 12)  -- ขนาดขยายจรวด / ลูกปืนใหญ่
local HITBOX_TRANSPARENCY = 0.5
local isScriptEnabled = true

-- รายชื่อจรวด/ลูกปืนใหญ่ศัตรูที่อยู่ใน Enemies
local PROJECTILE_NAMES = {
    ["enemyreturnrocket"] = true,
    ["reflectcannonball"] = true
}

-- รายชื่อชิ้นส่วนร่างกายของมนุษย์ (กรองคนขับออก)
local HUMAN_PARTS = {
    ["head"] = true, ["torso"] = true, ["humanoidrootpart"] = true,
    ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true,
    ["upperleg"] = true, ["lowerleg"] = true, ["foot"] = true,
    ["upperarm"] = true, ["lowerarm"] = true, ["hand"] = true,
    ["uppertorso"] = true, ["lowertorso"] = true
}

-- ฟังก์ชันสำหรับปรับเปลี่ยนขนาดและคุณสมบัติ Hitbox
local function updatePartHitbox(part, enable)
    if not part:IsA("BasePart") then return end
    local partName = string.lower(part.Name)
    
    local isProjectile = PROJECTILE_NAMES[partName] or false
    local isHumanPart = HUMAN_PARTS[partName] or false
    local isInsideCharacter = part:FindFirstAncestorOfClass("Accessory") or (part.Parent and part.Parent:FindFirstChildOfClass("Humanoid"))
    
    -- ทำงานเฉพาะกระสุน/จรวด หรือ Part ยานพาหนะที่ไม่ใช่ตัวละคร
    if isProjectile or (not isHumanPart and not isInsideCharacter) then
        if enable then
            -- สำรองค่าดั้งเดิมไว้
            if not part:GetAttribute("OriginalSize") then
                part:SetAttribute("OriginalSize", part.Size)
                part:SetAttribute("OriginalTrans", part.Transparency)
                part:SetAttribute("OriginalColor", part.BrickColor)
                part:SetAttribute("OriginalMat", part.Material)
                part:SetAttribute("OriginalCanCollide", part.CanCollide)
            end
            
            -- ปรับขนาดตามประเภท
            if isProjectile then
                part.Size = PROJECTILE_SIZE
            else
                part.Size = part:GetAttribute("OriginalSize") * SCALE_FACTOR
            end
            
            part.Transparency = HITBOX_TRANSPARENCY
            part.BrickColor = BrickColor.new("Bright blue")
            part.Material = Enum.Material.Neon
            part.CanCollide = false
            part.CanQuery = true
        else
            -- คืนค่าเดิมเมื่อปิด
            if part:GetAttribute("OriginalSize") then
                part.Size = part:GetAttribute("OriginalSize")
                part.Transparency = part:GetAttribute("OriginalTrans")
                part.BrickColor = part:GetAttribute("OriginalColor")
                part.Material = part:GetAttribute("OriginalMat")
                part.CanCollide = part:GetAttribute("OriginalCanCollide")
            end
        end
    end
end

-- สแกนและอัปเดตวัตถุทั้งหมดในโฟลเดอร์ Enemies
local function refreshEnemiesFolder()
    if not enemiesFolder then return end
    for _, item in ipairs(enemiesFolder:GetDescendants()) do
        updatePartHitbox(item, isScriptEnabled)
    end
end

-- ==================== UI Controls ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "VehicleHitboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
ToggleButton.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Enemies Hitbox: ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    isScriptEnabled = not isScriptEnabled
    
    if isScriptEnabled then
        ToggleButton.Text = "Enemies Hitbox: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
    else
        ToggleButton.Text = "Enemies Hitbox: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    
    refreshEnemiesFolder()
end)

-- ==================== Event Listener ====================
-- ดักจับทุกสิ่งที่เสกเข้ามาใน Enemies (ทั้งยานพาหนะและจรวด)
if enemiesFolder then
    enemiesFolder.DescendantAdded:Connect(function(newItem)
        task.wait(0.05)
        updatePartHitbox(newItem, isScriptEnabled)
    end)
end

-- เริ่มสแกนครั้งแรก
refreshEnemiesFolder()

print("Enemies Folder Hitbox Handler Loaded!")
