-- [[ COLOR OVERLAY DETECTOR & AUTO CLICKER ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorOverlayDetectorGui"
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

-- =========================================================
-- [UI 1: กรอบตรวจจับสี (Detect Frame)]
-- =========================================================
local detectFrame = Instance.new("Frame")
detectFrame.Name = "DetectFrame"
detectFrame.Parent = screenGui
detectFrame.Size = UDim2.new(0, 70, 0, 70)
detectFrame.Position = UDim2.new(0.3, 0, 0.4, 0)
detectFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
detectFrame.BackgroundTransparency = 0.6
detectFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
detectFrame.BorderSizePixel = 2
detectFrame.Active = true

local detectLabel = Instance.new("TextLabel")
detectLabel.Parent = detectFrame
detectLabel.Size = UDim2.new(1, 0, 1, 0)
detectLabel.BackgroundTransparency = 1
detectLabel.Text = "1. จุดตรวจสี"
detectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
detectLabel.TextSize = 12
detectLabel.Font = Enum.Font.SourceSansBold

makeDraggable(detectFrame)

-- =========================================================
-- [UI 2: กรอบจุดกด (Click Target Frame)]
-- =========================================================
local clickFrame = Instance.new("Frame")
clickFrame.Name = "ClickFrame"
clickFrame.Parent = screenGui
clickFrame.Size = UDim2.new(0, 70, 0, 70)
clickFrame.Position = UDim2.new(0.6, 0, 0.4, 0)
clickFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
clickFrame.BackgroundTransparency = 0.6
clickFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
clickFrame.BorderSizePixel = 2
clickFrame.Active = true

local clickLabel = Instance.new("TextLabel")
clickLabel.Parent = clickFrame
clickLabel.Size = UDim2.new(1, 0, 1, 0)
clickLabel.BackgroundTransparency = 1
clickLabel.Text = "2. จุดกด"
clickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
clickLabel.TextSize = 12
clickLabel.Font = Enum.Font.SourceSansBold

makeDraggable(clickFrame)

-- =========================================================
-- [UI เมนูควบคุมการเลือกสี & สวิตช์เปิด/ปิด]
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
title.Text = "Color Overlay Detector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold

-- แสดงสีเป้าหมายที่เลือก
local colorPreview = Instance.new("Frame")
colorPreview.Name = "ColorPreview"
colorPreview.Parent = controlPanel
colorPreview.Size = UDim2.new(0, 20, 0, 20)
colorPreview.Position = UDim2.new(0.08, 0, 0.25, 0)
colorPreview.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- ค่าเริ่มต้น: สีแดง
Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(1, 0)

local colorText = Instance.new("TextLabel")
colorText.Parent = controlPanel
colorText.Size = UDim2.new(0.7, 0, 0, 20)
colorText.Position = UDim2.new(0.22, 0, 0.25, 0)
colorText.BackgroundTransparency = 1
colorText.Text = "สีหลักที่ต้องการตรวจจับ"
colorText.TextColor3 = Color3.fromRGB(200, 200, 200)
colorText.TextSize = 11
colorText.TextXAlignment = Enum.TextXAlignment.Left

-- ปุ่มเลือก Set สี Quick Presets
local presets = {
    { Name = "Red", Color = Color3.fromRGB(255, 0, 0) },
    { Name = "Green", Color = Color3.fromRGB(0, 255, 0) },
    { Name = "Blue", Color = Color3.fromRGB(0, 150, 255) },
    { Name = "Yellow", Color = Color3.fromRGB(255, 255, 0) },
    { Name = "White", Color = Color3.fromRGB(255, 255, 255) },
}

local selectedTargetColor = Color3.fromRGB(255, 0, 0) -- ค่าสีเป้าหมายที่ตั้งไว้
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

-- ปุ่มดึงสีปัจจุบันที่จุดตรวจจับ (Lock Current Color)
local lockColorBtn = Instance.new("TextButton")
lockColorBtn.Parent = controlPanel
lockColorBtn.Size = UDim2.new(0.84, 0, 0, 20)
lockColorBtn.Position = UDim2.new(0.08, 0, 0.68, 0)
lockColorBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockColorBtn.Text = "🎯 ดูดสีจากหน้าจอตรงจุดตรวจ"
lockColorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockColorBtn.TextSize = 11
Instance.new("UICorner", lockColorBtn).CornerRadius = UDim.new(0, 4)

-- ปุ่ม ON/OFF
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
-- [ฟังก์ชันอ่านสี & ตรวจจับการโดนทับ]
-- =========================================================
local function getColorAtDetectZone()
    local detectCenter = detectFrame.AbsolutePosition + (detectFrame.AbsoluteSize / 2)
    local guis = playerGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)

    for _, gui in ipairs(guis) do
        if not gui:IsDescendantOf(screenGui) and gui:IsA("GuiObject") and gui.Visible then
            return gui.BackgroundColor3
        end
    end
    return nil
end

lockColorBtn.MouseButton1Click:Connect(function()
    local currentColor = getColorAtDetectZone()
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

-- ลูปตรวจจับการทับของสี
local overlayThreshold = 0.25 -- ความไวการโดนทับ (ยิ่งน้อยยิ่งไว)

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    local currentColor = getColorAtDetectZone()
    if currentColor then
        -- เปรียบเทียบความต่างระหว่าง "สีหลักที่เลือก" กับ "สีปัจจุบันที่อยู่ตรงจุดตรวจ"
        local diffR = math.abs(currentColor.R - selectedTargetColor.R)
        local diffG = math.abs(currentColor.G - selectedTargetColor.G)
        local diffB = math.abs(currentColor.B - selectedTargetColor.B)
        local totalDifference = diffR + diffG + diffB

        -- ถ้าความต่างสีเพิ่มขึ้นอย่างรวดเร็ว (แสดงว่ามีสีอื่นวิ่งมาทับสีหลัก)
        if totalDifference > overlayThreshold then
            -- พิกัดจุดกด (Click Frame)
            local clickCenter = clickFrame.AbsolutePosition + (clickFrame.AbsoluteSize / 2)
            local guiInset = GuiService:GetGuiInset()
            
            local targetX = clickCenter.X
            local targetY = clickCenter.Y + guiInset.Y

            -- ส่งคลิก
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 1)

            task.wait(0.15) -- Cooldown ป้องกันการกดซ้ำรัวเกินไป
        end
    end
end)

print("🎯 [Color Overlay Detector] Ready! Set target color and start auto-clicking on overlay.")
