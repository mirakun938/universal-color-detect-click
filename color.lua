local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local isHolding = false
local isLocked = true -- ตั้งค่าเริ่มต้นให้ล็อคตำแหน่งไว้
local spamSpeed = 0.02 -- ความเร็วในการสแปมคลิกซ้าย

-- ลบ UI เก่าออกหากมีอยู่
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("CenterLMBSpamGui")) or CoreGui:FindFirstChild("CenterLMBSpamGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI หลัก
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local HoldCorner = Instance.new("UICorner")

local LockButton = Instance.new("TextButton")
local LockCorner = Instance.new("UICorner")

ScreenGui.Name = "CenterLMBSpamGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มสแปมหลัก (ตั้งไว้ตรงกลางหน้าจอ)
HoldButton.Name = "HoldSpamBtn"
HoldButton.Parent = ScreenGui
HoldButton.AnchorPoint = Vector2.new(0.5, 0.5)
HoldButton.Position = UDim2.new(0.5, 0, 0.5, 0) -- พิกัดกึ่งกลางหน้าจอ
HoldButton.Size = UDim2.new(0, 90, 0, 90)
HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
HoldButton.BackgroundTransparency = 0.3
HoldButton.Text = "HOLD TO\nSPAM LMB"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 14
HoldButton.Font = Enum.Font.SourceSansBold
HoldButton.Active = true
HoldButton.Draggable = not isLocked

HoldCorner.CornerRadius = UDim.new(0, 45)
HoldCorner.Parent = HoldButton

-- 2. ปุ่มเล็กสำหรับ ล็อค/ปลดล็อก การลาก
LockButton.Name = "LockToggleBtn"
LockButton.Parent = ScreenGui
LockButton.AnchorPoint = Vector2.new(0.5, 0)
LockButton.Position = UDim2.new(0.5, 0, 0.5, 55) -- วางไว้ใต้ปุ่มหลักเล็กน้อย
LockButton.Size = UDim2.new(0, 70, 0, 25)
LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LockButton.BackgroundTransparency = 0.2
LockButton.Text = "🔒 Lock"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 12
LockButton.Font = Enum.Font.SourceSansBold
LockButton.Active = true

LockCorner.CornerRadius = UDim.new(0, 6)
LockCorner.Parent = LockButton

-- ฟังก์ชันสลับสถานะ ล็อค/ปลดล็อก
LockButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    HoldButton.Draggable = not isLocked
    
    if isLocked then
        LockButton.Text = "🔒 Lock"
        LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        LockButton.Text = "🔓 Unlock"
        LockButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    end
end)

-- ฟังก์ชันจำลองการคลิกเมาส์ซ้าย (LMB Click)
local function clickLMB()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- ลูปสแปม LMB
local function startSpam()
    task.spawn(function()
        while isHolding do
            clickLMB()
            task.wait(spamSpeed)
        end
    end)
end

-- ตรวจจับการกดค้าง
HoldButton.MouseButton1Down:Connect(function()
    if not isHolding then
        isHolding = true
        HoldButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        startSpam()
    end
end)

HoldButton.MouseButton1Up:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)

HoldButton.MouseLeave:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)
