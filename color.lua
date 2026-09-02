-- [[ PERFECT TIMING AUTO POUR SCRIPT ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 🎯 ปรับช่วงมุมองศา (Degrees) ให้แคบลงตรงสีเขียวพอดี
-- ค่าเดิม -15 ถึง 15 กว้างเกินไป ให้ปรับเป็น -3 ถึง 3 (หรือ 0)
local MIN_ANGLE = -4
local MAX_ANGLE = 4

local isAutoActive = true
local isClicked = false

print("✅ Perfect Auto Pour Loaded!")

RunService.RenderStepped:Connect(function()
    if not isAutoActive then return end

    pcall(function()
        local buildUI = playerGui:FindFirstChild("BuildStationUI")
        if not buildUI or not buildUI.Enabled then 
            isClicked = false
            return 
        end

        local pourMeter = buildUI:FindFirstChild("PourMeter")
        if not pourMeter or not pourMeter.Visible then 
            isClicked = false
            return 
        end

        local indicator = pourMeter:FindFirstChild("Indicator")
        local pourBtn = pourMeter:FindFirstChild("PourButton")
        
        if pourBtn and pourBtn:FindFirstChild("ActualButton") then
            pourBtn = pourBtn.ActualButton
        end

        if indicator and pourBtn and indicator.Visible then
            -- อ่านค่า Rotation ของเข็ม
            local currentRotation = indicator.Rotation
            
            -- ปรับแปลงมุมให้อยู่ในช่วง -180 ถึง 180
            if currentRotation > 180 then
                currentRotation = currentRotation - 360
            end

            -- ตรวจสอบว่าเข็มวิ่งเข้าโซนสีเขียวตรงกลางพอดีหรือยัง
            if currentRotation >= MIN_ANGLE and currentRotation <= MAX_ANGLE then
                if not isClicked then
                    isClicked = true -- กันการกดซ้ำหลายรอบในมินิเกมเดียว
                    
                    local guiInset = GuiService:GetGuiInset()
                    local clickX = pourBtn.AbsolutePosition.X + (pourBtn.AbsoluteSize.X / 2)
                    local clickY = pourBtn.AbsolutePosition.Y + (pourBtn.AbsoluteSize.Y / 2) + guiInset.Y

                    -- สั่งกดปุ่ม POUR ทันที
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

                    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(clickX, clickY, 0), game)
                    task.wait(0.01)
                    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(clickX, clickY, 0), game)
                end
            else
                -- ถ้าเข็มไม่อยู่ในจุด ให้รีเซ็ตสถานะเตรียมกดรอบถัดไป
                if math.abs(currentRotation) > 15 then
                    isClicked = false
                end
            end
        end
    end)
end)
