local Workspace = game:GetService("Workspace")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

local SCALE_FACTOR = Vector3.new(3, 3, 3) 
local HITBOX_TRANSPARENCY = 0.5

-- รายชื่อชิ้นส่วนร่างกายของตัวละครมนุษย์ (ทั้ง R6 และ R15)
local HUMAN_PARTS = {
    ["head"] = true, ["torso"] = true, ["humanoidrootpart"] = true,
    ["left arm"] = true, ["right arm"] = true, ["left leg"] = true, ["right leg"] = true,
    ["upperleg"] = true, ["lowerleg"] = true, ["foot"] = true,
    ["upperarm"] = true, ["lowerarm"] = true, ["hand"] = true,
    ["uppertorso"] = true, ["lowertorso"] = true
}

local function expandVehicleBodyOnly(model)
    if not model:IsA("Model") then return end
    task.wait(0.2)

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:GetAttribute("Expanded") then
            local partName = string.lower(part.Name)
            
            -- ตรวจสอบว่าไม่ใช่ชิ้นส่วนร่างกายของ NPC คนขับ
            local isHumanPart = HUMAN_PARTS[partName] or false
            local isInsideCharacter = part:FindFirstAncestorOfClass("Accessory") or part.Parent:FindFirstChildOfClass("Humanoid")
            
            -- ขยายเฉพาะชิ้นส่วนที่เป็นตัวยานพาหนะจริงๆ เท่านั้น
            if not isHumanPart and not isInsideCharacter then
                part:SetAttribute("Expanded", true)
                
                part.Size = part.Size * SCALE_FACTOR
                part.Transparency = HITBOX_TRANSPARENCY
                part.BrickColor = BrickColor.new("Bright blue")
                part.Material = Enum.Material.Neon
                part.CanCollide = false
                part.CanQuery = true

                local mesh = part:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh.Scale = mesh.Scale * SCALE_FACTOR
                end
            end
        end
    end
end

if enemiesFolder then
    print("Strict Vehicle-Part Only Hitbox Loaded!")

    for _, child in ipairs(enemiesFolder:GetChildren()) do
        expandVehicleBodyOnly(child)
    end

    enemiesFolder.ChildAdded:Connect(function(newChild)
        expandVehicleBodyOnly(newChild)
    end)
end
