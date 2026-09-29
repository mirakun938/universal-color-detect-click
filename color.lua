local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local isHolding = false
local spamSpeed = 0.02 -- ปรับความเร็วในการสแปมคลิกซ้าย (ยิ่งน้อยยิ่งเร็ว)

-- ลบ UI เก่าออกหากรันซ้ำ
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("LMBSpamGui")) or CoreGui:FindFirstChild("LMBSpamGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI ปุ่มสำหรับกดค้างเพื่อสแปม LMB
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "LMBSpamGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

HoldButton.Name = "LMBSpamBtn"
HoldButton.Parent = ScreenGui
HoldButton.Position = UDim2.new(0.82, 0, 0.65, 0)
HoldButton.Size = UDim2.new(0, 85, 0, 85)
HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
HoldButton.BackgroundTransparency = 0.3
HoldButton.Text = "HOLD TO\nSPAM LMB"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 14
HoldButton.Font = Enum.Font.SourceSansBold
HoldButton.Active = true
HoldButton.Draggable = true -- กดลากย้ายตำแหน่งได้ตามสะดวก

UICorner.CornerRadius = UDim.new(0, 45)
UICorner.Parent = HoldButton

-- ฟังก์ชันจำลองการคลิกเมาส์ซ้าย (LMB Click)
local function clickLMB()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    -- ส่งสัญญาณ LMB Press (กดลง)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    -- ส่งสัญญาณ LMB Release (ปล่อย)
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

-- ตรวจจับการกดค้างที่ปุ่ม UI
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
