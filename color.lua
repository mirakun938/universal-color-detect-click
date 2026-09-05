local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- เข้าถึงโฟลเดอร์ Values ใน MainUI
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

-- ล็อคค่า Stamina ให้เต็มและวิ่งได้ตลอดเวลา
RunService.Heartbeat:Connect(function()
    local values = getStaminaValues()
    if values then
        -- 1. ล็อคค่า StaminaValue ให้เท่ากับ MaxStamina (หรือใส่ 100)
        local staminaValue = values:FindFirstChild("StaminaValue")
        local maxStamina = values:FindFirstChild("MaxStamina")
        if staminaValue then
            staminaValue.Value = maxStamina and maxStamina.Value or 100
        end

        -- 2. ปรับ CanSprint ให้เป็น true
        local canSprint = values:FindFirstChild("CanSprint")
        if canSprint then
            canSprint.Value = true
        end

        -- 3. ปรับอัตราการลด Stamina ให้เป็น 0 (กันสคริปต์เกมหักค่า)
        local staminaDrain = values:FindFirstChild("StaminaDrain")
        if staminaDrain then
            staminaDrain.Value = 0
        end
    end
end)

print("Infinite Stamina (The Rake Remastered) Activated!")
