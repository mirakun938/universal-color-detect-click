local Workspace = game:GetService("Workspace")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

local SCALE_FACTOR = Vector3.new(3, 3, 3) 
local HITBOX_TRANSPARENCY = 0.5

-- ฟังก์ชันตรวจสอบว่าเป็นยานพาหนะจริงๆ (ไม่ใช่ NPC คน)
local function isActualVehicle(model)
    if not model:IsA("Model") then return false end
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local hasVehicleSeat = model:FindFirstChildOfClass("VehicleSeat") or model:FindFirstChildOfClass("Seat")
    local modelName = string.lower(model.Name)
    
    -- 1. ถ้ามี VehicleSeat หรือ ชื่อโมเดลระบุว่าเป็นยานพาหนะ = ใช่ยานพาหนะแน่นอน
    if hasVehicleSeat or string.find(modelName, "jeep") or string.find(modelName, "plane") or string.find(modelName, "tank") or string.find(modelName, "vehicle") or string.find(modelName, "car") then
        return true
    end
    
    -- 2. ถ้ามี Humanoid แบบ NPC คนปกติ (เดินได้ มีอนิเมชัน) = ไม่ใช่ยานพาหนะ (เป็นคน)
    if humanoid and not hasVehicleSeat then
        return false
    end
    
    -- 3. ถ้าไม่มี Humanoid เลย แต่มียานพาหนะประกอบอยู่ = ยานพาหนะ
    if not humanoid then
        return true
    end

    return false
end

local function expandVehicleOnly(model)
    if not model:IsA("Model") then return end
    task.wait(0.2) -- รอโครงสร้างโมเดลโหลดเสร็จ

    -- ตรวจสอบ: ถ้าเป็น NPC คน ให้ยกเลิกการขยายทันที
    if not isActualVehicle(model) then return end

    -- ขยายเฉพาะชิ้นส่วนของยานพาหนะ
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
    print("Strict Vehicle-Only Hitbox Loaded!")

    for _, child in ipairs(enemiesFolder:GetChildren()) do
        expandVehicleOnly(child)
    end

    enemiesFolder.ChildAdded:Connect(function(newChild)
        expandVehicleOnly(newChild)
    end)
end
