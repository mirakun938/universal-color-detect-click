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
    local values = getValues()
    if values then
        -- 1. หลอกสถานะว่าไม่ได้กำลังวิ่งหรือเคลื่อนไหว (เพื่อให้เกมใช้ Regen Rate ตอนยืนนิ่ง)
        local isSprinting = values:FindFirstChild("IsSprinting") or values:FindFirstChild("Sprinting")
        if isSprinting and isSprinting:IsA("ValueBase") then
            isSprinting.Value = false
        end

        local isMoving = values:FindFirstChild("IsMoving") or values:FindFirstChild("Moving")
        if isMoving and isMoving:IsA("ValueBase") then
            isMoving.Value = false
        end

        -- 2. อนุญาตให้รีเจ็น Stamina ได้ตลอดเวลา
        local canRegen = values:FindFirstChild("CanRegen") or values:FindFirstChild("RegenStamina")
        if canRegen and canRegen:IsA("ValueBase") then
            canRegen.Value = true
        end

        -- 3. ปล่อยให้ Stamina ลดได้ตามปกติเมื่อกดตี แต่บังคับไม่ให้ติดสถานะเหนื่อย (SprintSlowDown)
        local sprintSlowDown = values:FindFirstChild("SprintSlowDown")
        if sprintSlowDown and sprintSlowDown:IsA("ValueBase") then
            sprintSlowDown.Value = false
        end
        
        local canSprint = values:FindFirstChild("CanSprint")
        if canSprint and canSprint:IsA("ValueBase") then
            canSprint.Value = true
        end
    end
end)

print("Fake Standing State (Fast Stamina Regen) Activated!")
