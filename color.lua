local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. ล็อคค่า Stamina ใน Data (Players.LocalPlayer.Stamina)
RunService.Heartbeat:Connect(function()
    -- ปรับค่า Stamina ใน Data ของตัวละคร
    local playerDataStamina = LocalPlayer:FindFirstChild("Stamina")
    if playerDataStamina and playerDataStamina:IsA("ValueBase") then
        playerDataStamina.Value = 100
    end
    
    -- 2. ปรับสถานะ CanSprint ใน PlayerGui ให้วิ่งได้ตลอดเวลา
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local staminaFolder = playerGui:FindFirstChild("PlayerBar") and playerGui.PlayerBar:FindFirstChild("Stamina")
        if staminaFolder then
            local canSprint = staminaFolder:FindFirstChild("CanSprint")
            if canSprint and canSprint:IsA("BoolValue") then
                canSprint.Value = true
            end
            
            local isSprinting = staminaFolder:FindFirstChild("IsSprinting")
            -- ป้องกันไม่ให้ UseStamina มาปิดการวิ่ง
            local useStamina = staminaFolder:FindFirstChild("UseStamina")
            if useStamina and useStamina:IsA("BoolValue") then
                useStamina.Value = false
            end
        end
    end
end)

print("Infinite Stamina Activated for this Game!")
