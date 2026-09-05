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
    local maxStamina = values:FindFirstChild("MaxStamina")
    
    if staminaValue then
        local isUpdating = false -- กัน Infinite Loop การจับสัญญาณ
        local lastValue = staminaValue.Value

        staminaValue.Changed:Connect(function(newVal)
            if isUpdating then return end
            
            local max = maxStamina and maxStamina.Value or 100
            
            -- ถ้าเกมพยายามดึงค่า Stamina ลดลง ทั้งๆ ที่ควรเป็นการฟื้นฟู ให้ล็อคไม่ให้ย้อนกลับ
            if newVal < lastValue and (max - newVal) > 5 then
                -- จังหวะนี้ปล่อยให้อาวุธหักค่า Stamina ได้ตามปกติ
                lastValue = newVal
            elseif newVal > lastValue then
                -- จังหวะฟื้นฟู: บังคับเพิ่มเป็น +2% ทันที และป้องกันไม่ให้เด้งกลับ
                isUpdating = true
                local targetValue = math.min(max, lastValue + 2)
                staminaValue.Value = targetValue
                lastValue = targetValue
                isUpdating = false
            end
        end)
    end
end

-- ปิดสถานะเหนื่อย/ชะลอความเร็ว
RunService.RenderStepped:Connect(function()
    local val = getValues()
    if val then
        if val:FindFirstChild("CanSprint") then val.CanSprint.Value = true end
        if val:FindFirstChild("SprintSlowDown") then val.SprintSlowDown.Value = false end
    end
end)

print("Smooth 2% Regen (Anti-Revert) Activated!")
