local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local buildingsFolder = Workspace:WaitForChild("buildings", 10)

local SEARCH_RADIUS = 150 -- ระยะค้นหาสิ่งก่อสร้างรอบตัวผู้เล่น (สตัด/Studs)

-- ฟังก์ชันค้นหาสิ่งก่อสร้างที่อยู่ใกล้ผู้เล่นที่สุด
local function getClosestBuilding()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local playerPos = character.HumanoidRootPart.Position
    local closestBuilding = nil
    local shortestDistance = SEARCH_RADIUS

    if buildingsFolder then
        for _, building in ipairs(buildingsFolder:GetChildren()) do
            -- คำนวณหาตำแหน่งศูนย์กลางของสิ่งก่อสร้าง
            local primaryPart = building:IsA("Model") and (building.PrimaryPart or building:FindFirstChildOfClass("BasePart")) or building:FindFirstChildOfClass("BasePart")
            
            if primaryPart then
                local distance = (primaryPart.Position - playerPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestBuilding = building
                end
            end
        end
    end
    
    return closestBuilding, shortestDistance
end

-- ฟังก์ชันยืนยันและปักหมุด ESP ใส่สิ่งก่อสร้าง
local function markBuilding(building)
    if not building then return end

    -- 1. เพิ่ม Highlight เรืองแสงทะลุกำแพง
    local highlight = building:FindFirstChild("MarkedBuildingESP")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MarkedBuildingESP"
        highlight.Adornee = building
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = Color3.fromRGB(0, 255, 127)   -- สีเขียวสว่าง (แสดงว่ายืนยันแล้ว)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.Parent = building
    end

    -- 2. สร้างป้ายชื่อ (BillboardGui) ปักหมุดบอกตำแหน่ง
    local targetPart = building:IsA("Model") and (building.PrimaryPart or building:FindFirstChildOfClass("BasePart")) or building
    if targetPart and not targetPart:FindFirstChild("BuildingLabel") then
        local billboard = Instance.new("BillboardGui")
        local textLabel = Instance.new("TextLabel")

        billboard.Name = "BuildingLabel"
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 8, 0) -- ยกป้ายชื่อขึ้นสูงเหนือสิ่งก่อสร้าง
        billboard.AlwaysOnTop = true
        billboard.Parent = targetPart

        textLabel.Parent = billboard
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "🏠 " .. building.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- ตัวหนังสือสีเหลือง
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 18
    end
end

-- ==================== UI กดเพื่อยืนยันตำแหน่ง ====================
local ScreenGui = Instance.new("ScreenGui")
local MarkButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "MarkBuildingGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

MarkButton.Name = "MarkButton"
MarkButton.Parent = ScreenGui
MarkButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- สีฟ้า
MarkButton.Position = UDim2.new(0.02, 0, 0.48, 0)
MarkButton.Size = UDim2.new(0, 160, 0, 45)
MarkButton.Font = Enum.Font.SourceSansBold
MarkButton.Text = "📌 Mark Building"
MarkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MarkButton.TextSize = 16.00
MarkButton.Active = true
MarkButton.Draggable = true -- ลากปุ่มเคลื่อนย้ายบนหน้าจอมือถือได้

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MarkButton

-- เมื่อกดปุ่ม ยืนยันสิ่งก่อสร้างที่อยู่ใกล้เรา
MarkButton.MouseButton1Click:Connect(function()
    local closestBuilding, dist = getClosestBuilding()
    
    if closestBuilding then
        markBuilding(closestBuilding)
        
        -- เอฟเฟกต์ปุ่มแจ้งเตือนเมื่อกดสำเร็จ
        MarkButton.Text = "✓ Marked!"
        MarkButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        task.wait(1)
        MarkButton.Text = "📌 Mark Building"
        MarkButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    else
        MarkButton.Text = "❌ No Building Near"
        MarkButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        MarkButton.Text = "📌 Mark Building"
        MarkButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end
end)

print("Building Position Marker Loaded!")
