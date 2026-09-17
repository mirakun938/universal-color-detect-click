local Workspace = game:GetService("Workspace")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

-- ขนาดตัวคูณของยานพาหนะ ( multiplier เช่น 2.5x หรือ 3x ของขนาดเดิม )
local SCALE_FACTOR = Vector3.new(3, 3, 3) 
local HITBOX_TRANSPARENCY = 0.5 -- ความโปร่งใส (0 = ทึบ, 1 = ล่องหน)

local function expandVehicleParts(model)
    if not model:IsA("Model") then return end
    
    task.wait(0.15) -- รอให้ Part ภายในยานพาหนะสร้างครบถ้วน

    -- วนลูปขยายทุกชิ้นส่วนที่เป็น Part ในยานพาหนะโดยตรง
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:GetAttribute("Expanded") then
            part:SetAttribute("Expanded", true)
            
            -- ขยายขนาดของ Part เดิม
            part.Size = part.Size * SCALE_FACTOR
            part.Transparency = HITBOX_TRANSPARENCY
            part.BrickColor = BrickColor.new("Bright blue")
            part.Material = Enum.Material.Neon
            part.CanCollide = false
            part.CanQuery = true -- อนุญาตให้ Raycast ของปืนตรวจจับเพื่อคำนวณ Damage

            -- หากมี Mesh ข้างใน ให้ขยาย Mesh ตามด้วย
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                mesh.Scale = mesh.Scale * SCALE_FACTOR
            end
        end
    end
end

if enemiesFolder then
    print("Damage-Registering Vehicle Hitbox Loaded!")

    -- 1. สแกนยานพาหนะที่มีอยู่ตอนนี้
    for _, vehicle in ipairs(enemiesFolder:GetChildren()) do
        expandVehicleParts(vehicle)
    end

    -- 2. ดักจับเมื่อมียานพาหนะเกิดใหม่ใน Enemies
    enemiesFolder.ChildAdded:Connect(function(newVehicle)
        expandVehicleParts(newVehicle)
    end)
else
    warn("ไม่พบโฟลเดอร์ 'Enemies' ใน Workspace")
end
