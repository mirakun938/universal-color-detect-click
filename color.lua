-- [[ ULTRA-SENSITIVE SCREEN PIXEL DETECTOR ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltraPixelDetector"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999999

pcall(function()
    screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
    screenGui.Parent = playerGui
end

-- ฟังก์ชันลากวาง
local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- สร้างวงกลม + จุดเป้าหมายตรงกลาง
local function createTargetRing(name, color, pos, labelText)
    local ring = Instance.new("Frame")
    ring.Name = name
    ring.Parent = screenGui
    ring.Size = UDim2.new(0, 40, 0, 40)
    ring.Position = pos
    ring.BackgroundTransparency = 1
    ring.Active = true

    local stroke = Instance.new("UIStroke")
    stroke.Parent = ring
    stroke.Color = color
    stroke.Thickness = 2

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local dot = Instance.new("Frame")
    dot.Name = "TargetDot"
    dot.Parent = ring
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0.5, 0, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Parent = ring
    label.Size = UDim2.new(1, 80, 0, 14)
    label.Position = UDim2.new(0, -20, -0.45, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 10
    label.Font = Enum.Font.SourceSansBold

    makeDraggable(ring)
    return ring, dot
end

local detectRing, detectDot = createTargetRing("DetectRing", Color3.fromRGB(255, 50, 50), UDim2.new(0.22, 0, 0.45, 0), "1. จุดตรวจจับ")
local clickRing, clickDot = createTargetRing("ClickRing", Color3.fromRGB(50, 255, 50), UDim2.new(0.12, 0, 0.65, 0), "2. จุดกด (POUR)")

-- Menu UI
local panel = Instance.new("Frame")
panel.Parent = screenGui
panel.Size = UDim2.new(0, 180, 0, 90)
panel.Position = UDim2.new(0.68, 0, 0.08, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
panel.BackgroundTransparency = 0.2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Parent = panel
status.Size = UDim2.new(1, 0, 0, 25)
status.BackgroundTransparency = 1
status.Text = "ระบบ: ปิดการทำงาน"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 11

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = panel
toggleBtn.Size = UDim2.new(0.85, 0, 0, 32)
toggleBtn.Position = UDim2.new(0.075, 0, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "เปิดระบบตรวจจับ"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

makeDraggable(panel)

-- =========================================================
-- [ระบบตรวจจับความเปลี่ยนแปลงของวัตถุบนพิกเซล]
-- =========================================================
local isRunning = false

toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "ปิดระบบตรวจจับ"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        status.Text = "กำลังเฝ้าดูจุดเล็งเหลือง..."
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        toggleBtn.Text = "เปิดระบบตรวจจับ"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        status.Text = "ระบบ: ปิดการทำงาน"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- ฟังก์ชันสั่งกดลงพิกัดปุ่ม
local function doPress()
    local clickCenter = clickDot.AbsolutePosition + (clickDot.AbsoluteSize / 2)
    local guiInset = GuiService:GetGuiInset()
    local x = clickCenter.X
    local y = clickCenter.Y + guiInset.Y

    -- ซ่อน UI แวบเดียวเพื่อให้การกดเข้าปุ่มเกมแน่นอน
    screenGui.Enabled = false

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)

    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
    task.wait(0.01)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(x, y, 0), game)

    screenGui.Enabled = true
end

-- สแกนวัตถุแบบครอบคลุม Image, Frame, Text, Canvas
local lastUIObj = nil

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    pcall(function()
        local dotPos = detectDot.AbsolutePosition + (detectDot.AbsoluteSize / 2)
        local objectsAtPoint = playerGui:GetGuiObjectsAtPosition(dotPos.X, dotPos.Y)

        local foundAnyObject = nil
        for _, obj in ipairs(objectsAtPoint) do
            if not obj:IsDescendantOf(screenGui) and obj.Visible then
                foundAnyObject = obj
                break
            end
        end

        -- เมื่อมีวัตถุ (เช่น แถบสี/เข็มวัด) เคลื่อนที่เข้ามาทับจุดเล็งเหลือง
        if foundAnyObject and foundAnyObject ~= lastUIObj then
            lastUIObj = foundAnyObject
            status.Text = "🎯 ตรวจพบการทับ! สั่งกดแล้ว"
            doPress()
            task.wait(0.3) -- คูลดาวน์กันกดซ้ำ
        elseif not foundAnyObject then
            lastUIObj = nil
        end
    end)
end)

print("🎯 [Ultra Pixel Detector Ready]")
