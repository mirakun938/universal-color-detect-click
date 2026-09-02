-- [[ SAFE PIXEL DETECTOR WITH CENTER DOT TARGET ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- ป้องกัน Gui หายโดยลองใส่ใน CoreGui หรือ PlayerGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PersistentPixelDetectorGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999999

-- เช็กสิทธิ์การวาง ScreenGui เพื่อไม่ให้โดนเกมสั่งลบ
local success, _ = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success then
    screenGui.Parent = playerGui
end

-- ฟังก์ชันทำให้ UI ลากวางได้ปลอดภัย
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

-- สร้างวงกลมกลวง พร้อม "จุดเล็งเล็กๆ ตรงกลาง (Center Dot)"
local function createRingWithCenterDot(name, color, pos, labelText)
    local ring = Instance.new("Frame")
    ring.Name = name
    ring.Parent = screenGui
    ring.Size = UDim2.new(0, 50, 0, 50)
    ring.Position = pos
    ring.BackgroundTransparency = 1
    ring.Active = true

    local stroke = Instance.new("UIStroke")
    stroke.Parent = ring
    stroke.Color = color
    stroke.Thickness = 2.5

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    -- **จุดเล็งเล็กๆ ตรงกลาง (Center Dot Target)**
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Parent = ring
    centerDot.Size = UDim2.new(0, 4, 0, 4) -- ขนาดจุดเล็กเป๊ะๆ
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- สีเหลืองสังเกตง่าย
    centerDot.BorderSizePixel = 0
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Parent = ring
    label.Size = UDim2.new(1, 80, 0, 16)
    label.Position = UDim2.new(0, -15, -0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 11
    label.Font = Enum.Font.SourceSansBold

    makeDraggable(ring)
    return ring, centerDot
end

local detectRing, detectDot = createRingWithCenterDot("DetectRing", Color3.fromRGB(255, 50, 50), UDim2.new(0.22, 0, 0.45, 0), "1. จุดเล็งสี (Dot)")
local clickRing, clickDot = createRingWithCenterDot("ClickRing", Color3.fromRGB(50, 255, 50), UDim2.new(0.12, 0, 0.65, 0), "2. จุดกด (POUR)")

-- =========================================================
-- [UI Panel]
-- =========================================================
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Parent = screenGui
controlPanel.Size = UDim2.new(0, 190, 0, 110)
controlPanel.Position = UDim2.new(0.65, 0, 0.1, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlPanel.BackgroundTransparency = 0.15
Instance.new("UICorner", controlPanel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Parent = controlPanel
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Dot Target Detector V3"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.SourceSansBold

local colorPreview = Instance.new("Frame")
colorPreview.Name = "ColorPreview"
colorPreview.Parent = controlPanel
colorPreview.Size = UDim2.new(0, 16, 0, 16)
colorPreview.Position = UDim2.new(0.08, 0, 0.26, 0)
colorPreview.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(1, 0)

local lockColorBtn = Instance.new("TextButton")
lockColorBtn.Parent = controlPanel
lockColorBtn.Size = UDim2.new(0.72, 0, 0, 20)
lockColorBtn.Position = UDim2.new(0.2, 0, 0.24, 0)
lockColorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockColorBtn.Text = "🎯 ล็อกสีจากจุดเหลือง"
lockColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockColorBtn.TextSize = 11
Instance.new("UICorner", lockColorBtn).CornerRadius = UDim.new(0, 4)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = controlPanel
toggleBtn.Size = UDim2.new(0.84, 0, 0, 26)
toggleBtn.Position = UDim2.new(0.08, 0, 0.6, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

makeDraggable(controlPanel)

-- =========================================================
-- [ระบบตรวจจับสีตรงจุดพิกเซล Center Dot]
-- =========================================================
local targetColor = Color3.fromRGB(0, 255, 0)
local isRunning = false

-- อ่านค่าสีตรงตำแหน่งพิกเซลของ Center Dot
local function getDotPixelColor()
    local dotCenter = detectDot.AbsolutePosition + (detectDot.AbsoluteSize / 2)
    local guis = playerGui:GetGuiObjectsAtPosition(dotCenter.X, dotCenter.Y)
    
    for _, gui in ipairs(guis) do
        if not gui:IsDescendantOf(screenGui) and gui.Visible then
            if gui:IsA("GuiObject") and gui.BackgroundColor3 and gui.BackgroundTransparency < 1 then
                return gui.BackgroundColor3
            end
        end
    end
    return nil
end

lockColorBtn.MouseButton1Click:Connect(function()
    local c = getDotPixelColor()
    if c then
        targetColor = c
        colorPreview.BackgroundColor3 = c
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "AUTO CLICK: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        toggleBtn.Text = "AUTO CLICK: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- ฟังก์ชันยิงสัญญาณคลิกแบบไม่ให้ UI หาย
local function triggerInstantClick()
    local clickCenter = clickDot.AbsolutePosition + (clickDot.AbsoluteSize / 2)
    local guiInset = GuiService:GetGuiInset()
    local x = clickCenter.X
    local y = clickCenter.Y + guiInset.Y

    -- ยิงคลิกทันทีโดยใช้ pcall เพื่อกันสคริปต์หลุด
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)

        VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
        task.wait(0.01)
        VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(x, y, 0), game)
    end)
end

-- ลูปเช็กความต่างสีเฉพาะจุด Center Dot (หุ้ม pcall ป้องกันสคริปต์หลุดดับ)
local tolerance = 0.2

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    pcall(function()
        local currentColor = getDotPixelColor()
        if currentColor then
            local diffR = math.abs(currentColor.R - targetColor.R)
            local diffG = math.abs(currentColor.G - targetColor.G)
            local diffB = math.abs(currentColor.B - targetColor.B)

            -- เมื่อสีตรงจุดเหลืองเปลี่ยน หรือมีสีเป้าหมายวิ่งมาทับจุดเหลือง
            if (diffR + diffG + diffB) <= tolerance then
                triggerInstantClick()
                task.wait(0.25) -- คูลดาวน์กันกดซ้ำ
            end
        end
    end)
end)

print("🎯 [Persistent Dot Detector Ready] Script protected from disappearing!")
