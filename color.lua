local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

-- ==================== ตั้งค่า (CONFIG) ====================
local SCALE_FACTOR = Vector3.new(3, 3, 3)        -- ขนาดขยายยานพาหนะทั่วไป
local PROJECTILE_SIZE = Vector3.new(15, 15, 15)  -- ขนาดขยายจรวด / ลูกปืนใหญ่ (ปรับใหญ่ขึ้นเพื่อความชัดเจน)
local HITBOX_TRANSPARENCY = 0.4                  -- ปรับให้ทึบขึ้นเล็กน้อยเพื่อสังเกตง่าย
local isScriptEnabled = true

-- คีย์เวิร์ดสำหรับตรวจจับจรวดและลูกปืนใหญ่ (ค้นหาแบบยืดหยุ่น)
local PROJECTILE_KEYWORDS = {
    "enemyreturnrocket",
    "reflectcannonball",
    "returnrocket",
    "cannonball",
    "rocket"
}

-- รายชื่อชิ้นส่วนร่างกายของมนุษย์ (กรองคนขับออก)
local HUMAN_PARTS = {
    ["head"] = true, ["torso"] = true, ["humanoidrootpart"] = true,
    ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true,
    ["upperleg"] = true, ["lowerleg"] = true, ["foot"] = true,
    ["upperarm"] = true, ["lowerarm"] = true, ["hand"] = true,
    ["uppertorso"] = true, ["lowertorso"] = true
}

-- ฟังก์ชันเช็คว่าวัตถุมีชื่อตรงกับคีย์เวิร์ดกระสุน/จรวดหรือไม่
local function isProjectileObject(instance)
    if not instance then return false end
    local nameLower = string.lower(instance.Name)
    
    for _, keyword in ipairs(PROJECTILE_KEYWORDS) do
        if string.find(nameLower, keyword) then
            return true
        end
    end
    return false
end

-- ฟังก์ชันปรับแต่ง Part
local function applyHitboxToPart(part, isProjectile, enable)
    if not part:IsA("BasePart") then return end
    
    local partName = string.lower(part.Name)
    local isHumanPart = HUMAN_PARTS[partName] or false
    local isInsideCharacter = part:FindFirstAncestorOfClass("Accessory") or (part.Parent and part.Parent:FindFirstChildOfClass("Humanoid"))
    
    -- ถ้าเป็นกระสุน/จรวด ให้ขยายทันที (ไม่สนว่าเป็น Part ตัวละครหรือไม่)
    -- ถ้าเป็นยานพาหนะ ต้องไม่ใช่ Part ร่างกายคน
    if isProjectile or (not isHumanPart and not isInsideCharacter) then
        if enable then
            if not part:GetAttribute("OriginalSize") then
                part:SetAttribute("OriginalSize", part.Size)
                part:SetAttribute("OriginalTrans", part.Transparency)
                part:SetAttribute("OriginalColor", part.BrickColor)
                part:SetAttribute("OriginalMat", part.Material)
                part:SetAttribute("OriginalCanCollide", part.CanCollide)
            end
            
            if isProjectile then
                part.Size = PROJECTILE_SIZE
                part.BrickColor = BrickColor.new("Bright red") -- เปลี่ยนจรวดเป็นสีแดงสดสังเกตง่าย
            else
                part.Size = part:GetAttribute("OriginalSize") * SCALE_FACTOR
                part.BrickColor = BrickColor.new("Bright blue")
            end
            
            part.Transparency = HITBOX_TRANSPARENCY
            part.Material = Enum.Material.Neon
            part.CanCollide = false
            part.CanQuery = true
        else
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

-- ฟังก์ชันประมวลผลวัตถุ (รองรับทั้ง Part และ Model)
local function processObject(instance, enable)
    if not instance then return end
    
    local isProj = isProjectileObject(instance) or isProjectileObject(instance.Parent)
    
    if instance:IsA("BasePart") then
        applyHitboxToPart(instance, isProj, enable)
    elseif instance:IsA("Model") or instance:IsA("Folder") then
        for _, child in ipairs(instance:GetDescendants()) do
            if child:IsA("BasePart") then
                applyHitboxToPart(child, isProj or isProjectileObject(child), enable)
            end
        end
    end
end

-- สแกนวัตถุทั้งหมดใน Enemies และ Workspace
local function refreshAll()
    if enemiesFolder then
        for _, child in ipairs(enemiesFolder:GetChildren()) do
            processObject(child, isScriptEnabled)
        end
    end
    
    for _, child in ipairs(Workspace:GetChildren()) do
        if isProjectileObject(child) then
            processObject(child, isScriptEnabled)
        end
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
    
    refreshAll()
end)

-- ==================== Event Listeners ====================
-- ดักจับใน Enemies Folder
if enemiesFolder then
    enemiesFolder.ChildAdded:Connect(function(newChild)
        task.wait(0.1)
        processObject(newChild, isScriptEnabled)
    end)
    enemiesFolder.DescendantAdded:Connect(function(newDescendant)
        task.wait(0.1)
        if newDescendant:IsA("BasePart") then
            processObject(newDescendant, isScriptEnabled)
        end
    end)
end

-- ดักจับกรณีเสกตรงลงใน Workspace
Workspace.ChildAdded:Connect(function(newChild)
    if isProjectileObject(newChild) then
        task.wait(0.1)
        processObject(newChild, isScriptEnabled)
    end
end)

-- สแกนทำงานครั้งแรก
refreshAll()

print("Enhanced Projectile & Vehicle Hitbox Loaded!")
