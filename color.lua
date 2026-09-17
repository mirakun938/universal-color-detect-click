local Workspace = game:GetService("Workspace")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

local SCALE_FACTOR = Vector3.new(3, 3, 3) 
local HITBOX_TRANSPARENCY = 0.5

-- ฟังก์ชันเช็คว่าโมเดลนั้นเป็น NPC คนหรือไม่
local function isHumanNPC(model)
    if not model:IsA("Model") then return false end
    
    -- ถ้ามี Head และ HumanoidRootPart/Torso ชัดเจนแบบโครงสร้างคน ให้ถือว่าเป็น NPC คน
    local hasHead = model:FindFirstChild("Head")
    local hasBody = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    
    -- หากชื่อโมเดลไม่มีคำว่า Vehicle/Jeep/Tank/Plane แต่มีชิ้นส่วนร่างกายครบ = NPC คน
    if hasHead and hasBody then
        return true
    end
    
    return false
end

local function expandVehicleOnly(model)
    if not model:IsA("Model") then return end
    task.wait(0.15)

    -- ข้ามการขยาย Hitbox ถ้าเป็น NPC คน
    if isHumanNPC(model) then return end

    -- ขยายเฉพาะชิ้นส่วนยานพาหนะ
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not part:GetAttribute("Expanded") then
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

if enemiesFolder then
    print("Vehicle-Only Hitbox Loaded!")

    for _, child in ipairs(enemiesFolder:GetChildren()) do
        expandVehicleOnly(child)
    end

    enemiesFolder.ChildAdded:Connect(function(newChild)
        expandVehicleOnly(newChild)
    end)
end
