-- [[ HOLLOW CIRCLE COLOR DETECTOR & AUTO CLICKER ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HollowCircleColorGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

-- ฟังก์ชันทำให้ Ring ลากวางได้
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

-- ฟังก์ชันสร้าง "วงกลมกลวง" (Hollow Ring) ที่ไม่บังตรงกลาง
local function createHollowRing(name, color, initialPos, labelText)
    local ringFrame = Instance.new("Frame")
    ringFrame.Name = name
    ringFrame.Parent = screenGui
    ringFrame.Size = UDim2.new(0, 60, 0, 60)
    ringFrame.Position = initialPos
    ringFrame.BackgroundTransparency = 1 -- ตรงกลางโปร่งใส 100% ไม่บังการกด
    ringFrame.Active = true

    -- เส้นขอบวงกลมกลวงนอก
    local stroke = Instance.new("UIStroke")
    stroke.Parent = ringFrame
    stroke.Color = color
    stroke.Thickness = 4
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ringFrame

    -- ข้อความกำกับ
    local label = Instance.new("TextLabel")
    label.Parent = ringFrame
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 0, -0.35, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 11
    label.Font = Enum.Font.SourceSansBold

    makeDraggable(ringFrame)
    return ringFrame
end

-- =========================================================
-- [สร้างจุดวางแบบวงกลมกลวง 2 วง]
-- =========================================================
local detectRing = createHollowRing("DetectRing", Color3.fromRGB(255, 50, 50), UDim2.new(0.3, 0, 0.4, 0), "1. จุดตรวจจับสี")
local clickRing = createHollowRing("ClickRing", Color3.fromRGB(50, 255, 50), UDim2.new(0.6, 0, 0.4, 0), "2. จุดกด")

-- =========================================================
-- [UI เมนูควบคุม]
-- =========================================================
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Parent = screenGui
controlPanel.Size = UDim2.new(0, 200, 0, 130)
controlPanel.Position = UDim2.new(0.35, 0, 0.08, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
controlPanel.BackgroundTransparency = 0.1
Instance.new("UICorner", controlPanel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Parent = controlPanel
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "Hollow Ring Color Detector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold

local colorPreview = Instance.new("Frame")
colorPreview.Name = "ColorPreview"
colorPreview.Parent = controlPanel
colorPreview.Size = UDim2.new(0, 20, 0, 20)
colorPreview.Position = UDim2.new(0.08, 0, 0.25, 0)
colorPreview.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(1, 0)

local colorText = Instance.new("TextLabel")
colorText.Parent = controlPanel
colorText.Size = UDim2.new(0.7, 0, 0, 20)
colorText.Position = UDim2.new(0.22, 0, 0.25, 0)
colorText.BackgroundTransparency = 1
colorText.Text = "สีเป้าหมายหลัก"
colorText.TextColor3 = Color3.fromRGB(200, 200, 200)
colorText.TextSize = 11
colorText.TextXAlignment = Enum.TextXAlignment.Left

local presets = {
    { Name = "Red", Color = Color3.fromRGB(255, 0, 0) },
    { Name = "Green", Color = Color3.fromRGB(0, 255, 0) },
    { Name = "Blue", Color = Color3.fromRGB(0, 150, 255) },
    { Name = "Yellow", Color = Color3.fromRGB(255, 255, 0) },
    { Name = "White", Color = Color3.fromRGB(255, 255, 255) },
}

local selectedTargetColor = Color3.fromRGB(255, 0, 0)
local isRunning = false

for i, p in ipairs(presets) do
    local pBtn = Instance.new("TextButton")
    pBtn.Parent = controlPanel
    pBtn.Size = UDim2.new(0, 32, 0, 20)
    pBtn.Position = UDim2.new(0.08 + ((i - 1) * 0.17), 0, 0.48, 0)
    pBtn.BackgroundColor3 = p.Color
    pBtn.Text = ""
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)

    pBtn.MouseButton1Click:Connect(function()
        selectedTargetColor = p.Color
        colorPreview.BackgroundColor3 = p.Color
    end)
end

local lockColorBtn = Instance.new("TextButton")
lockColorBtn.Parent = controlPanel
lockColorBtn.Size = UDim2.new(0.84, 0, 0, 20)
lockColorBtn.Position = UDim2.new(0.08, 0, 0.68, 0)
lockColorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockColorBtn.Text = "🎯 ดูดสี UI เกมจากกลางวงกลม"
lockColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockColorBtn.TextSize = 11
Instance.new("UICorner", lockColorBtn).CornerRadius = UDim.new(0, 4)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = controlPanel
toggleBtn.Size = UDim2.new(0.84, 0, 0, 22)
toggleBtn.Position = UDim2.new(0.08, 0, 0.85, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

makeDraggable(controlPanel)

-- =========================================================
-- [DEEP SCAN COLOR DETECTION (อ่านค่าสี UI เกมจริง)]
-- =========================================================
local function getDeepGameGuiColor()
    local detectCenter = detectRing.AbsolutePosition + (detectRing.AbsoluteSize / 2)
    
    -- 1. สแกนจาก PlayerGui ก่อน
    local guis = playerGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)
    for _, gui in ipairs(guis) do
        if not gui:IsDescendantOf(screenGui) and gui:IsA("GuiObject") and gui.Visible then
            if gui.BackgroundColor3 then return gui.BackgroundColor3 end
        end
    end

    -- 2. สแกนจาก CoreGui (กรณี UI เกมเขียนซ่อนในระดับ Core)
    pcall(function()
        local coreGuis = CoreGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)
        for _, gui in ipairs(coreGuis) do
            if not gui:IsDescendantOf(screenGui) and gui:IsA("GuiObject") and gui.Visible then
                if gui.BackgroundColor3 then return gui.BackgroundColor3 end
            end
        end
    end)

    return nil
end

lockColorBtn.MouseButton1Click:Connect(function()
    local currentColor = getDeepGameGuiColor()
    if currentColor then
        selectedTargetColor = currentColor
        colorPreview.BackgroundColor3 = currentColor
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

-- ลูปการทำงาน
local overlayThreshold = 0.2

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    local currentColor = getDeepGameGuiColor()
    if currentColor then
        local diffR = math.abs(currentColor.R - selectedTargetColor.R)
        local diffG = math.abs(currentColor.G - selectedTargetColor.G)
        local diffB = math.abs(currentColor.B - selectedTargetColor.B)
        local totalDifference = diffR + diffG + diffB

        -- ตรวจพบว่าสีถูกทับ/เปลี่ยนไป
        if totalDifference > overlayThreshold then
            -- พิกัดศูนย์กลางรูวงกลมจุดกด
            local clickCenter = clickRing.AbsolutePosition + (clickRing.AbsoluteSize / 2)
            local guiInset = GuiService:GetGuiInset()
            
            local targetX = clickCenter.X
            local targetY = clickCenter.Y + guiInset.Y

            -- ส่งคลิกตรงทะลุรูวงกลมลงไปที่ตัวเกม
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 1)

            task.wait(0.12) -- Cooldown
        end
    end
end)

print("⭕ [Hollow Circle Detector] Ready! Center is transparent for accurate clicks.")
