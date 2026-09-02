-- [[ COLOR DETECTOR & AUTO CLICKER WITH DUAL UI ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. สร้าง ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorDetectorGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

-- ฟังก์ชันสำหรับทำให้ Frame ลากวาง (Drag) ได้บนมือถือและ PC
local function makeDraggable(guiObject)
    local dragging = false
    local dragInput, dragStart, startPos

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
-- [UI ที่ 1: กรอบตรวจจับสีเคลื่อนที่ (Color Detector)]
-- =========================================================
local detectFrame = Instance.new("Frame")
detectFrame.Name = "DetectFrame"
detectFrame.Parent = screenGui
detectFrame.Size = UDim2.new(0, 80, 0, 80)
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
detectLabel.Text = "1. จุดตรวจจับสี"
detectLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
detectLabel.TextSize = 12
detectLabel.Font = Enum.Font.SourceSansBold

makeDraggable(detectFrame)

-- =========================================================
-- [UI ที่ 2: กรอบตำแหน่งการกด (Click Target)]
-- =========================================================
local clickFrame = Instance.new("Frame")
clickFrame.Name = "ClickFrame"
clickFrame.Parent = screenGui
clickFrame.Size = UDim2.new(0, 80, 0, 80)
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
clickLabel.Text = "2. จุดกด (Click)"
clickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
clickLabel.TextSize = 12
clickLabel.Font = Enum.Font.SourceSansBold

makeDraggable(clickFrame)

-- =========================================================
-- [UI เมนูควบคุมการทำงาน (Toggle On/Off Panel)]
-- =========================================================
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Parent = screenGui
controlPanel.Size = UDim2.new(0, 160, 0, 50)
controlPanel.Position = UDim2.new(0.4, 0, 0.1, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
controlPanel.BackgroundTransparency = 0.2
Instance.new("UICorner", controlPanel).CornerRadius = UDim.new(0, 8)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = controlPanel
toggleBtn.Size = UDim2.new(0.9, 0, 0.7, 0)
toggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

makeDraggable(controlPanel)

-- =========================================================
-- [ระบบตรวจจับ Pixel GUI และส่งสัญญาณกด]
-- =========================================================
local isRunning = false
local sensitivity = 0.15 -- ความไวในการตรวจจับสีเปลี่ยน (0.1 = ไวมาก)

-- ฟังก์ชันค้นหาจุด UI ที่ผ่านตำแหน่ง Detector
local function checkColorChangeAtDetector()
    local detectCenter = detectFrame.AbsolutePosition + (detectFrame.AbsoluteSize / 2)
    local guis = playerGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)
    
    for _, gui in ipairs(guis) do
        -- ข้าม UI ของสคริปต์เราเอง
        if not gui:IsDescendantOf(screenGui) then
            -- เช็กว่าวัตถุมีสี หรือแทบสีเคลื่อนที่ผ่านหรือไม่
            if gui:IsA("GuiObject") and gui.Visible then
                return gui.BackgroundColor3
            end
        end
    end
    return nil
end

local lastColor = nil

toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "AUTO CLICK: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        lastColor = checkColorChangeAtDetector()
    else
        toggleBtn.Text = "AUTO CLICK: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- ลูปเช็กสีและสั่งกด
RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    local currentColor = checkColorChangeAtDetector()
    if currentColor and lastColor then
        -- คำนวณค่าความต่างของสี (RGB Difference)
        local diffR = math.abs(currentColor.R - lastColor.R)
        local diffG = math.abs(currentColor.G - lastColor.G)
        local diffB = math.abs(currentColor.B - lastColor.B)
        local totalDiff = diffR + diffG + diffB

        -- ถ้าสีเคลื่อนที่หรือเปลี่ยนไปเกินค่า Sensitivity
        if totalDiff > sensitivity then
            -- ดึงพิกัดศูนย์กลางของกรอบกด (Click Frame)
            local clickCenter = clickFrame.AbsolutePosition + (clickFrame.AbsoluteSize / 2)
            local guiInset = GuiService:GetGuiInset()
            
            local targetX = clickCenter.X
            local targetY = clickCenter.Y + guiInset.Y

            -- ส่งคำสั่งคลิกลงพิกัดกรอบกดทันที
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 1)

            -- อัปเดตค่าสีล่าสุด
            lastColor = currentColor
            task.wait(0.1) -- หน่วงเวลาป้องกันการกดรัวซ้ำซ้อน
        end
    else
        lastColor = currentColor
    end
end)

print("🎯 [Color Detector & Auto Clicker] Loaded! Drag UI frames to setup positions.")
