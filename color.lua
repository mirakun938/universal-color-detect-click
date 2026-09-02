-- [[ PERFECT CENTER AUTO POUR WITH DELAY COMPENSATION ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- สร้าง ScreenGui แสดงสถานะ
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "AutoPourTracker"
statusGui.ResetOnSpawn = false

pcall(function() statusGui.Parent = CoreGui end)
if not statusGui.Parent then statusGui.Parent = playerGui end

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusGui
statusLabel.Size = UDim2.new(0, 260, 0, 40)
statusLabel.Position = UDim2.new(0.5, -130, 0.05, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "กำลังค้นหา UI เกม..."
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)

-- 🎯 ตั้งค่าความแม่นยำตรงนี้
local TRIGGER_DISTANCE = 12     -- ระยะห่างพิกเซลที่จะเริ่มยิงกด (ยิ่งน้อยยิ่งใกล้จุดศูนย์กลาง)
local OFFSET_COMPENSATION = 3.0 -- สั่งกดล่วงหน้าก่อนถึงจุดจริงเพื่อชดเชย Ping/Delay (ปรับเพิ่ม-ลดได้)

local isPressed = false
local lastIndX = nil

RunService.RenderStepped:Connect(function()
    pcall(function()
        local buildUI = playerGui:FindFirstChild("BuildStationUI")
        if not buildUI or not buildUI.Enabled then 
            statusLabel.Text = "⏳ รอเริ่มมินิเกม Pour..."
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            isPressed = false
            lastIndX = nil
            return 
        end

        local pourMeter = buildUI:FindFirstChild("PourMeter")
        if not pourMeter or not pourMeter.Visible then 
            statusLabel.Text = "⏳ รอเปิดหลอดวัด PourMeter..."
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            isPressed = false
            lastIndX = nil
            return 
        end

        local indicator = pourMeter:FindFirstChild("Indicator")
        local meterBar = pourMeter:FindFirstChild("MeterBar")
        local pourBtn = pourMeter:FindFirstChild("PourButton")
        
        if pourBtn and pourBtn:FindFirstChild("ActualButton") then
            pourBtn = pourBtn.ActualButton
        end

        if indicator and meterBar and pourBtn then
            -- พิกัดจุดศูนย์กลาง X จริงของเข็ม และ แถบวัด
            local indX = indicator.AbsolutePosition.X + (indicator.AbsoluteSize.X / 2)
            local barX = meterBar.AbsolutePosition.X + (meterBar.AbsoluteSize.X / 2)
            
            -- คำนวณทิศทางการวิ่งของเข็ม (วิ่งไปทางขวา หรือ วิ่งไปทางซ้าย)
            local isMovingRight = true
            if lastIndX then
                isMovingRight = (indX >= lastIndX)
            end
            lastIndX = indX

            -- คำนวณพิกัดล่วงหน้าเพื่อสวนดีเลย์ (Offset Compensation)
            local adjustedIndX = indX
            if isMovingRight then
                adjustedIndX = indX + OFFSET_COMPENSATION -- เข็มวิ่งไปทางขวา ให้คิดตำแหน่งนำหน้าไปทางขวา
            else
                adjustedIndX = indX - OFFSET_COMPENSATION -- เข็มวิ่งไปทางซ้าย ให้คิดตำแหน่งนำหน้าไปทางซ้าย
            end

            -- ระยะห่างหลังชดเชยดีเลย์
            local diff = math.abs(adjustedIndX - barX)
            statusLabel.Text = string.format("ระยะห่างชดเชย: %.1f px", diff)

            -- เมื่อระยะห่างชดเชยเข้าใกล้จุดศูนย์กลางสีเขียว
            if diff <= TRIGGER_DISTANCE then
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                
                if not isPressed then
                    isPressed = true
                    statusLabel.Text = "🎯 Perfect Click! (ยิงคำสั่งกดแล้ว)"

                    local guiInset = GuiService:GetGuiInset()
                    local clickX = pourBtn.AbsolutePosition.X + (pourBtn.AbsoluteSize.X / 2)
                    local clickY = pourBtn.AbsolutePosition.Y + (pourBtn.AbsoluteSize.Y / 2) + guiInset.Y

                    -- ยิงคำสั่งกดทันทีด้วยดีเลย์ที่สั้นที่สุด (0.005 วินาที)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                    task.wait(0.005)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

                    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(clickX, clickY, 0), game)
                    task.wait(0.005)
                    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(clickX, clickY, 0), game)
                end
            else
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                if diff > TRIGGER_DISTANCE + 15 then
                    isPressed = false
                end
            end
        end
    end)
end)
