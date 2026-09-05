local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- โฟลเดอร์เก็บ ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ScrapESP_Folder"
espFolder.Parent = CoreGui

-- ฟังก์ชันเลือกสี Highlight ตามประเภทเศษเหล็ก
local function getScrapColor(name)
    local upperName = string.upper(name)
    if string.find(upperName, "DIAMOND") then
        return Color3.fromRGB(0, 255, 255) -- สีฟ้า DIAMOND
    elseif string.find(upperName, "GOLD") then
        return Color3.fromRGB(255, 215, 0) -- สีทอง GOLD
    elseif string.find(upperName, "NEON") then
        return Color3.fromRGB(50, 255, 50) -- สีเขียว NEON
    elseif string.find(upperName, "METAL") or string.find(upperName, "SCRAP") then
        return Color3.fromRGB(255, 140, 0) -- สีส้ม METAL
    end
    return nil
end

-- ฟังก์ชันสร้าง Highlight และ ป้ายชื่อ ESP
local function applyScrapESP(target)
    if not target or target:FindFirstChild("ScrapESP_Added") then return end
    
    local color = getScrapColor(target.Name)
    if not color then return end
    
    -- ทำเครื่องหมายว่าติด ESP แล้ว
    local tag = Instance.new("BoolValue")
    tag.Name = "ScrapESP_Added"
    tag.Parent = target

    -- 1. สร้าง Highlight ทะลุกำแพง
    local highlight = Instance.new("Highlight")
    highlight.Name = "ScrapHighlight"
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder

    -- 2. สร้างป้ายชื่อแสดงประเภท
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ScrapNameTag"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = target.Name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Parent = billboard

    -- เมื่อเศษเหล็กหายไป/โดนเก็บ ให้ลบ ESP ออก
    target.AncestryChanged:Connect(function(_, parent)
        if not parent then
            highlight:Destroy()
            billboard:Destroy()
        end
    end)
end

-- สแกนวัตถุทั้งหมดใน Workspace
local function scan()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if getScrapColor(obj.Name) and (obj:IsA("Model") or obj:IsA("BasePart")) then
            applyScrapESP(obj)
        end
    end
end

-- ทำงานทันที + ดักจับเศษเหล็กที่สปอว์นใหม่
scan()
Workspace.DescendantAdded:Connect(function(obj)
    if getScrapColor(obj.Name) and (obj:IsA("Model") or obj:IsA("BasePart")) then
        task.wait(0.1)
        applyScrapESP(obj)
    end
end)

print("Scrap ESP (Multi-Color) Loaded Successfully!")
