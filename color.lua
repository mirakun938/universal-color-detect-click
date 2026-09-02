-- [[ PIXEL COLOR DETECTOR & ACCURATE TOUCH CLICKER ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ScreenGui หลัก
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PixelDetectorGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999999
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

-- สร้างวงกลมกลวง (Hollow Circle) เพื่อไม่ให้บังการกด
local function createRing(name, color, pos, labelText)
    local ring = Instance.new("Frame")
    ring.Name = name
    ring.Parent = screenGui
    ring.Size = UDim2.new(0, 46, 0, 46)
    ring.Position = pos
    ring.BackgroundTransparency = 1
    ring.Active = true

    local stroke = Instance.new("UIStroke")
    stroke.Parent = ring
    stroke.Color = color
    stroke.Thickness = 3

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local label = Instance.new("TextLabel")
    label.Parent = ring
    label.Size = UDim2.new(1, 80, 0, 16)
    label.Position = UDim2.new(0, -17, -0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = color
    label.TextSize = 11
    label.Font = Enum.Font.SourceSansBold

    makeDraggable(ring)
    return ring
end

local detectRing = createRing("DetectRing", Color3.fromRGB(255, 50, 50), UDim2.new(0.22, 0, 0.45, 0), "1. จุดตรวจจับสี")
local clickRing = createRing("ClickRing", Color3.fromRGB(50, 255, 50), UDim2.new(0.12, 0, 0.65, 0), "2. จุดกด (POUR)")

-- =========================================================
-- [UI Panel]
-- =========================================================
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Parent = screenGui
controlPanel.Size = UDim2.new(0, 190, 0, 100)
controlPanel.Position = UDim2.new(0.65, 0, 0.1, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
controlPanel.BackgroundTransparency = 0.2
Instance.new("UICorner", controlPanel).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Parent = controlPanel
title.Size = UDim2.new(1, 0, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Pixel Auto-Clicker V2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.SourceSansBold

local statusText = Instance.new("TextLabel")
statusText.Parent = controlPanel
statusText.Size = UDim2.new(1, 0, 0, 20)
statusText.Position = UDim2.new(0, 0, 0.25, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "สถานะ: รอเปิดการทำงาน"
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 11

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = controlPanel
toggleBtn.Size = UDim2.new(0.84, 0, 0, 28)
toggleBtn.Position = UDim2.new(0.08, 0, 0.58, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Text = "AUTO CLICK: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

makeDraggable(controlPanel)

-- =========================================================
-- [ระบบอ่านสี Image/UI และจำลอง Touch Event]
-- =========================================================
local isRunning = false

toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "AUTO CLICK: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusText.Text = "กำลังตรวจจับวัตถุเคลื่อนที่..."
        statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        toggleBtn.Text = "AUTO CLICK: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusText.Text = "สถานะ: ปิดการทำงาน"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- ฟังก์ชันสแกนหาวัตถุ UI/Image ที่ผ่านจุดตรวจ
local function getPixelObjectAtDetector()
    local detectCenter = detectRing.AbsolutePosition + (detectRing.AbsoluteSize / 2)
    local guis = playerGui:GetGuiObjectsAtPosition(detectCenter.X, detectCenter.Y)
    
    for _, gui in ipairs(guis) do
        if not gui:IsDescendantOf(screenGui) and gui.Visible then
            -- ถ้าเป็น ImageLabel หรือ Frame ใดๆ ที่ปรากฏขึ้นมาตรงจุดนั้น
            if gui:IsA("ImageLabel") or gui:IsA("ImageButton") or gui:IsA("Frame") then
                return gui
            end
        end
    end
    return nil
end

-- ฟังก์ชันส่งสัญญาณกด Touch ตรงปุ่ม POUR
local function doTouchClick()
    local clickCenter = clickRing.AbsolutePosition + (clickRing.AbsoluteSize / 2)
    local guiInset = GuiService:GetGuiInset()
    local x = clickCenter.X
    local y = clickCenter.Y + guiInset.Y

    -- ซ่อน UI ชั่วคราว 0.01 วินาที เพื่อให้คำสั่ง Touch ทะลุแน่ 100%
    screenGui.Enabled = false

    -- ส่งคำสั่งคลิกเมาส์
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)

    -- ส่งคำสั่งแตะหน้าจอมือถือ (Touch Event)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
    task.wait(0.02)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(targetX, targetY, 0), game)

    screenGui.Enabled = true
end

-- ลูปตรวจจับการผ่านของตัวชี้บนแถบวัด
local lastDetectedObject = nil

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    local detectedObj = getPixelObjectAtDetector()
    
    -- เมื่อพบว่ามีเข็ม/แถบสีเคลื่อนที่เข้ามาทับจุดตรวจจับ
    if detectedObj and detectedObj ~= lastDetectedObject then
        lastDetectedObject = detectedObj
        
        -- สั่งกดที่ปุ่ม POUR ทันที
        doTouchClick()
        
        statusText.Text = "🎯 ตรวจพบวัตถุ! สั่งกดแล้ว"
        task.wait(0.3) -- Cooldown
    elseif not detectedObj then
        lastDetectedObject = nil
    end
end)

print("🎯 [Pixel Detector Ready] Ready to detect UI objects and trigger touch clicks.")
