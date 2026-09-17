local Workspace = game:GetService("Workspace")
local aiFolder = Workspace:WaitForChild("ai", 10)

local HEAD_SIZE = Vector3.new(15, 15, 15) -- ขนาดความกว้าง x ยาว x สูง
local HEAD_TRANSPARENCY = 0.6            -- ความโปร่งใส (0 = ทึบ, 1 = ล่องหน)

-- ฟังก์ชันสำหรับซ่อน/คืนค่า Hitbox เมื่อ Zombie ตาย
local function clearHeadHitbox(head)
    pcall(function()
        head.Size = Vector3.new(1.2, 1.2, 1.2)
        head.Transparency = 1
        head.CanCollide = false
    end)
end

local function applyHitboxToHead(head)
    if not head:IsA("BasePart") then return end
    
    -- ขยายขนาดส่วนหัว
    head.Size = HEAD_SIZE
    head.Transparency = HEAD_TRANSPARENCY
    head.BrickColor = BrickColor.new("Really red")
    head.Material = Enum.Material.Neon
    head.CanCollide = false

    -- ตรวจหา Humanoid ในโมเดลเพื่อดักจับการตาย
    local model = head:FindFirstAncestorOfClass("Model")
    if model then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        
        if humanoid then
            -- หากเลือดหมดแล้ว ให้ซ่อน Hitbox ทันที
            if humanoid.Health <= 0 then
                clearHeadHitbox(head)
                return
            end
            
            -- ดักจับจังหวะที่เลือดลดจนเหลือ 0 (ตาย)
            local healthConn
            healthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health <= 0 then
                    clearHeadHitbox(head)
                    if healthConn then healthConn:Disconnect() end
                end
            end)
        end
        
        -- ดักจับกรณีที่โมเดล Zombie ถูกลบออกจาก Workspace (Destroy)
        local removeConn
        removeConn = model.AncestryChanged:Connect(function(_, parent)
            if not parent then
                clearHeadHitbox(head)
                if removeConn then removeConn:Disconnect() end
            end
        end)
    end
end

-- สแกนชิ้นส่วนในโฟลเดอร์ ai
local function processDescendant(descendant)
    if descendant:IsA("BasePart") and string.find(string.lower(descendant.Name), "head") then
        applyHitboxToHead(descendant)
    end
end

if aiFolder then
    print("Auto-Clean Dynamic Head Hitbox Loaded!")

    -- 1. สแกน AI ทุกตัวที่มีอยู่ในโฟลเดอร์ ai ปัจจุบัน
    for _, desc in ipairs(aiFolder:GetDescendants()) do
        processDescendant(desc)
    end

    -- 2. ดักจับ AI ตัวใหม่ที่เพิ่งเกิด (Spawn)
    aiFolder.DescendantAdded:Connect(function(desc)
        task.wait(0.05)
        processDescendant(desc)
    end)
end
