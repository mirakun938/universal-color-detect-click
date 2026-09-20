local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- การตั้งค่า
local MARK_DISTANCE = 25 -- ระยะที่ถือว่าเดินมาถึงแล้ว (หน่วยเป็น Studs / ประมาณ 25 เมตร)
local visitedBuildings = {} -- ตารางบันทึกบ้านที่เคยเดินไปถึงแล้ว
local isSystemEnabled = true -- สถานะเปิด/ปิดระบบสคริปต์

-- ฟังก์ชันจัดการ Highlight และ Billboard
local function updateBuildingMark(model)
    if not model:IsA("Model") and not model:IsA("Folder") then return end

    -- 1. สร้าง Highlight
    local highlight = model:FindFirstChild("VisitedHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "VisitedHighlight"
        highlight.Adornee = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
    end

    -- 2. สร้าง BillboardGui ป้ายแสดงระยะทาง
    local billboard = model:FindFirstChild("VisitedBillboard")
    if not billboard then
        local primary = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
        if primary then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "VisitedBillboard"
            billboard.Adornee = primary
            billboard.Size = UDim2.new(0, 120, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop = true
            
            local label = Instance.new("TextLabel")
            label.Name = "TextLabel"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(85, 255, 127)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 13
            label.Parent = billboard

            billboard.Parent = model
        end
    end

    -- ตรวจสอบสถานะว่าเคยไปถึงหรือยัง
    local isVisited = visitedBuildings[model] or false

    if isSystemEnabled and not isVisited then
        -- แบบที่ 1: ยังไม่เคยไปถึง -> แสดง Highlight สีเขียว + ESP ระยะทาง
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
                    label.Text = string.format("%s\n[%d m]", model.Name, dist)
                end
            end
        end
    else
        -- แบบที่ 2: เดินไปถึงแล้ว (Visited) หรือ ปิดระบบ -> ซ่อน Highlight & ESP ทันที
        highlight.Enabled = false
        if billboard then
            billboard.Enabled = false
        end
    end
end

-- ระบบตรวจจับการเข้าใกล้สิ่งก่อสร้างแบบ Real-time
task.spawn(function()
    while task.wait(0.3) do
        if isSystemEnabled and buildingsFolder and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = LocalPlayer.Character.HumanoidRootPart.Position
            
            for _, building in ipairs(buildingsFolder:GetChildren()) do
                if not visitedBuildings[building] then
                    local primary = building.PrimaryPart or building:FindFirstChildOfClass("BasePart")
                    if primary then
                        local distance = (myPos - primary.Position).Magnitude
                        
                        -- ถ้าเข้าใกล้ระยะที่กำหนด มาร์กว่า "มาถึงแล้ว"
                        if distance <= MARK_DISTANCE then
                            visitedBuildings[building] = true
                            print("Visited Building:", building.Name)
                        end
                    end
                end
                updateBuildingMark(building)
            end
        end
    end
end)

-- ==================== Main Menu UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProximityBuildingMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด เมนู
local MenuBtn = Instance.new("TextButton")
MenuBtn.Parent = ScreenGui
MenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MenuBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
MenuBtn.Size = UDim2.new(0, 110, 0, 35)
MenuBtn.Font = Enum.Font.SourceSansBold
MenuBtn.Text = "MENU [MARK]"
MenuBtn.TextColor3 = Color3.fromRGB(85, 255, 127)
MenuBtn.TextSize = 13
MenuBtn.Active = true
MenuBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = MenuBtn

-- กรอบ Main Menu
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 140)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Proximity Auto-Mark"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15

-- ปุ่มรีเซ็ตการมาร์กทั้งหมด (Reset Visited)
local ResetBtn = Instance.new("TextButton")
ResetBtn.Parent = MainFrame
ResetBtn.Position = UDim2.new(0.05, 0, 0.28, 0)
ResetBtn.Size = UDim2.new(0.9, 0, 0, 35)
ResetBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.Text = "Reset Visited Markers"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 13

local RCorner = Instance.new("UICorner")
RCorner.CornerRadius = UDim.new(0, 6)
RCorner.Parent = ResetBtn

-- ปุ่ม Toggle ปิด/เปิดระบบ
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = MainFrame
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "Hide All ESP [OFF]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(0, 6)
TCorner.Parent = ToggleBtn

-- ระบบการคลิก UI
MenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

ResetBtn.MouseButton1Click:Connect(function()
    visitedBuildings = {} -- ล้างค่าที่เคยบันทึกไว้ เพื่อให้กลับมาขยายสีเขียวใหม่ทั้งหมด
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isSystemEnabled = not isSystemEnabled
    if isSystemEnabled then
        ToggleBtn.Text = "Hide All ESP [OFF]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    else
        ToggleBtn.Text = "Hide All ESP [ON]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end)

print("Proximity Building Auto-Mark Loaded Successfully!")
