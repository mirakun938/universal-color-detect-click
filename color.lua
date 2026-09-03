local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("events")
local CastRod = Events:WaitForChild("CastRod")
local ReelFish = Events:WaitForChild("ReelFish")
local FishingMinigameRF = Events:WaitForChild("FishingMinigameRF")

-- 1. Auto Win Minigame (Hook Callback เมื่อมินิเกมเริ่ม)
if FishingMinigameRF then
    FishingMinigameRF.OnClientInvoke = function(...)
        -- ตอบกลับ Server ทันทีว่ามินิเกมผ่าน (Return true)
        return true
    end
end

-- 2. ลูป Auto Cast & Reel (เหวี่ยงเบ็ดและดึงสายอัตโนมัติ)
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            
            -- ตรวจสอบว่าถือเบ็ดอยู่หรือไม่
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool then
                -- คำนวณพิกัดด้านหน้าตัวละครสำหรับการเหวี่ยงเบ็ด (Vector3)
                local TargetPosition = Character.HumanoidRootPart.Position + (Character.HumanoidRootPart.CFrame.LookVector * 15)
                
                -- สั่ง CastRod พร้อมพิกัด Vector3 (ตรงตาม RemoteSpy)
                CastRod:FireServer(TargetPosition)
                
                task.wait(0.2)
                
                -- สั่ง ReelFish (ดึงสาย)
                ReelFish:FireServer()
            end
        end)
    end
end)
