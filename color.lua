local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getStaminaValues()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local mainUI = playerGui:FindFirstChild("MainUI")
        if mainUI then
            local bars = mainUI:FindFirstChild("Bars")
            if bars then
                return bars:FindFirstChild("Values")
            end
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    local values = getStaminaValues()
    if values then
        -- 1. ล็อค Stamina ให้เต็มตลอดเวลา
        local maxStamina = values:FindFirstChild("MaxStamina")
        local staminaValue = values:FindFirstChild("StaminaValue")
        local maxVal = (maxStamina and maxStamina.Value > 0) and maxStamina.Value or 100
        
        if staminaValue then
            staminaValue.Value = maxVal
        end

        -- 2. อนุญาตให้กดวิ่งได้ตลอด
        local canSprint = values:FindFirstChild("CanSprint")
        if canSprint and canSprint:IsA("BoolValue") then
            canSprint.Value = true
        end

        -- 3. ปรับอัตราการหัก Stamina ให้เป็น 0
        local staminaDrain = values:FindFirstChild("StaminaDrain")
        if staminaDrain then
            staminaDrain.Value = 0
        end

        -- 4. ลบ/ปิด คูลดาวน์การลด Stamina
        local drainCooldown = values:FindFirstChild("DrainCooldown")
        if drainCooldown then
            drainCooldown.Value = 0
        end

        -- 5. ปิดสถานะ SlowDown (อาการเหนื่อย/เดินช้า)
        local sprintSlowDown = values:FindFirstChild("SprintSlowDown")
        if sprintSlowDown then
            if sprintSlowDown:IsA("BoolValue") then
                sprintSlowDown.Value = false
            elseif sprintSlowDown:IsA("NumberValue") then
                sprintSlowDown.Value = 0
            end
        end
        
        -- 6. ป้องกันไม่ให้ขึ้นสถานะ Using ค้าง
        local usingVal = values:FindFirstChild("Using")
        if usingVal and usingVal:IsA("BoolValue") and not values:FindFirstChild("Sprinting").Value then
            usingVal.Value = false
        end
    end
end)

print("Full Infinite Stamina & Anti-Tired Activated!")
