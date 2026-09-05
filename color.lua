local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local currentConnection = nil

-- ฟังก์ชันผูกสคริปต์กับ StaminaValue ชิ้นใหม่
local function setupRegen()
    if currentConnection then
        currentConnection:Disconnect()
        currentConnection = nil
    end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    
    local mainUI = playerGui:WaitForChild("MainUI", 10)
    if not mainUI then return end
    
    local bars = mainUI:WaitForChild("Bars", 10)
    if not bars then return end
    
    local values = bars:WaitForChild("Values", 10)
    if not values then return end

    local staminaValue = values:WaitForChild("StaminaValue", 10)
    local maxStamina = values:FindFirstChild("MaxStamina")

    if staminaValue then
        local isUpdating = false
        local lastValue = staminaValue.Value

        currentConnection = staminaValue.Changed:Connect(function(newVal)
            if isUpdating then return end
            
            local max = maxStamina and maxStamina.Value or 100
            
            -- จังหวะกดตี/ถูกหัก Stamina: ปล่อยให้ลดได้ตามปกติ
            if newVal < lastValue and (max - newVal) > 5 then
                lastValue = newVal
            elseif newVal > lastValue then
                -- จังหวะฟื้นฟู: บังคับเพิ่มขึ้น +2% ทันที ไม่ให้เด้งย้อนกลับ
                isUpdating = true
                local targetValue = math.min(max, lastValue + 2)
                staminaValue.Value = targetValue
                lastValue = targetValue
                isUpdating = false
            end
        end)
    end
end

-- 1. ทำงานครั้งแรกทันทีที่รันสคริปต์
task.spawn(setupRegen)

-- 2. ดักจับเมื่อตัวละครเกิดใหม่ (Respawn/Death) ให้ผูกสคริปต์ใหม่ทันที
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- รอ UI โหลดขึ้นมาสมบูรณ์หลังตาย
    setupRegen()
end)

-- 3. ล็อคเงื่อนไข CanSprint / SprintSlowDown ไว้ตลอดเวลา
RunService.RenderStepped:Connect(function()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui and playerGui:FindFirstChild("MainUI") then
        local bars = playerGui.MainUI:FindFirstChild("Bars")
        if bars and bars:FindFirstChild("Values") then
            local val = bars.Values
            if val:FindFirstChild("CanSprint") then val.CanSprint.Value = true end
            if val:FindFirstChild("SprintSlowDown") then val.SprintSlowDown.Value = false end
        end
    end
end)

print("Respawn-Proof 2% Stamina Regen Activated!")
