-- [[ DIRECT BUTTON ACTIVATION AUTO POUR ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local isFired = false

print("⚡ Direct Button Trigger Loaded!")

RunService.RenderStepped:Connect(function()
    pcall(function()
        local buildUI = playerGui:FindFirstChild("BuildStationUI")
        if not buildUI or not buildUI.Enabled then 
            isFired = false
            return 
        end

        local pourMeter = buildUI:FindFirstChild("PourMeter")
        if not pourMeter or not pourMeter.Visible then 
            isFired = false
            return 
        end

        local indicator = pourMeter:FindFirstChild("Indicator")
        local meterBar = pourMeter:FindFirstChild("MeterBar")
        local pourBtn = pourMeter:FindFirstChild("PourButton")
        
        if pourBtn and pourBtn:FindFirstChild("ActualButton") then
            pourBtn = pourBtn.ActualButton
        end

        if indicator and meterBar and pourBtn then
            -- วัดตำแหน่ง X/Y จริงบนหน้าจอของเข็มเทียบกับจุดกลางแถบสีเขียว
            local indX = indicator.AbsolutePosition.X + (indicator.AbsoluteSize.X / 2)
            local barX = meterBar.AbsolutePosition.X + (meterBar.AbsoluteSize.X / 2)
            
            -- ระยะห่างระหว่างเข็มกับจุดศูนย์กลางสีเขียว (พิกเซล)
            local diff = math.abs(indX - barX)

            -- เมื่อเข็มวิ่งมาใกล้จุดกลางสีเขียว (ระยะห่างน้อยกว่า 15 พิกเซล)
            if diff <= 15 and not isFired then
                isFired = true
                
                -- 1. สั่งกดผ่าน Activated Event ของปุ่มโดยตรง (ไม่โดนบล็อก)
                if firesignal then
                    firesignal(pourBtn.Activated)
                    firesignal(pourBtn.MouseButton1Click)
                else
                    -- 2. สำรอง: กรณี Executor ไม่รองรับ firesignal
                    for _, connection in pairs(getconnections(pourBtn.MouseButton1Click)) do
                        connection:Fire()
                    end
                    for _, connection in pairs(getconnections(pourBtn.Activated)) do
                        connection:Fire()
                    end
                end
            elseif diff > 30 then
                isFired = false
            end
        end
    end)
end)
