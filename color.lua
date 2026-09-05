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

local values = getValues()
if values then
    local staminaValue = values:FindFirstChild("StaminaValue")
    if staminaValue then
        local lastStamina = staminaValue.Value

        -- ดักจับจังหวะที่เกมทำการเพิ่ม/รีเจ็น Stamina ให้ตัวละคร
        staminaValue.Changed:Connect(function(newVal)
            -- ถ้าค่า Stamina กำลังเพิ่มขึ้น (แสดงว่าอยู่ในโหมด Regen)
            if newVal > lastStamina then
                local maxStamina = values:FindFirstChild("MaxStamina")
                local max = maxStamina and maxStamina.Value or 100
                
                -- เร่งอัตราการเพิ่มขึ้นให้อีกเท่าตัว (แปลงการเพิ่ม 1% ให้เป็น 2% หรือมากกว่าทันที)
                local diff = newVal - lastStamina
                local boostedVal = math.min(max, newVal + (diff * 2))
                
                -- อัปเดตค่า Stamina ทันที
                staminaValue.Value = boostedVal
            end
            lastStamina = staminaValue.Value
        end)
    end
end

-- ล็อคเงื่อนไขย่อยเพื่อไม่ให้ติด Cooldown ชะลอความเร็ว
RunService.RenderStepped:Connect(function()
    local val = getValues()
    if val then
        if val:FindFirstChild("CanSprint") then val.CanSprint.Value = true end
        if val:FindFirstChild("SprintSlowDown") then val.SprintSlowDown.Value = false end
    end
end)

print("Regen Multiplier Activated!")
