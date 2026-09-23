local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local mercPlayersFolder = Workspace:WaitForChild("MercPlayers", 10)

-- ==================== ตั้งค่า (CONFIG) ====================
local SCALE_FACTOR = Vector3.new(3, 3, 3)            -- ขนาดขยาย Hitbox (ปรับเพิ่ม/ลดได้)
local HITBOX_TRANSPARENCY = 0.5                      -- ความโปร่งแสง
local HITBOX_COLOR = BrickColor.new("Bright yellow") -- สี Hitbox
local isScriptEnabled = true                         -- สถานะเปิด/ปิด
-- =========================================================

-- ฟังก์ชันขยาย/คืนค่า Part Hitbox
local function updateHitboxPart(part, enable)
    if not part:IsA("BasePart") then return end
    
    if enable then
        -- บันทึกค่าดั้งเดิมไว้
        if not part:GetAttribute("OriginalSize") then
            part:SetAttribute("OriginalSize", part.Size)
            part:SetAttribute("OriginalTrans", part.Transparency)
            part:SetAttribute("OriginalColor", part.BrickColor)
            part:SetAttribute("OriginalMat", part.Material)
            part:SetAttribute("OriginalCanCollide", part.CanCollide)
        end
        
        -- ปรับขยายขนาด
        part.Size = part:GetAttribute("OriginalSize") * SCALE_FACTOR
        part.Transparency = HITBOX_TRANSPARENCY
        part.BrickColor = HITBOX_COLOR
        part.Material = Enum.Material.Neon
        part.CanCollide = false -- ป้องกันตัวละครติดขัด
        part.CanQuery = true
    else
        -- คืนค่าเดิมเมื่อปิดสวิตช์
        if part:GetAttribute("OriginalSize") then
            part.Size = part:GetAttribute("OriginalSize")
            part.Transparency = part:GetAttribute("OriginalTrans")
            part.BrickColor = part:GetAttribute("OriginalColor")
            part.Material = part:GetAttribute("OriginalMat")
            part.CanCollide = part:GetAttribute("OriginalCanCollide")
        end
    end
end

-- ฟังก์ชันประมวลผลโมเดล MercHitboxes
local function processMercModel(model, enable)
    if not model or not model:IsA("Model") then return end
    
    -- กรองไม่ให้ทำกับตัวเราเอง (ถ้าเป็น MercHitboxes_[ชื่อเรา] จะข้าม)
    local myHitboxName = "MercHitboxes_" .. LocalPlayer.Name
    if string.lower(model.Name) == string.lower(myHitboxName) then
        return
    end
    
    -- ขยาย Part ทุกชิ้นที่อยู่ในโมเดลของผู้เล่นคนนั้น (เช่น Head, Torso ฯลฯ)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            updateHitboxPart(part, enable)
        end
    end
end

-- สแกนผู้เล่นทุกคนใน MercPlayers
local function refreshAllMercPlayers()
    if not mercPlayersFolder then return end
    for _, model in ipairs(mercPlayersFolder:GetChildren()) do
        processMercModel(model, isScriptEnabled)
    end
end

-- ==================== UI Controls ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "MercPlayerHitboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- สีส้ม
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Player Hitbox: ON"
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    isScriptEnabled = not isScriptEnabled
    
    if isScriptEnabled then
        ToggleButton.Text = "Player Hitbox: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    else
        ToggleButton.Text = "Player Hitbox: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    
    refreshAllMercPlayers()
end)

-- ==================== Event Listeners ====================
-- ดักจับเมื่อผู้เล่นคนอื่นเข้าเกมหรือเกิดใหม่ใน MercPlayers
if mercPlayersFolder then
    mercPlayersFolder.ChildAdded:Connect(function(newChild)
        task.wait(0.2) -- รอให้ Part ข้างในโหลดครบ
        processMercModel(newChild, isScriptEnabled)
    end)
    
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
refreshAllMercPlayers()

print("MercPlayers Hitbox Script Loaded Successfully!")
