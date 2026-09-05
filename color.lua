local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getValues()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui and playerGui:FindFirstChild("MainUI") then
        local bars = playerGui.MainUI:FindFirstChild("Bars")
        if bars then return bars:FindFirstChild("Values") end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    local values = getValues()
    if values then
        local staminaValue = values:FindFirstChild("StaminaValue")
        local maxStamina = values:FindFirstChild("MaxStamina")
        
        if staminaValue then
            local max = maxStamina and maxStamina.Value or 100
            
            -- ถ้า Stamina ไม่เต็ม ให้ทำการเติมเพิ่มทีละมากๆ ในทุกๆ เฟรม (จำลองการยืนฟื้นฟูความเร็วสูง)
            if staminaValue.Value < max then
                -- เพิ่มทีละ 10% - 20% ต่อเฟรม เพื่อให้หลอดเด้งเต็มไวแทบทันทีที่กดตี
                staminaValue.Value = math.min(max, staminaValue.Value + 15)
            end
        end

        -- บังคับเปิด CanSprint ให้เป็น true เสมอ เพื่อไม่ให้ติดสถานะเหนื่อยช้าลง
        local canSprint = values:FindFirstChild("CanSprint")
        if canSprint then
            canSprint.Value = true
        end

        -- ปิดการชะลอความเร็ว
        local sprintSlowDown = values:FindFirstChild("SprintSlowDown")
        if sprintSlowDown then
            sprintSlowDown.Value = false
        end
    end
end)

print("Fast Stamina Regen Activated!")
