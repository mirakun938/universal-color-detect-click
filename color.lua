-- [[ COLOR DETECTOR & AUTO CLICKER FOR MINI-GAMES ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- 1. ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DrinkGameColorDetector"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

-- ฟังก์ชันทำให้ UI ลากวางได้
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

-- สร้างวงกลมกลวง (Hollow Ring)
local function createHollowRing(name, color, initialPos, labelText)
    local ringFrame = Instance.new("Frame")
    ringFrame.Name = name
    ringFrame.Parent = screenGui
    ringFrame.Size = UDim2.new(0, 50, 0, 50)
    ringFrame.Position = initialPos
    ringFrame.BackgroundTransparency = 1
    ringFrame.Active = true

    local stroke = Instance.new("UIStroke")
    stroke.Parent = ringFrame
    stroke.Color = color
    stroke.Thickness = 3

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ringFrame

    local label = Instance.new("TextLabel")
    label.Parent = ringFrame
    label.Size = UDim2.new(1, 100, 0, 16)
    label.Position = UDim2.new(0, -25, -0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 11
    label.Font = Enum.Font.SourceSansBold

    makeDraggable(ringFrame)
    return ringFrame
end

local detectRing = createHollowRing("DetectRing", Color3.fromRGB(255, 50, 50), UDim2.new(0.22, 0, 0.45, 0), "1. จุดตรวจสี")
local clickRing = createHollowRing("ClickRing", Color3.fromRGB(50, 255, 50), UDim2.new(0.12, 0, 0.65, 0), "2. จุดกด (POUR)")

-- =========================================================
-- [UI เมนูควบคุม]
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
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "Color Auto-Clicker"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold

local colorPreview = Instance.new("Frame")
colorPreview.Name = "ColorPreview"
colorPreview.Parent = controlPanel
colorPreview.Size = UDim2.new(0, 18, 0, 18)
colorPreview.Position = UDim2.new(0.08, 0, 0.28, 0)
colorPreview.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(1, 0)

local colorText = Instance.new("TextLabel")
colorText.Parent = controlPanel
colorText.Size = UDim2.new(0.7, 0, 0, 18)
colorText.Position = UDim2.new(0.22, 0, 0.28, 0)
colorText.BackgroundTransparency = 1
colorText.Text = "สีเป้าหมาย (สีแถบเขียว)"
colorText.TextColor3 = Color3.fromRGB(200, 200, 200)
colorText.TextSize = 11
colorText.TextXAlignment = Enum.TextXAlignment.Left

local lockColorBtn = Instance.new("TextButton")
lockColorBtn.Parent = controlPanel
lockColorBtn.Size = UDim2.new(0.84, 0, 0, 20)
lockColorBtn.Position = UDim2.new(0.08, 0, 0.52, 0)
lockColorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockColorBtn.Text = "🎯 ดูดสีจากจุดตรวจ"
lockColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockColorBtn.TextSize = 11
Instance.new("UICorner", lockColorBtn).CornerRadius = UDim.new(0, 4)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = controlPanel
toggleBtn.Size = UDim2.new(0.84, 0, 0, 22)
toggleBtn.Position = UDim2.new(0.08, 0, 0.76, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

makeDraggable(controlPanel)

-- =========================================================
-- [ระบบตรวจจับสีผ่าน Screen Objects]
-- =========================================================
local selectedTargetColor = Color3.fromRGB(0, 255, 0)
local isRunning = false

local function getScreenPixelColor()
    local detectCenter = detectRing.AbsolutePosition + (detectRing.AbsoluteSize / 2)
    local guis = playerGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)
    
    for _, gui in ipairs(guis) do
        if not gui:IsDescendantOf(screenGui) and gui:IsA("GuiObject") and gui.Visible then
            if gui.BackgroundColor3 and gui.BackgroundTransparency < 1 then
                return gui.BackgroundColor3
            end
        end
    end
    return nil
end

lockColorBtn.MouseButton1Click:Connect(function()
    local c = getScreenPixelColor()
    if c then
        selectedTargetColor = c
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

-- ฟังก์ชันส่งสัญญาณแตะ/คลิกตรงปุ่มเกม
local function triggerTargetClick()
    local clickCenter = clickRing.AbsolutePosition + (clickRing.AbsoluteSize / 2)
    local guiInset = GuiService:GetGuiInset()
    local targetX = clickCenter.X
    local targetY = clickCenter.Y + guiInset.Y

    -- ปิดวงกลมชั่วคราวชั่วเสี้ยววินาทีเพื่อให้การแตะทะลุ 100%
    clickRing.Visible = false
    detectRing.Visible = false

    VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 1)
    task.wait(0.03)
    VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 1)

    -- สั่งจำลอง Touch Event ชดเชยสำหรับอุปกรณ์มือถือ
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(targetX, targetY, 0), game)
    task.wait(0.03)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(targetX, targetY, 0), game)

    clickRing.Visible = true
    detectRing.Visible = true
end

-- ลูปเช็กความต่างสีเพื่อสั่งกด
local threshold = 0.18

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    local currentColor = getScreenPixelColor()
    if currentColor then
        local diffR = math.abs(currentColor.R - selectedTargetColor.R)
        local diffG = math.abs(currentColor.G - selectedTargetColor.G)
        local diffB = math.abs(currentColor.B - selectedTargetColor.B)

        -- เมื่อสีตรงหรือมีการเคลื่อนที่มาทับตรงแถบตรวจ
        if (diffR + diffG + diffB) < threshold then
            triggerTargetClick()
            task.wait(0.2) -- คูลดาวน์
        end
    end
end)

print("🎯 [Drink Game Detector Ready] Place Ring 1 on progress bar & Ring 2 on POUR button.")
