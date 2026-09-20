local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ตารางเก็บสถานะเปิด/ปิด ESP ของสิ่งก่อสร้างแต่ละหลัง
local hiddenBuildings = {}

-- ฟังก์ชันสำหรับเปิด/ปิด Highlight ของสิ่งก่อสร้างรายหลัง
local function toggleSingleBuildingESP(building, enable)
    if not building then return end
    
    local highlight = building:FindFirstChild("BuildingLoggerHighlight")
    if enable then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BuildingLoggerHighlight"
            highlight.Adornee = building
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = Color3.fromRGB(0, 255, 127) -- สีเขียว
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = building
        end
        highlight.Enabled = true
    else
        if highlight then
            highlight.Enabled = false
        end
    end
end

-- ==================== UI Main Menu & Logs ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuildingLoggerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มเปิด/ปิด เมนูหลัก
local MenuBtn = Instance.new("TextButton")
MenuBtn.Name = "MenuButton"
MenuBtn.Parent = ScreenGui
MenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
MenuBtn.Size = UDim2.new(0, 110, 0, 35)
MenuBtn.Font = Enum.Font.SourceSansBold
MenuBtn.Text = "LOGS [BUILD]"
MenuBtn.TextColor3 = Color3.fromRGB(85, 255, 127)
MenuBtn.TextSize = 14
MenuBtn.Active = true
MenuBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = MenuBtn

-- 2. หน้าต่าง Main Menu Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 240)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- หัวข้อ Menu
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Building Detector & ESP Manager"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- 3. Scroll Frame สำหรับแสดงรายการ Log
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Position = UDim2.new(0.04, 0, 0.15, 0)
ScrollFrame.Size = UDim2.new(0.92, 0, 0.8, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- ระบบสลับซ่อน/แสดง เมนูหลัก
MenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==================== ระบบสแกนหาและบันทึก Log พร้อมปุ่มเปิด/ปิด ESP ====================
local function updateBuildingLogs()
    -- ล้างข้อมูลปุ่มรายการเก่าออกก่อนอัปเดตใหม่
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    if not buildingsFolder then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    local buildingList = {}

    -- รวบรวมข้อมูลสิ่งก่อสร้างทั้งหมด
    for _, building in ipairs(buildingsFolder:GetChildren()) do
        local primary = building.PrimaryPart or building:FindFirstChildOfClass("BasePart")
        local distance = 999999

        if hrp and primary then
            distance = math.floor((hrp.Position - primary.Position).Magnitude)
        end

        table.insert(buildingList, {
            Object = building,
            Name = building.Name,
            Distance = distance
        })
    end

    -- เรียงลำดับสิ่งก่อสร้างตามระยะทาง (ใกล้สุดอยู่บน)
    table.sort(buildingList, function(a, b)
        return a.Distance < b.Distance
    end)

    -- สร้างแถบรายการสิ่งก่อสร้างลงใน ScrollFrame
    for i, data in ipairs(buildingList) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 28)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 4)
        ItemCorner.Parent = itemFrame

        -- ข้อความบอกชื่อและระยะทาง
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(0.7, 0, 1, 0)
        logLabel.Position = UDim2.new(0.03, 0, 0, 0)
        logLabel.BackgroundTransparency = 1
        logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLabel.Font = Enum.Font.SourceSans
        logLabel.TextSize = 13
        logLabel.TextXAlignment = Enum.TextXAlignment.Left

        if data.Distance < 999999 then
            logLabel.Text = string.format("[%d] %s (%dm)", i, data.Name, data.Distance)
        else
            logLabel.Text = string.format("[%d] %s", i, data.Name)
        end
        logLabel.Parent = itemFrame

        -- ปุ่ม Toggle ESP สิ่งก่อสร้างเฉพาะหลัง
        local toggleEspBtn = Instance.new("TextButton")
        toggleEspBtn.Size = UDim2.new(0.24, 0, 0.75, 0)
        toggleEspBtn.Position = UDim2.new(0.73, 0, 0.125, 0)
        toggleEspBtn.Font = Enum.Font.SourceSansBold
        toggleEspBtn.TextSize = 12

        local BtnItemCorner = Instance.new("UICorner")
        BtnItemCorner.CornerRadius = UDim.new(0, 4)
        BtnItemCorner.Parent = toggleEspBtn

        -- ตรวจสอบสถานะว่าถูกซ่อนหรือเปิดอยู่
        local isHidden = hiddenBuildings[data.Object] or false
        if isHidden then
            toggleEspBtn.Text = "Show"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleSingleBuildingESP(data.Object, false)
        else
            toggleEspBtn.Text = "Hide"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleSingleBuildingESP(data.Object, true)
        end

        -- ระบบเมื่อกดปุ่ม Hide/Show รายหลัง
        toggleEspBtn.MouseButton1Click:Connect(function()
            hiddenBuildings[data.Object] = not hiddenBuildings[data.Object]
            updateBuildingLogs()
        end)

        itemFrame.Parent = ScrollFrame
    end

    -- ปรับขนาด Scrolling Canvas ตามจำนวนสิ่งก่อสร้าง
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buildingList * 33)
end

-- อัปเดตรายการและระยะทางแบบ Real-time ทุก 1.5 วินาที
task.spawn(function()
    while task.wait(1.5) do
        if MainFrame.Visible then
            updateBuildingLogs()
        end
    end
end)

print("Building Radar & Single-ESP Logger Loaded Successfully!")
