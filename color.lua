local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- ค่าสถานะโหมด: 1 = Highlight สีเขียว + ESP, 2 = ซ่อนทั้งหมด (Hidden)
local currentMode = 1

-- ฟังก์ชันสร้าง/ปรับแต่ง Highlight และ BillboardGui
local function updateBuildingMark(model)
    if not model:IsA("Model") and not model:IsA("Folder") then return end

    -- 1. จัดการ Highlight
    local highlight = model:FindFirstChild("BuildingHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "BuildingHighlight"
        highlight.Adornee = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
    end

    -- 2. จัดการ BillboardGui (ป้ายชื่อและระยะทาง)
    local billboard = model:FindFirstChild("BuildingBillboard")
    if not billboard then
        local primaryPart = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
        if primaryPart then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "BuildingBillboard"
            billboard.Adornee = primaryPart
            billboard.Size = UDim2.new(0, 150, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 5, 0)
            billboard.AlwaysOnTop = true
            
            local label = Instance.new("TextLabel")
            label.Name = "TextLabel"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(85, 255, 127)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.Parent = billboard

            billboard.Parent = model
        end
    end

    -- อัปเดตตามโหมดปัจจุบัน
    if currentMode == 1 then
        -- โหมดที่ 1: Highlight สีเขียว + แสดง ESP
        highlight.FillColor = Color3.fromRGB(0, 255, 127) -- สีเขียว
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = true

        if billboard then
            billboard.Enabled = true
            local label = billboard:FindFirstChild("TextLabel")
            if label then
                local primary = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
                if primary and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - primary.Position).Magnitude)
                    label.Text = string.format("[%s]\n%d m", model.Name, dist)
                else
                    label.Text = model.Name
                end
            end
        end
    elseif currentMode == 2 then
        -- โหมดที่ 2: ซ่อน Highlight และ ESP ทั้งหมด
        highlight.Enabled = false
        if billboard then
            billboard.Enabled = false
        end
    end
end

-- สแกนอัปเดตสิ่งก่อสร้างทั้งหมด
local function refreshAllBuildings()
    if not buildingsFolder then return end
    for _, child in ipairs(buildingsFolder:GetChildren()) do
        updateBuildingMark(child)
    end
end

-- ==================== สร้าง UI Main Menu ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BuildingMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด เมนูหลัก
local OpenMenuBtn = Instance.new("TextButton")
OpenMenuBtn.Name = "OpenMenuButton"
OpenMenuBtn.Parent = ScreenGui
OpenMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenMenuBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
OpenMenuBtn.Size = UDim2.new(0, 100, 0, 35)
OpenMenuBtn.Font = Enum.Font.SourceSansBold
OpenMenuBtn.Text = "MENU [BUILD]"
OpenMenuBtn.TextColor3 = Color3.fromRGB(85, 255, 127)
OpenMenuBtn.TextSize = 14
OpenMenuBtn.Draggable = true

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 6)
OpenCorner.Parent = OpenMenuBtn

-- หน้าต่าง Main Menu Frame
local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MainFrame"
MenuFrame.Parent = ScreenGui
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MenuFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
MenuFrame.Size = UDim2.new(0, 200, 0, 150)
MenuFrame.Visible = false
MenuFrame.Active = true
MenuFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MenuFrame

-- หัวข้อ Menu
local Title = Instance.new("TextLabel")
Title.Parent = MenuFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Building ESP Manager"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16

-- ปุ่มโหมดที่ 1 (Highlight สีเขียว)
local Mode1Btn = Instance.new("TextButton")
Mode1Btn.Parent = MenuFrame
Mode1Btn.Position = UDim2.new(0.05, 0, 0.28, 0)
Mode1Btn.Size = UDim2.new(0.9, 0, 0, 35)
Mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
Mode1Btn.Font = Enum.Font.SourceSansBold
Mode1Btn.Text = "Mode 1: Green Highlight"
Mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Mode1Btn.TextSize = 13

local M1Corner = Instance.new("UICorner")
M1Corner.CornerRadius = UDim.new(0, 6)
M1Corner.Parent = Mode1Btn

-- ปุ่มโหมดที่ 2 (ซ่อนทั้งหมด)
local Mode2Btn = Instance.new("TextButton")
Mode2Btn.Parent = MenuFrame
Mode2Btn.Position = UDim2.new(0.05, 0, 0.6, 0)
Mode2Btn.Size = UDim2.new(0.9, 0, 0, 35)
Mode2Btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
Mode2Btn.Font = Enum.Font.SourceSansBold
Mode2Btn.Text = "Mode 2: Hide All ESP"
Mode2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Mode2Btn.TextSize = 13

local M2Corner = Instance.new("UICorner")
M2Corner.CornerRadius = UDim.new(0, 6)
M2Corner.Parent = Mode2Btn

-- ระบบการทำงานของปุ่ม
OpenMenuBtn.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

Mode1Btn.MouseButton1Click:Connect(function()
    currentMode = 1
    Mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 220, 120)
    Mode2Btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    refreshAllBuildings()
end)

Mode2Btn.MouseButton1Click:Connect(function()
    currentMode = 2
    Mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
    Mode2Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    refreshAllBuildings()
end)

-- Loop อัปเดตรายชื่อสิ่งก่อสร้างใหม่ที่เกิดแบบไม่จำกัด
if buildingsFolder then
    refreshAllBuildings()

    buildingsFolder.ChildAdded:Connect(function(newBuilding)
        task.wait(0.2)
        updateBuildingMark(newBuilding)
    end)
    
    -- อัปเดตระยะทางแบบ Real-time
    task.spawn(function()
        while task.wait(1) do
            if currentMode == 1 then
                refreshAllBuildings()
            end
        end
    end)
end

print("Building Main Menu & Multi-Mode ESP Loaded!")
