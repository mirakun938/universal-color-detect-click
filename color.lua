local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("events")
local FishingRF = Events:WaitForChild("FishingMinigameRF")
local ReelUIEvent = Events:WaitForChild("ReellnUI")

-- 1. Hook / Bypass Minigame Remote (ส่งผลลัพธ์ชนะมินิเกมทันที)
local oldInvoke
oldInvoke = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if self == FishingRF and (method == "InvokeServer" or method == "invokeServer") then
        -- บังคับส่งค่าการกดสำเร็จแบบ 100% หรือ Perfect ไปยัง Server
        return true, 100
    end
    
    return oldInvoke(self, ...)
end)

-- 2. Auto Direct Reel (สั่งให้มินิเกมเสร็จสิ้นทันทีที่ UI แสดงขึ้นมา)
ReelUIEvent.OnClientEvent:Connect(function(...)
    task.wait(0.05)
    pcall(function()
        -- ส่งสัญญาณจบมินิเกมไปที่ Server
        FishingRF:InvokeServer(true, 100)
    end)
end)

-- 3. Auto Cast & Auto Reel Loop (ลูปตกปลาอัตโนมัติ)
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character then return end
            
            local Rod = Character:FindFirstChildOfClass("Tool")
            if Rod and Rod:FindFirstChild("events") then
                local RodEvents = Rod.events
                
                -- สั่ง CastRod (เหวี่ยงเบ็ด)
                if RodEvents:FindFirstChild("CastRod") then
                    RodEvents.CastRod:FireServer()
                end
                
                -- สั่ง ReelFish (ดึงสาย)
                if RodEvents:FindFirstChild("ReelFish") then
                    RodEvents.ReelFish:FireServer()
                end
            end
            
            -- สั่ง Auto Shake
            if Events:FindFirstChild("ScreenShake") then
                Events.ScreenShake:FireServer()
            end
        end)
    end
end)
