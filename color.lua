local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local buildingsFolder = Workspace:WaitForChild("buildings", 10)

-- การตั้งค่า Highlight
local FILL_COLOR = Color3.fromRGB(255, 170, 0)   -- สีภายใน (สีส้มทอง)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255) -- สีเส้นขอบ (สีขาว)
local FILL_TRANSPARENCY = 0.5                     -- ความโปร่งใสข้างใน (0 = ทึบ, 1 = ล่องหน)
local OUTLINE_TRANSPARENCY = 0                   -- ความโปร่งใสเส้นขอบ

local isEspEnabled = true

-- ฟังก์ชันใส่ Highlight ให้สิ่งก่อสร้าง
local function applyBuildingESP(model)
    if not model:IsA("Model") and not model:IsA("Folder") then return end
    
    -- สร้าง หรือ ดึง Highlight เดิมที่มีอยู่แล้ว
    local highlight = model:FindFirstChild("BuildingESP")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "BuildingESP"
        highlight.Adornee = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- มองเห็นทะลุกำแพง
        highlight.Parent = model
    end

    -- อัปเดตสีและความโปร่งใสตามสถานะการเปิด/ปิด
    highlight.FillColor = FILL_COLOR
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.FillTransparency = isEspEnabled and FILL_TRANSPARENCY or 1
    highlight.OutlineTransparency = isEspEnabled and OUTLINE_TRANSPARENCY or 1
    highlight.Enabled = isEspEnabled
end

-- สแกนสิ่งก่อสร้างทั้งหมดในโฟลเดอร์ buildings
local function refreshAllBuildings()
    if not buildingsFolder then return end
    
    for _, child in ipairs(buildingsFolder:GetChildren()) do
        applyBuildingESP(child)
    end
end

-- ==================== ระบบ UI Toggle ====================
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "BuildingEspGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "BuildingEspButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- สีส้ม (ON)
ToggleButton.Position = UDim2.new(0.02, 0, 0.48, 0)
ToggleButton.Size = UDim2.new(0, 140, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "House ESP: ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16.00
ToggleButton.Active = true
ToggleButton.Draggable = true -- ลากปุ่มเคลื่อนย้ายได้บนมือถือ

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

-- ระบบคลิกเปิด-ปิด UI
ToggleButton.MouseButton1Click:Connect(function()
    isEspEnabled = not isEspEnabled
    
    if isEspEnabled then
        ToggleButton.Text = "House ESP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    else
        ToggleButton.Text = "House ESP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    refreshAllBuildings()
end)

if buildingsFolder then
    print("Building ESP Loaded Successfully!")
    refreshAllBuildings()

    -- ดักจับเมื่อมีสิ่งก่อสร้างใหม่เกิดเข้ามาในโฟลเดอร์
    buildingsFolder.ChildAdded:Connect(function(newBuilding)
        task.wait(0.2)
        applyBuildingESP(newBuilding)
    end)
else
    warn("ไม่พบโฟลเดอร์ 'buildings' ใน Workspace")
end
