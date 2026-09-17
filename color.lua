local Workspace = game:GetService("Workspace")
local enemiesFolder = Workspace:WaitForChild("Enemies", 10)

-- การตั้งค่า Hitbox ยานพาหนะ
local VEHICLE_HITBOX_SIZE = Vector3.new(30, 30, 30) -- ขนาดความกว้าง x ยาว x สูง (ปรับได้)
local HITBOX_TRANSPARENCY = 0.6                     -- ความโปร่งใส (0 = ทึบ, 1 = ล่องหน)

local function expandVehicleHitbox(model)
    if not model:IsA("Model") then return end
    
    task.wait(0.1) -- รอให้ Part ภายในยานพาหนะโหลดสมบูรณ์

    -- 1. หา ชิ้นส่วนหลัก (PrimaryPart / Hitbox Part)
    local targetPart = model.PrimaryPart 
        or model:FindFirstChild("HumanoidRootPart") 
        or model:FindFirstChildOfClass("VehicleSeat") 
        or model:FindFirstChildOfClass("Seat")
    
    -- 2. ถ้าไม่เจอ Part หลัก ให้ดึง BasePart ชิ้นแรกในโมเดลมาใช้แทน
    if not targetPart then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                targetPart = desc
                break
            end
        end
    end

    -- 3. ทำการขยาย Hitbox
    if targetPart and targetPart:IsA("BasePart") then
        targetPart.Size = VEHICLE_HITBOX_SIZE
        targetPart.Transparency = HITBOX_TRANSPARENCY
        targetPart.BrickColor = BrickColor.new("Bright blue") -- สีฟ้าเนออน
        targetPart.Material = Enum.Material.Neon
        targetPart.CanCollide = false
        targetPart.CanQuery = true

        -- ดักจับเมื่อ Humanoid ของยานพาหนะตาย (ถ้ามี)
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local diedConn
            diedConn = humanoid.Died:Connect(function()
                targetPart.Size = Vector3.new(1, 1, 1)
                targetPart.Transparency = 1
                if diedConn then diedConn:Disconnect() end
            end)
        end
    end
end

if enemiesFolder then
    print("Enemies Vehicle Hitbox Expander Loaded!")

    -- 1. สแกนยานพาหนะ/ศัตรูที่มีอยู่ในโฟลเดอร์ Enemies ณ ปัจจุบัน
    for _, child in ipairs(enemiesFolder:GetChildren()) do
        expandVehicleHitbox(child)
    end

    -- 2. ดักจับเมื่อมียานพาหนะใหม่เกิดเข้ามาในโฟลเดอร์ Enemies
    enemiesFolder.ChildAdded:Connect(function(newVehicle)
        expandVehicleHitbox(newVehicle)
    end)
else
    warn("ไม่พบโฟลเดอร์ 'Enemies' ใน Workspace")
end
