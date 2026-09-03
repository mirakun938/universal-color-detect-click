-- [[ AUTO FISHING & SKILL CHECK SCRIPT ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- สร้างหน้าจอ UI แสดงสถานะ
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "AutoFishingStatus"
statusGui.ResetOnSpawn = false

pcall(function() statusGui.Parent = CoreGui end)
if not statusGui.Parent then statusGui.Parent = playerGui end

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusGui
statusLabel.Size = UDim2.new(0, 280, 0, 40)
statusLabel.Position = UDim2.new(0.5, -140, 0.05, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "🎣 พร้อมตกปลา..."
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)

-- ฟังก์ชันจำลองการกดปุ่ม
local function clickGuiObject(btn)
    if not btn or not btn.Visible then return end
    local guiInset = GuiService:GetGuiInset()
    local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
    local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + guiInset.Y

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
    task.wait(0.01)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(x, y, 0), game)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- 1. เช็กระบบ ReelIn (ดึงสายเมื่อปลาตอด)
        local fishingGui = playerGui:FindFirstChild("FishingGui")
        if fishingGui then
            local reelIn = fishingGui:FindFirstChild("ReelIn")
            if reelIn and reelIn.Visible then
                statusLabel.Text = "🎣 ปลาติดเบ็ดแล้ว! กำลังกด Reel In..."
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                clickGuiObject(reelIn)
                return
            end
        end

        -- 2. เช็กมินิเกม FishingMinigameGui
        local minigameGui = playerGui:FindFirstChild("FishingMinigameGui")
        if not minigameGui or not minigameGui.Enabled then
            statusLabel.Text = "⏳ รอเริ่มมินิเกมตกปลา..."
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            return
        end

        local root = minigameGui:FindFirstChild("Root")
        if not root or not root.Visible then return end

        -- 2.1 ตรวจจับและกดปุ่ม SHAKE อัตโนมัติ (QTEBounds)
        local qteBounds = root:FindFirstChild("QTEBounds")
        if qteBounds and qteBounds.Visible then
            local shakeBtn = qteBounds:FindFirstChildWhichIsA("GuiObject", true)
            if shakeBtn and shakeBtn.Visible then
                statusLabel.Text = "⚡ เจอปุ่ม SHAKE! กำลังกด..."
                statusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
                clickGuiObject(shakeBtn)
            end
        end

        -- 2.2 อ่านค่าโฟลเดอร์ State เพื่อคุมทิศทางหลอดสีเขียว
        local stateFolder = minigameGui:FindFirstChild("State") or root:FindFirstChild("State")
        local controls = root:FindFirstChild("ControlsFrame")
        
        if stateFolder and controls then
            local markerX = stateFolder:FindFirstChild("MarkerX") and stateFolder.MarkerX.Value
            local safeX = stateFolder:FindFirstChild("SafeX") and stateFolder.SafeX.Value
            local safeWidth = stateFolder:FindFirstChild("SafeWidth") and stateFolder.SafeWidth.Value
            
            local leftBtn = controls:FindFirstChild("LeftButton")
            local rightBtn = controls:FindFirstChild("RightButton")

            if markerX and safeX and safeWidth and leftBtn and rightBtn then
                -- จุดศูนย์กลางของหลอดสีเขียว
                local safeCenter = safeX + (safeWidth / 2)
                
                -- ระยะห่างระหว่างปลากับศูนย์กลางหลอด
                local diff = markerX - safeCenter

                if math.abs(diff) <= 5 then
                    statusLabel.Text = "🎯 หลอดครอบตัวปลาอยู่ (Perfect)"
                    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif diff > 5 then
                    -- ปลายู่ทางขวามากกว่าหลอด -> กดปุ่มขวา
                    statusLabel.Text = "➡️ ปลายู่ขวา -> กำลังเลื่อนขวา"
                    statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                    clickGuiObject(rightBtn)
                elseif diff < -5 then
                    -- ปลายู่ทางซ้ายมากกว่าหลอด -> กดปุ่มซ้าย
                    statusLabel.Text = "⬅️ ปลายู่ซ้าย -> กำลังเลื่อนซ้าย"
                    statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                    clickGuiObject(leftBtn)
                end
            end
        end
    end)
end)
