local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- อ้างอิง Remote จาก ReplicatedStorage โดยตรงตาม RemoteSpy
local CastRod = ReplicatedStorage:WaitForChild("CastRod")
local ReelFish = ReplicatedStorage:WaitForChild("ReelFish")
local FishingRF = ReplicatedStorage:WaitForChild("FishingMinigameRF")

-- 1. ดักจับและทำ Auto-Win Minigame ทันทีที่ Server ส่งสัญญาณมินิเกมมา
FishingRF.OnClientInvoke = function(data)
    -- เมื่อ Server เรียกมินิเกม สคริปต์จะตอบกลับค่า true เพื่อข้ามการกด Left/Right/Shake และชนะทันที
    return true
end

-- 2. ลูปทำงาน Auto Cast & Reel In อัตโนมัติ
task.spawn(function()
    while task.wait(1.5) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            
            -- ตรวจสอบว่าถือเบ็ดอยู่หรือไม่
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool then
                local hrp = Character.HumanoidRootPart
                -- คำนวณพิกัดด้านหน้าตัวละครลงน้ำ (Vector3)
                local targetPos = hrp.Position + (hrp.CFrame.LookVector * 15) - Vector3.new(0, 5, 0)
                
                -- ขั้นตอนที่ 1: เหวี่ยงเบ็ดลงน้ำ
                CastRod:FireServer(targetPos)
                
                task.wait(1)
                
                -- ขั้นตอนที่ 2: กด Reel In (ดึงสายเมื่อปลาติดเบ็ด)
                ReelFish:FireServer()
            end
        end)
    end
end)
