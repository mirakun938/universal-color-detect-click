local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- เข้าถึงโฟลเดอร์ Values
local function getValues()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui and playerGui:FindFirstChild("MainUI") then
        local bars = playerGui.MainUI:FindFirstChild("Bars")
        if bars then return bars:FindFirstChild("Values") end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    -- 1. บังคับค่าใน Values ไม่ให้ลด และปิดอัตราการเหนื่อย
    local values = getValues()
    if values then
        if values:FindFirstChild("StaminaValue") then values.StaminaValue.Value = 100 end
        if values:FindFirstChild("CanSprint") then values.CanSprint.Value = true end
        if values:FindFirstChild("StaminaDrain") then values.StaminaDrain.Value = 0 end
        if values:FindFirstChild("SprintSlowDown") then values.SprintSlowDown.Value = false end
    end

    -- 2. ดักจับและล็อคความเร็ว WalkSpeed ของตัวละคร ไม่ให้สคริปต์เกมปรับลดตอนเหนื่อย
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        -- หากกำลังกดวิ่ง (Sprinting) ให้ล็อคความเร็วไว้ที่ความเร็ววิ่ง (ปกติประมาณ 24-26)
        if values and values:FindFirstChild("Sprinting") and values.Sprinting.Value == true then
            humanoid.WalkSpeed = 25
        end
    end
end)

print("Advanced Infinite Stamina Activated!")
