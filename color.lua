local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local isHolding = false
local spamSpeed = 0.03 -- ความเร็วในการสแปม (ยิ่งน้อยยิ่งเร็ว)

-- ลบ UI เก่าออกหากมีอยู่
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("UseSpamOverlayGui")) or CoreGui:FindFirstChild("UseSpamOverlayGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง ScreenGui และ ปุ่มสำหรับกดค้าง
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "UseSpamOverlayGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

HoldButton.Name = "HoldSpamBtn"
HoldButton.Parent = ScreenGui
-- ตั้งค่าปุ่มให้อยู่โซนขวาล่าง (บริเวณปุ่ม Use)
HoldButton.Position = UDim2.new(0.82, 0, 0.65, 0)
HoldButton.Size = UDim2.new(0, 80, 0, 80)
HoldButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.BackgroundTransparency = 0.6 -- ปุ่มโปร่งแสงเพื่อให้เห็นปุ่มเดิมด้านหลัง
HoldButton.Text = "SPAM\nATTACK"
HoldButton.TextColor3 = Color3.fromRGB(0, 0, 0)
HoldButton.TextSize = 14
HoldButton.Font = Enum.Font.SourceSansBold
HoldButton.Active = true
HoldButton.Draggable = true -- สามารถกดลากปรับตำแหน่งให้ตรงกับปุ่ม Use ได้

UICorner.CornerRadius = UDim.new(0, 40) -- ปุ่มทรงกลม
UICorner.Parent = HoldButton

-- ฟังก์ชันยิงการแตะ/คลิกตรงพิกัดของปุ่มนี้
local function clickAtButtonPosition()
    local pos = HoldButton.AbsolutePosition
    local size = HoldButton.AbsoluteSize
    local centerX = pos.X + (size.X / 2)
    local centerY = pos.Y + (size.Y / 2) + 36 -- ชดเชยระยะ Topbar

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- ลูปสแปม
local function startSpam()
    task.spawn(function()
        while isHolding do
            clickAtButtonPosition()
            task.wait(spamSpeed)
        end
    end)
end

-- ตรวจจับการกดค้างที่ปุ่มลอย
HoldButton.MouseButton1Down:Connect(function()
    if not isHolding then
        isHolding = true
        HoldButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        startSpam()
    end
end)

HoldButton.MouseButton1Up:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)

HoldButton.MouseLeave:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)
