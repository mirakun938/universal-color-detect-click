local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ระยะทำการสูงสุดของ ESP (10,000 เมตร)
local MAX_ESP_DISTANCE = 10000 

-- ฟังก์ชันหา Part หลักภายในโมเดลสิ่งก่อสร้าง
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

-- ฟังก์ชันสร้าง/อัปเดต Highlight + ป้ายชื่อพร้อมระยะทาง (BillboardGui)
local function updateBuildingESP(building, distance, enable)
    if not building then return end
    
    local highlight = building:FindFirstChild("BuildingLoggerHighlight")
    local billboard = building:FindFirstChild("BuildingLoggerBillboard")
    local targetPart = getBuildingPart(building)

    if enable and targetPart then
        -- 1. จัดการ Highlight สีเขียว
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

        -- 2. จัดการ ป้ายชื่อและระยะทาง (BillboardGui)
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "BuildingLoggerBillboard"
            billboard.Adornee = targetPart
            billboard.Size = UDim2.new(0, 160, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 6, 0) -- ความสูงลอยเหนือตัวบ้าน
            billboard.AlwaysOnTop = true

            local label = Instance.new("TextLabel")
            label.Name = "ESPLabel"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(85, 255, 127) -- ตัวอักษรสีเขียวสด
            label.TextStrokeTransparency = 0 -- มีเส้นขอบดำรอบตัวอักษรให้อ่านง่าย
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.Parent = billboard

            billboard.Parent = building
        else
            billboard.Adornee = targetPart
        end

        -- อัปเดตข้อความ ป้ายชื่อ + ระยะทาง
        local label = billboard:FindFirstChild("ESPLabel")
        if label then
            label.Text = string.format("%s\n[%d m]", building.Name, distance)
        end
        billboard.Enabled = true

    else
        -- ถ้าเกินระยะ 10,000m ให้ปิดการแสดงผลทั้งหมด
        if highlight then highlight.Enabled = false end
        if billboard then billboard.Enabled = false end
    end
end

-- ==================== UI MAIN MENU (LOGS ONLY) ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuildingLoggerGui_FullESP"
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

-- 2. หน้าต่างเมนูหลัก
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(0.02, 0, 0.26, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- หัวข้อ Menu
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Building Logs & Full ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- 3. Scroll Frame แสดงรายการ Log
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Position = UDim2.new(0.04, 0, 0.15, 0)
ScrollFrame.Size = UDim2.new(0.92, 0, 0.82, 0)
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

-- ==================== ระบบสแกนและอัปเดต Real-time ====================
local function updateBuildingLogsAndESP()
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

        -- เช็คระยะทางไม่เกิน 10,000 เมตร
        if distance <= MAX_ESP_DISTANCE then
            updateBuildingESP(building, distance, true)
            
            table.insert(buildingList, {
                Object = building,
                Name = building.Name,
                Distance = distance
            })
        else
            updateBuildingESP(building, distance, false)
        end
    end

    -- อัปเดตรายการใน UI Logs เมื่อเปิดเมนู
    if MainFrame.Visible then
        for _, child in ipairs(ScrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        table.sort(buildingList, function(a, b)
            return a.Distance < b.Distance
        end)

        for i, data in ipairs(buildingList) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(0.98, 0, 0, 30)
            itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

            local ItemCorner = Instance.new("UICorner")
            ItemCorner.CornerRadius = UDim.new(0, 6)
            ItemCorner.Parent = itemFrame

            local logLabel = Instance.new("TextLabel")
            logLabel.Size = UDim2.new(0.95, 0, 1, 0)
            logLabel.Position = UDim2.new(0.03, 0, 0, 0)
            logLabel.BackgroundTransparency = 1
            logLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            logLabel.Font = Enum.Font.SourceSansBold
            logLabel.TextSize = 13
            logLabel.TextXAlignment = Enum.TextXAlignment.Left

            if data.Distance < 999999 then
                logLabel.Text = string.format("[%d] %s (%dm)", i, data.Name, data.Distance)
            else
                logLabel.Text = string.format("[%d] %s", i, data.Name)
            end
            logLabel.Parent = itemFrame

            itemFrame.Parent = ScrollFrame
        end

        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buildingList * 36)
    end
end

-- Loop สแกนอัปเดตระยะทางและป้าย ESP ทุกๆ 0.5 วินาที
task.spawn(function()
    while task.wait(0.5) do
        updateBuildingLogsAndESP()
    end
end)

print("Full ESP Name & Distance Billboard Loaded!")
