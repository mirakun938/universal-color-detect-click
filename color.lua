local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ตารางบันทึกบ้านที่สั่งซ่อนไว้
local hiddenBuildings = {}

-- ฟังก์ชันใส่ Highlight ให้สิ่งก่อสร้าง (รองรับกรณีไม่มี PrimaryPart)
local function setBuildingHighlight(building, enable)
    if not building then return end
    
    local highlight = building:FindFirstChild("BuildingLoggerHighlight")
    
    if enable then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BuildingLoggerHighlight"
            
            -- ค้นหา Part เพื่อเป็นเป้าหมาย Highlight
            local adorneeTarget = building.PrimaryPart or building:FindFirstChildOfClass("BasePart")
            if not adorneeTarget then
                for _, desc in ipairs(building:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        adorneeTarget = desc
                        break
                    end
                end
            end
            
            highlight.Adornee = adorneeTarget or building
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = Color3.fromRGB(0, 255, 127) -- สีเขียว
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- เส้นขอบสีขาว
            highlight.FillTransparency = 0.4
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
ScreenGui.Name = "BuildingLoggerGui_v3"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มเปิด/ปิด เมนูหลัก
local MenuBtn = Instance.new("TextButton")
MenuBtn.Name = "MenuButton"
MenuBtn.Parent = ScreenGui
MenuBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MenuBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
MenuBtn.Size = UDim2.new(0, 120, 0, 38)
MenuBtn.Font = Enum.Font.SourceSansBold
MenuBtn.Text = "LOGS [BUILD]"
MenuBtn.TextColor3 = Color3.fromRGB(85, 255, 127)
MenuBtn.TextSize = 14
MenuBtn.Active = true
MenuBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = MenuBtn

-- 2. หน้าต่าง Main Menu Frame (ขยายความกว้างให้เห็นปุ่มชัดเจน)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
MainFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 250) -- ขยายขนาดกว้าง 320px
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

-- หัวข้อ Menu
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Building Detector & ESP Logs"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- 3. Scroll Frame แสดงรายการพร้อมปุ่ม Hide
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Parent = MainFrame
ScrollFrame.Position = UDim2.new(0.03, 0, 0.16, 0)
ScrollFrame.Size = UDim2.new(0.94, 0, 0.8, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)

-- เปิด/ปิด หน้าต่าง UI
MenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==================== ระบบ Render แถบรายการ + ปุ่ม [HIDE/SHOW] ====================
local function updateBuildingLogs()
    -- ล้างรายการเก่าก่อนวาดใหม่
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    if not buildingsFolder then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local buildingList = {}

    -- สแกนรวบรวมสิ่งก่อสร้าง
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

    -- เรียงลำดับใกล้สุดขึ้นก่อน
    table.sort(buildingList, function(a, b)
        return a.Distance < b.Distance
    end)

    -- วาดแต่ละรายการสิ่งก่อสร้าง
    for i, data in ipairs(buildingList) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(0.98, 0, 0, 32)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 6)
        ItemCorner.Parent = itemFrame

        -- ข้อความชื่อสิ่งก่อสร้าง + ระยะทาง
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

        -- ปุ่มเปิด-ปิด ESP [HIDE / SHOW] ด้านขวามือ
        local toggleEspBtn = Instance.new("TextButton")
        toggleEspBtn.Size = UDim2.new(0.28, 0, 0.75, 0)
        toggleEspBtn.Position = UDim2.new(0.68, 0, 0.125, 0)
        toggleEspBtn.Font = Enum.Font.SourceSansBold
        toggleEspBtn.TextSize = 12

        local BtnItemCorner = Instance.new("UICorner")
        BtnItemCorner.CornerRadius = UDim.new(0, 5)
        BtnItemCorner.Parent = toggleEspBtn

        local isHidden = hiddenBuildings[data.Object] or false
        if isHidden then
            toggleEspBtn.Text = "SHOW ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 0) -- สีส้ม
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            setBuildingHighlight(data.Object, false)
        else
            toggleEspBtn.Text = "HIDE ESP"
            toggleEspBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100) -- สีเขียว
            toggleEspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            setBuildingHighlight(data.Object, true)
        end

        -- ระบบคลิกเปลี่ยนโหมด
        toggleEspBtn.MouseButton1Click:Connect(function()
            hiddenBuildings[data.Object] = not hiddenBuildings[data.Object]
            updateBuildingLogs()
        end)

        itemFrame.Parent = ScrollFrame
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buildingList * 38)
end

-- สแกนอัปเดตระยะทางอัตโนมัติทุก 1.5 วินาที
task.spawn(function()
    while task.wait(1.5) do
        if MainFrame.Visible then
            updateBuildingLogs()
        end
    end
end)

print("Building ESP Logger v3 Loaded!")
