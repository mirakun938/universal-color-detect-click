-- [[ AUTO POUR SCRIPT BASED ON DEX UI STRUCTURE ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- ตั้งค่ามุม (Degrees) ที่ต้องการให้กด
-- แถบสีเขียวจะอยู่ช่วงมุมกลางๆ (ค่าเริ่มต้นลองตั้งไว้ที่ -10 ถึง 20 องศา หรือปรับตามจริงได้)
local MIN_ANGLE = -15
local MAX_ANGLE = 15

local isAutoActive = true

print("✅ Auto Pour Loaded! Waiting for Meter...")

RunService.RenderStepped:Connect(function()
    if not isAutoActive then return end

    pcall(function()
        local buildUI = playerGui:FindFirstChild("BuildStationUI")
        if not buildUI or not buildUI.Enabled then return end

        local pourMeter = buildUI:FindFirstChild("PourMeter")
        if not pourMeter then return end

        local indicator = pourMeter:FindFirstChild("Indicator")
        local pourBtn = pourMeter:FindFirstChild("PourButton")
        
        if pourBtn and pourBtn:FindFirstChild("ActualButton") then
            pourBtn = pourBtn.ActualButton
        end

        if indicator and pourBtn and indicator.Visible then
            -- อ่านค่า Rotation ของเข็ม
            local currentRotation = indicator.Rotation
            
            -- ปรับมุมให้อยู่ในช่วง -180 ถึง 180
            if currentRotation > 180 then
                currentRotation = currentRotation - 360
            end

            -- ถ้าเข็มหมุนเข้าสู่โซนสีเขียว
            if currentRotation >= MIN_ANGLE and currentRotation <= MAX_ANGLE then
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

                task.wait(0.5) -- คูลดาวน์กันกดซ้ำ
            end
        end
    end)
end)
