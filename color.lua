-- [[ REAL-TIME POSITION TRACKER AUTO POUR ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- สร้างหน้าจอ GUI แจ้งเตือนสถานะ
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "AutoPourTracker"
statusGui.ResetOnSpawn = false

pcall(function() statusGui.Parent = CoreGui end)
if not statusGui.Parent then statusGui.Parent = playerGui end

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusGui
statusLabel.Size = UDim2.new(0, 240, 0, 40)
statusLabel.Position = UDim2.new(0.5, -120, 0.05, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "กำลังค้นหา UI เกม..."
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)

-- กำหนดระยะความห่าง (พิกเซล) ที่ต้องการให้ยิงสั่งกด (ปรับเพิ่ม-ลดได้)
local TRIGGER_DISTANCE = 18 

local isPressed = false

RunService.RenderStepped:Connect(function()
    pcall(function()
        local buildUI = playerGui:FindFirstChild("BuildStationUI")
        if not buildUI or not buildUI.Enabled then 
            statusLabel.Text = "⏳ รอเริ่มมินิเกม Pour..."
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            isPressed = false
            return 
        end

        local pourMeter = buildUI:FindFirstChild("PourMeter")
        if not pourMeter or not pourMeter.Visible then 
            statusLabel.Text = "⏳ รอเปิดหลอดวัด PourMeter..."
            statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            isPressed = false
            return 
        end

        local indicator = pourMeter:FindFirstChild("Indicator")
        local meterBar = pourMeter:FindFirstChild("MeterBar")
        local pourBtn = pourMeter:FindFirstChild("PourButton")
        
        if pourBtn and pourBtn:FindFirstChild("ActualButton") then
            pourBtn = pourBtn.ActualButton
        end

        if indicator and meterBar and pourBtn then
            -- คำนวณพิกัดจุดศูนย์กลาง X ของเข็ม และ แถบวัด
            local indX = indicator.AbsolutePosition.X + (indicator.AbsoluteSize.X / 2)
            local barX = meterBar.AbsolutePosition.X + (meterBar.AbsoluteSize.X / 2)
            
            -- หาค่าระยะห่าง
            local diff = math.abs(indX - barX)
            statusLabel.Text = string.format("เข็มห่างจากจุดกลาง: %.1f px", diff)

            -- เมื่อเข็มขยับเข้ามาใกล้จุดกลางสีเขียว
            if diff <= TRIGGER_DISTANCE then
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                
                if not isPressed then
                    isPressed = true
                    statusLabel.Text = "🎯 ยิงคำสั่งกดปุ่ม POUR!"

                    local guiInset = GuiService:GetGuiInset()
                    local clickX = pourBtn.AbsolutePosition.X + (pourBtn.AbsoluteSize.X / 2)
                    local clickY = pourBtn.AbsolutePosition.Y + (pourBtn.AbsoluteSize.Y / 2) + guiInset.Y

                    -- ยิงคำสั่งกดแบบตรงจุด
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

                    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(clickX, clickY, 0), game)
                    task.wait(0.01)
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
