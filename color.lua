local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ตารางบันทึกสถานะการซ่อน
local hiddenBuildings = {}

-- ฟังก์ชันบังคับใส่ Highlight ให้สิ่งก่อสร้างทุกชิ้นส่วน
local function setBuildingHighlight(building, enable)
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
            highlight.FillTransparency = 0.3
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

-- ==================== UI MAIN MENU (ปรับขนาดใหม่) ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuildingLoggerGui_Fix"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มเปิด/ปิด เมนู
local MenuBtn = Instance.new("TextButton")
MenuBtn.Name = "MenuButton"
MenuBtn.Parent = ScreenGui
MenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
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

-- 2. หน้าต่างเมนูหลัก (ปรับความกว้างเป็น 350px ป้องกันปุ่มเบียด)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.02, 0, 0.26, 0)
MainFrame.Size = UDim2.new(0, 350, 0, 260)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- Title Header
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Building Detector & ESP Logs"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- 3. Scroll Frame แสดงรายการ
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Position = UDim2.new(0.03, 0, 0.15, 0)
ScrollFrame.Size = UDim2.new(0.94, 0, 0.82, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

MenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==================== ระบบสแกน + สร้างปุ่ม HIDE/SHOW ====================
local function updateBuildingLogs()
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    if not buildingsFolder then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local buildingList = {}

    for _, building in ipairs(buildingsFolder:GetChildren()) do
        local primary = building.PrimaryPart or building:FindFirstChildOfClass("BasePart")
        if not primary then
            primary = building:FindFirstChildWhichIsA("BasePart", true)
        end
        
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

    table.sort(buildingList, function(a, b)
        return a.Distance < b.Distance
    end)

    for i, data in ipairs(buildingList) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(0.96, 0, 0, 32)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 6)
        ItemCorner.Parent = itemFrame

        -- ข้อความชื่อสิ่งก่อสร้าง (จำกัดความกว้างไว้ที่ 65%)
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(0.65, 0, 1, 0)
        logLabel.Position = UDim2.new(0.03, 0, 0, 0)
        logLabel.BackgroundTransparency = 1
        logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLabel.Font = Enum.Font.SourceSansBold
        logLabel.TextSize = 13
        logLabel.TextXAlignment = Enum.TextXAlignment.Left

        if data.Distance < 999999 then
            logLabel.Text = string.format("[%d] %s (%dm)", i, data.Name, data.Distance)
        else
            logLabel.Text = string.format("[%d] %s", i, data.Name)
        end
        logLabel.Parent = itemFrame

        -- ปุ่มกด [HIDE / SHOW] อยู่ด้านขวามือชัดเจน
        local toggleEspBtn = Instance.new("TextButton")
        toggleEspBtn.Size = UDim2.new(0.28, 0, 0.75, 0)
        toggleEspBtn.Position = UDim2.new(0.69, 0, 0.125, 0)
        toggleEspBtn.Font = Enum.Font.SourceSansBold
        toggleEspBtn.TextSize = 12

        local BtnItemCorner = Instance.new("UICorner")
        BtnItemCorner.CornerRadius = UDim.new(0, 4)
        BtnItemCorner.Parent = toggleEspBtn

        local isHidden = hiddenBuildings[data.Object] or false
        if isHidden then
            toggleEspBtn.Text = "SHOW ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            setBuildingHighlight(data.Object, false)
        else
            toggleEspBtn.Text = "HIDE ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            setBuildingHighlight(data.Object, true)
        end

        toggleEspBtn.MouseButton1Click:Connect(function()
            hiddenBuildings[data.Object] = not hiddenBuildings[data.Object]
            updateBuildingLogs()
        end)

        itemFrame.Parent = ScrollFrame
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buildingList * 38)
end

-- อัปเดตรายการและระยะทางแบบ Real-time
task.spawn(function()
    while task.wait(1.5) do
        if MainFrame.Visible then
            updateBuildingLogs()
        end
    end
end)

print("Building Logger UI Fixed!")
