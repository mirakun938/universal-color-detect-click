local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันรันการเติมกระสุนผ่าน Remote ของปืน
local function forceRefillGun(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- เช็คว่าเป็นปืน Borrowed Technology หรือไม่
    if tool.Name == "Borrowed Technology" or string.find(string.lower(tool.Name), "borrowed") then
        local gunServer = tool:FindFirstChild("GunServer")
        if gunServer then
            local reloadFolder = gunServer:FindFirstChild("Reload")
            if reloadFolder then
                -- 1. เรียกใช้ RemoteFunction "Refill"
                local refillRemote = reloadFolder:FindFirstChild("Refill")
                if refillRemote and refillRemote:IsA("RemoteFunction") then
                    task.spawn(function()
                        pcall(function()
                            refillRemote:InvokeServer()
                        end)
                    end)
                end
                
                -- 2. ยิง RemoteEvent "ForceRefill" (ถ้ามี)
                local forceRefillRemote = reloadFolder:FindFirstChild("ForceRefill")
                if forceRefillRemote and forceRefillRemote:IsA("RemoteEvent") then
                    pcall(function()
                        forceRefillRemote:FireServer()
                    end)
                end
            end
        end
    end
end

-- สแกนเติมกระสุนรัวๆ ทุกๆ 0.1 วินาที
task.spawn(function()
    while task.wait(0.1) do
        -- สแกนปืนที่ถือในมือ (Character)
        local char = LocalPlayer.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then
                    forceRefillGun(item)
                end
            end
        end
        
        -- สแกนปืนในกระเป๋า (Backpack)
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then
                    forceRefillGun(item)
                end
            end
        end
    end
end)

print("Borrowed Technology Auto-Refill Loaded!")
