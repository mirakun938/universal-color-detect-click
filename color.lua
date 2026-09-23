local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local mercPlayersFolder = Workspace:WaitForChild("MercPlayers", 10)

-- ==================== ตั้งค่า (CONFIG) ====================
local RESIZE_MULTIPLIER = Vector3.new(3.5, 3.5, 3.5) -- ตัวคูณขยายขนาด Part (ปรับเพิ่ม/ลดได้)
local HITBOX_TRANSPARENCY = 0.5                      -- ความโปร่งแสง (0 = ทึบ, 1 = ล่องหน)
local HITBOX_COLOR = BrickColor.new("Bright yellow") -- สีของ Part ที่ขยาย
local isScriptEnabled = true                         -- สถานะเปิด/ปิด
-- =========================================================

-- ฟังก์ชันขยายขนาด Part โดยตรง
local function expandPart(part)
    if not part:IsA("BasePart") then return end

    -- บันทึกค่าดั้งเดิมไว้ใน Attributes เผื่อสั่งปิดใช้งาน
    if not part:GetAttribute("OriginalSize") then
        part:SetAttribute("OriginalSize", part.Size)
        part:SetAttribute("OriginalTrans", part.Transparency)
        part:SetAttribute("OriginalColor", part.BrickColor)
        part:SetAttribute("OriginalMat", part.Material)
        part:SetAttribute("OriginalCanCollide", part.CanCollide)
    end

    -- ปรับขยายขนาด Part โดยตรง (Multiply Vector3)
    part.Size = part:GetAttribute("OriginalSize") * RESIZE_MULTIPLIER
    part.Transparency = HITBOX_TRANSPARENCY
    part.BrickColor = HITBOX_COLOR
    part.Material = Enum.Material.Neon
    part.CanCollide = false -- ป้องกัน Part ที่ใหญ่ขึ้นไปชนดันกับฉากจนตัวละครลอย
    part.CanQuery = true
end

-- ฟังก์ชัน คืนค่าขนาด Part กลับเป็นปกติ
local function restorePart(part)
    if not part:IsA("BasePart") then return end

    if part:GetAttribute("OriginalSize") then
        part.Size = part:GetAttribute("OriginalSize")
        part.Transparency = part:GetAttribute("OriginalTrans")
        part.BrickColor = part:GetAttribute("OriginalColor")
        part.Material = part:GetAttribute("OriginalMat")
        part.CanCollide = part:GetAttribute("OriginalCanCollide")
    end
end

-- ฟังก์ชันประมวลผลโมเดลผู้เล่นใน MercPlayers
local function processMercModel(model, enable)
    if not model or not model:IsA("Model") then return end
    
    -- กรองไม่ให้ขยาย Part ตัวละครของเราเอง
    local myHitboxName = "MercHitboxes_" .. LocalPlayer.Name
    if string.lower(model.Name) == string.lower(myHitboxName) then
        return
    end

    -- วนลูปขยาย Part ทุกชิ้น (เช่น Head, Torso, Limbs) ในโมเดลนั้น
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if enable then
                expandPart(child)
            else
                restorePart(child)
            end
        end
    end
end

-- สแกนอัปเดตผู้เล่นทุกคน
local function refreshAllPlayers()
    if not mercPlayersFolder then return end
    for _, model in ipairs(mercPlayersFolder:GetChildren()) do
        processMercModel(model, isScriptEnabled)
    end
end

-- ==================== UI Toggle ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "ExpandPartHitboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Expand Part: ON"
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    isScriptEnabled = not isScriptEnabled
    
    if isScriptEnabled then
        ToggleButton.Text = "Expand Part: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    else
        ToggleButton.Text = "Expand Part: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    
    refreshAllPlayers()
end)

-- ==================== Event Listeners ====================
if mercPlayersFolder then
    -- เมื่อมีผู้เล่นเกิดใหม่ใน MercPlayers
    mercPlayersFolder.ChildAdded:Connect(function(newChild)
        task.wait(0.15)
        processMercModel(newChild, isScriptEnabled)
    end)
    
    -- เมื่อมี Part ถูกโหลดเพิ่มเข้าในโมเดล
    mercPlayersFolder.DescendantAdded:Connect(function(newDescendant)
        if newDescendant:IsA("BasePart") then
            task.wait(0.05)
            local parentModel = newDescendant:FindFirstAncestorOfClass("Model")
            if parentModel then
                processMercModel(parentModel, isScriptEnabled)
            end
        end
    end)
end

-- สแกนทำงานครั้งแรก
refreshAllPlayers()

print("Part Resizing Hitbox Loaded Successfully!")
