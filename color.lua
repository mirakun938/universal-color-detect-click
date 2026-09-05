local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ลบทิ้งของเก่าถ้าเคยรันไว้
if CoreGui:FindFirstChild("ScrapESP_Folder") then
    CoreGui.ScrapESP_Folder:Destroy()
end
if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ScrapESP_UI") then
    LocalPlayer.PlayerGui.ScrapESP_UI:Destroy()
end

-- โฟลเดอร์เก็บ ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ScrapESP_Folder"
espFolder.Parent = CoreGui

-- สถานะเปิด-ปิด ESP แยกตามประเภท
local espStates = {
    DIAMOND = true,
    GOLD = true,
    NEON = true,
    DIRTY_METAL = true,
    PURE_METAL = true
}

-- ฟังก์ชันแยกประเภทเศษเหล็กและกำหนดสี
local function getScrapCategory(name)
    local upper = string.upper(name)
    
    -- กรองวัตถุฉากที่ไม่ใช่เศษเหล็กออก
    if string.find(upper, "LEAF") or string.find(upper, "PART") or upper == "NEON2" or upper == "NEON" then
        return nil
    end
    
    if string.find(upper, "SCRAPDIAMOND") or upper:sub(1, 7) == "DIAMOND" then
        return "DIAMOND", Color3.fromRGB(0, 255, 255)
    elseif string.find(upper, "SCRAPGOLD") or upper:sub(1, 4) == "GOLD" then
        return "GOLD", Color3.fromRGB(255, 215, 0)
    elseif string.find(upper, "SCRAPNEON") then
        return "NEON", Color3.fromRGB(50, 255, 50)
    elseif string.find(upper, "SCRAPMETAL2_") then
        return "PURE_METAL", Color3.fromRGB(180, 180, 180) -- เหล็กแท้ (สีเทา)
    elseif string.find(upper, "SCRAPMETAL_") then
        return "DIRTY_METAL", Color3.fromRGB(255, 140, 0) -- เหล็กสกปรก (สีส้ม)
    end
    
    return nil
end

-- ฟังก์ชันสร้าง ESP
local function applyESP(target)
    if not target or target:FindFirstChild("ScrapESP_Added") then return end
    
    local category, color = getScrapCategory(target.Name)
    if not category then return end
    
    local tag = Instance.new("StringValue")
    tag.Name = "ScrapESP_Added"
    tag.Value = category
    tag.Parent = target

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ScrapHighlight"
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = espStates[category]
    highlight.Parent = espFolder

    -- Billboard Tag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ScrapNameTag"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = espStates[category]
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = target.Name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 13
    label.Parent = billboard

    highlight:SetAttribute("Category", category)
    billboard:SetAttribute("Category", category)

    target.AncestryChanged:Connect(function(_, parent)
        if not parent then
            highlight:Destroy()
            billboard:Destroy()
        end
    end)
end

-- สแกนวัตถุทั้งหมด
local function scan()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) then
            applyESP(obj)
        end
    end
end

scan()
Workspace.DescendantAdded:Connect(function(obj)
    if (obj:IsA("Model") or obj:IsA("BasePart")) then
        task.wait(0.1)
        applyESP(obj)
    end
end)

----------------------------------------------------
-- 🖥️ ส่วนของการสร้าง UI Control Panel + ปุ่ม Minimize
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScrapESP_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 190, 0, 250)
mainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "  Scrap ESP Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- ปุ่มMinimize ปิด/เปิด UI หลัก
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        contentFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 190, 0, 35)
        minimizeBtn.Text = "+"
    else
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 190, 0, 250)
        minimizeBtn.Text = "-"
    end
end)

local function toggleESP(category, enabled)
    espStates[category] = enabled
    for _, child in ipairs(espFolder:GetChildren()) do
        if child:GetAttribute("Category") == category then
            child.Enabled = enabled
        end
    end
end

local categories = {
    {ID = "DIAMOND", Name = "DIAMOND", Color = Color3.fromRGB(0, 255, 255)},
    {ID = "GOLD", Name = "GOLD", Color = Color3.fromRGB(255, 215, 0)},
    {ID = "NEON", Name = "NEON", Color = Color3.fromRGB(50, 255, 50)},
    {ID = "DIRTY_METAL", Name = "DIRTY METAL", Color = Color3.fromRGB(255, 140, 0)},
    {ID = "PURE_METAL", Name = "PURE METAL", Color = Color3.fromRGB(180, 180, 180)}
}

for i, cat in ipairs(categories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 32)
    btn.Position = UDim2.new(0.075, 0, 0, 8 + ((i - 1) * 38))
    btn.BackgroundColor3 = cat.Color
    btn.Text = cat.Name .. ": ON"
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = contentFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        espStates[cat.ID] = not espStates[cat.ID]
        local isON = espStates[cat.ID]
        
        if isON then
            btn.Text = cat.Name .. ": ON"
            btn.BackgroundTransparency = 0
        else
            btn.Text = cat.Name .. ": OFF"
            btn.BackgroundTransparency = 0.6
        end
        
        toggleESP(cat.ID, isON)
    end)
end

print("Scrap ESP (Updated Metal Types & Minimize UI) Loaded!")
