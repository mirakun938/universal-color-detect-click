local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. Hook Index/NewIndex เพื่อป้องกันไม่ให้อาวุธลด Stamina หรือเช็กค่า Stamina
local gmt = getrawmetatable(game)
local oldIndex = gmt.__index
local oldNewIndex = gmt.__newindex
setreadonly(gmt, false)

gmt.__index = newcclosure(function(self, key)
    if not checkcaller() and typeof(self) == "Instance" then
        if self.Name == "StaminaNeed" or self.Name == "StaminaUsed" then
            return 0
        end
    end
    return oldIndex(self, key)
end)

gmt.__newindex = newcclosure(function(self, key, value)
    if not checkcaller() and typeof(self) == "Instance" then
        if self.Name == "StaminaNeed" or self.Name == "StaminaUsed" then
            return oldNewIndex(self, key, 0)
        end
    end
    return oldNewIndex(self, key, value)
end)

setreadonly(gmt, true)

-- 2. วนลูปบังคับค่า Stamina ในอาวุธและตัวละครให้เป็น 0 ตลอดเวลา
RunService.Stepped:Connect(function()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local function processTool(tool)
        if tool:IsA("Tool") then
            local sn = tool:FindFirstChild("StaminaNeed")
            local su = tool:FindFirstChild("StaminaUsed")
            local ca = tool:FindFirstChild("CanAttack")
            
            if sn then rawset(sn, "Value", 0) sn.Value = 0 end
            if su then rawset(su, "Value", 0) su.Value = 0 end
            if ca then ca.Value = true end
        end
    end

    if character then
        for _, v in ipairs(character:GetChildren()) do processTool(v) end
    end
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do processTool(v) end
    end
end)

print("Absolute Weapon Stamina Bypass Activated!")
