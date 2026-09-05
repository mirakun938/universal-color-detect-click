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
        -- 1. รีเซ็ต Stamina ให้เต็ม 100 ตลอดเวลา
        if values:FindFirstChild("StaminaValue") then values.StaminaValue.Value = 100 end
        if values:FindFirstChild("MaxStamina") then values.StaminaValue.Value = values.MaxStamina.Value end
        
        -- 2. อนุญาตให้กดวิ่งได้ตลอดเวลา
        if values:FindFirstChild("CanSprint") then values.CanSprint.Value = true end
        if values:FindFirstChild("StaminaDrain") then values.StaminaDrain.Value = 0 end
        if values:FindFirstChild("SprintSlowDown") then values.SprintSlowDown.Value = false end

        -- 3. แก้ปัญหาตัวละครหลุดวิ่ง (Reset Timer / Override Speed)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            local humanoid = character.Humanoid
            
            -- ถ้ากำลังกดวิ่งอยู่ แต่สคริปต์เกมสั่งหยุดวิ่งเอง ให้รีเซ็ตค่าเพื่อกดวิ่งต่อได้ทันที
            if values:FindFirstChild("IsSprinting") then
                -- เช็กว่าถ้าความเร็วตกขณะที่ยังกดวิ่ง ให้เปิด CanSprint ซ้ำเพื่อ Bypass ตัวนับเวลา
                if humanoid.MoveDirection.Magnitude > 0 and values.CanSprint.Value == false then
                    values.CanSprint.Value = true
                end
            end
            
            -- ล็อค WalkSpeed ไม่ให้ลดเป็นความเร็วเดินปกติขณะกดวิ่ง
            if values:FindFirstChild("Sprinting") and values.Sprinting.Value == true then
                humanoid.WalkSpeed = 25
            end
        end
    end
end)

print("Infinite Sprint (Fix Auto-Stop) Activated!")
