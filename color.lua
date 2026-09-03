local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันค้นหา Remote แบบเดียวกับที่ RemoteSpy ในคลิปวิดีโอของคุณใช้
local function GetEvent(name)
    for _, obj in pairs(game:GetDescendants()) do
        if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            return obj
        end
    end
    -- กรณี Remote ถูกซ่อนใน Nil
    if getnilinstances then
        for _, obj in pairs(getnilinstances()) do
            if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
    end
    return nil
end

-- ดึง Remote ผ่านฟังก์ชันค้นหา
local CastRod = GetEvent("CastRod")
local ReelFish = GetEvent("ReelFish")
local FishingRF = GetEvent("FishingMinigameRF")

-- 1. Bypass มินิเกมเมื่อ Server เรียกใช้งาน
if FishingRF then
    FishingRF.OnClientInvoke = function(...)
        return true
    end
end

-- 2. ลูปเหวี่ยงเบ็ดและดึงสายอัตโนมัติ
task.spawn(function()
    while task.wait(1.2) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            
            -- ตรวจสอบว่าถือเบ็ดอยู่หรือไม่
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool and CastRod and ReelFish then
                local hrp = Character.HumanoidRootPart
                -- คำนวณพิกัดด้านหน้าตัวละครลงน้ำ (Vector3)
                local targetPos = hrp.Position + (hrp.CFrame.LookVector * 15) - Vector3.new(0, 5, 0)
                
                -- เหวี่ยงเบ็ดพร้อมส่ง Vector3
                CastRod:FireServer(targetPos)
                
                task.wait(0.5)
                
                -- ดึงสาย
                ReelFish:FireServer()
            end
        end)
    end
end)
