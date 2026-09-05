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

RunService.RenderStepped:Connect(function()
    -- 1. ล็อคระบบ Stamina การวิ่ง/เดิน
    local values = getValues()
    if values then
        if values:FindFirstChild("StaminaValue") then values.StaminaValue.Value = 100 end
        if values:FindFirstChild("CanSprint") then values.CanSprint.Value = true end
        if values:FindFirstChild("StaminaDrain") then values.StaminaDrain.Value = 0 end
        if values:FindFirstChild("SprintSlowDown") then values.SprintSlowDown.Value = false end
    end

    local character = LocalPlayer.Character
    if character then
        -- 2. ดักจับค่าการโจมตีในตัวละคร (ถ้ามี)
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BoolValue") then
                if child.Name:find("Attack") or child.Name:find("Swing") or child.Name:find("Debounce") then
                    if child.Name == "CanAttack" then
                        child.Value = true
                    elseif child.Name == "Attacking" or child.Name == "Swinging" then
                        child.Value = false
                    end
                end
            end
        end

        -- 3. ดักจับอาวุธที่ถืออยู่ในมือ (Tool)
        local currentTool = character:FindFirstChildOfClass("Tool")
        if currentTool then
            -- ปลดล็อก Debounce / Cooldown ในตัวอาวุธ
            for _, item in ipairs(currentTool:GetDescendants()) do
                if item:IsA("BoolValue") then
                    if item.Name == "CanAttack" or item.Name == "CanSwing" or item.Name == "Ready" then
                        item.Value = true
                    elseif item.Name == "Attacking" or item.Name == "Debounce" or item.Name == "Cooldown" then
                        item.Value = false
                    end
                elseif item:IsA("NumberValue") or item:IsA("IntValue") then
                    -- ถ้าระบบอาวุธใช้ Stamina แยกของตัวเอง ให้เติมให้เต็ม
                    if item.Name:find("Stamina") or item.Name:find("Cost") then
                        if item.Name:find("Cost") then
                            item.Value = 0 -- ปรับค่าใช้ Stamina ของอาวุธเป็น 0
                        end
                    end
                end
            end
        end
    end
end)

print("Infinite Stamina + Fast Continuous Attack Activated!")
