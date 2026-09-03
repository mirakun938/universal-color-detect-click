local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- อ้างอิง Remote จาก ReplicatedStorage โดยตรงตามใน RemoteSpy
local CastRod = ReplicatedStorage:WaitForChild("CastRod")
local ReelFish = ReplicatedStorage:WaitForChild("ReelFish")
local FishingRF = ReplicatedStorage:WaitForChild("FishingMinigameRF")

-- 1. Hook / Direct Return สำหรับ Bypass มินิเกม
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if self == FishingRF and (method == "InvokeServer" or method == "invokeServer") then
        return true
    end
    
    return oldNamecall(self, ...)
end)

-- 2. ลูปทำงาน Auto Cast & Reel
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            
            -- ตรวจสอบว่าถือเบ็ดอยู่หรือไม่
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool then
                -- คำนวณพิกัดด้านหน้าตัวละครสำหรับการเหวี่ยงเบ็ด (Vector3)
                local hrp = Character.HumanoidRootPart
                local targetPos = hrp.Position + (hrp.CFrame.LookVector * 20)
                
                -- สั่งเหวี่ยงเบ็ดตามโครงสร้าง Vector3 ใน RemoteSpy
                CastRod:FireServer(targetPos)
                
                task.wait(0.3)
                
                -- สั่งดึงสาย
                ReelFish:FireServer()
            end
        end)
    end
end)
