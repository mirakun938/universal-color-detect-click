local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันปรับค่า Stamina ของอาวุธเป็น 0
local function fixToolStamina(tool)
    if tool and tool:IsA("Tool") then
        local staminaNeed = tool:FindFirstChild("StaminaNeed")
        if staminaNeed and staminaNeed:IsA("ValueBase") then
            staminaNeed.Value = 0
        end

        local staminaUsed = tool:FindFirstChild("StaminaUsed")
        if staminaUsed and staminaUsed:IsA("ValueBase") then
            staminaUsed.Value = 0
        end

        local canAttack = tool:FindFirstChild("CanAttack")
        if canAttack and canAttack:IsA("BoolValue") then
            canAttack.Value = true
        end
    end
end

RunService.RenderStepped:Connect(function()
    -- 1. เช็กและปรับอาวุธทุกชิ้นใน Backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            fixToolStamina(tool)
        end
    end

    -- 2. เช็กและปรับอาวุธที่ถืออยู่ในมือ (Character)
    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            fixToolStamina(tool)
        end
    end
end)

print("Infinite Weapon Stamina (All Weapons) Activated!")
