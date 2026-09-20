local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ตารางเก็บสถานะการสั่งซ่อน ESP
local hiddenBuildings = {}

-- ฟังก์ชันค้นหาชิ้นส่วน Part ภายในโมเดลสิ่งก่อสร้าง
local function getBuildingPart(building)
    if not building then return nil end
    if building:IsA("BasePart") then return building end
    
    local primary = building.PrimaryPart or building:FindFirstChildOfClass("BasePart")
    if primary then return primary end
    
    for _, desc in ipairs(building:GetDescendants()) do
        if desc:IsA("BasePart") then
            return desc
        end
    end
    return nil
end

-- ฟังก์ชันจัดการ Highlight สีเขียว
local function applyHighlight(building, enable)
    if not building then return end
    
    local highlight = building:FindFirstChild("BuildingStreamHighlight")
    
    if enable then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BuildingStreamHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = Color3.fromRGB(0, 255, 127) -- สีเขียว
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.Adornee = building
            highlight.Parent = building
        end
        highlight.Enabled = true
    else
        if highlight then
            highlight.Enabled = false
        end
    end
end

-- ==================== UI MAIN MENU ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuildingLoggerGui_InlineBtn"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มเปิด/ปิด เมนูหลัก
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

-- 2. หน้าต่างเมนูหลัก
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.02, 0, 0.26, 0)
MainFrame.Size = UDim2.new(0, 340, 0, 270)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- Header
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Building Detector & Stream ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- 3. Scroll Frame แสดงรายการ Log
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

-- ==================== ระบบสร้างรายการแบบปุ่มอยู่ต่อท้ายชื่อ ====================
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
        local targetPart = getBuildingPart(building)
        local distance = 999999
        
        if hrp and targetPart then
            distance = math.floor((hrp.Position - targetPart.Position).Magnitude)
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
        itemFrame.Size = UDim2.new(0.98, 0, 0, 34)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 6)
        ItemCorner.Parent = itemFrame

        -- Layout แนวนอนสำหรับวาง [ชื่อสิ่งก่อสร้าง] แล้วต่อด้วย [ปุ่มกด]
        local rowListLayout = Instance.new("UIListLayout")
        rowListLayout.Parent = itemFrame
        rowListLayout.FillDirection = Enum.FillDirection.Horizontal
        rowListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowListLayout.Padding = UDim.new(0, 8)

        -- เว้นระยะขอบซ้าย
        local padding = Instance.new("UIPadding")
        padding.Parent = itemFrame
        padding.PaddingLeft = UDim.new(0, 10)

        -- 1. ข้อความบอกชื่อและระยะทาง เช่น [1] house6 (377m)
        local logLabel = Instance.new("TextLabel")
        logLabel.Parent = itemFrame
        logLabel.Size = UDim2.new(0, 190, 1, 0)
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

        -- 2. ปุ่มซ่อน/แสดง ESP อยู่ต่อท้ายชื่อทันที
        local toggleEspBtn = Instance.new("TextButton")
        toggleEspBtn.Parent = itemFrame
        toggleEspBtn.Size = UDim2.new(0, 85, 0, 24)
        toggleEspBtn.Font = Enum.Font.SourceSansBold
        toggleEspBtn.TextSize = 11

        local BtnItemCorner = Instance.new("UICorner")
        BtnItemCorner.CornerRadius = UDim.new(0, 4)
        BtnItemCorner.Parent = toggleEspBtn

        local isHidden = hiddenBuildings[data.Object] or false
        if isHidden then
            toggleEspBtn.Text = "SHOW ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 0) -- สีส้ม
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            applyHighlight(data.Object, false)
        else
            toggleEspBtn.Text = "HIDE ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100) -- สีเขียว
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            applyHighlight(data.Object, true)
        end

        toggleEspBtn.MouseButton1Click:Connect(function()
            hiddenBuildings[data.Object] = not hiddenBuildings[data.Object]
            updateBuildingLogs()
        end)
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buildingList * 40)
end

-- Loop อัปเดต Highlight และสแกนระยะทางแบบ Real-time
task.spawn(function()
    while task.wait(1) do
        if buildingsFolder then
            for _, building in ipairs(buildingsFolder:GetChildren()) do
                if not hiddenBuildings[building] then
                    applyHighlight(building, true)
                else
                    applyHighlight(building, false)
                end
            end
        end
        
        if MainFrame.Visible then
            updateBuildingLogs()
        end
    end
end)

print("Inline Button Building Logger Loaded Successfully!")
