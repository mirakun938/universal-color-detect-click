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

-- ปรับแต่งค่าเมื่อถืออาวุธที่ซื้อมา
local function setupTool(tool)
    if not tool:IsA("Tool") then return end
    
    -- ค้นหาและปลดล็อก Cooldown ภายในตัวอาวุธ
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("cooldown") or v.Name:lower():find("delay") or v.Name:lower():find("stamina") then
                v.Value = 0
            end
        elseif v:IsA("BoolValue") then
            if v.Name:lower():find("canattack") or v.Name:lower():find("ready") then
                v.Value = true
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    -- 1. ล็อคระบบ Stamina ไม่ให้ลด
    local values = getValues()
    if values then
        if values:FindFirstChild("StaminaValue") then values.StaminaValue.Value = 100 end
        if values:FindFirstChild("CanSprint") then values.CanSprint.Value = true end
        if values:FindFirstChild("StaminaDrain") then values.StaminaDrain.Value = 0 end
        if values:FindFirstChild("SprintSlowDown") then values.SprintSlowDown.Value = false end
    end

    -- 2. ปรับค่า Swing Speed ให้อยู่ในเกณฑ์ที่ตีนุ่มนวล ไม่โดน Server ปฏิเสธ
    local swingSpeed = LocalPlayer:FindFirstChild("SwingSpeedMultiply")
    if swingSpeed then swingSpeed.Value = 1.25 end

    local ogSwingSpeed = LocalPlayer:FindFirstChild("OGSwingSpeedMultiply")
    if ogSwingSpeed then ogSwingSpeed.Value = 1.25 end

    -- 3. ตรวจจับอาวุธในมือและใน Backpack
    local character = LocalPlayer.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            setupTool(child)
        end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            setupTool(child)
        end
    end
end)

print("Shop Weapon Continuous Attack Script Activated!")
