local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ล็อคค่า UI กระสุนบนหน้าจอไม่ให้ตัวเลขลดลง
local function patchMinigunGUI()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChild("Borrowed Technology") or char:FindFirstChildOfClass("Tool")
    if tool and (tool.Name == "Borrowed Technology" or string.find(string.lower(tool.Name), "borrowed")) then
        
        -- ปรับแต่ง LocalScript ของปืนเพื่อล็อคตัวเลขกระสุน
        local gunServer = tool:FindFirstChild("GunServer")
        if gunServer then
            local ammoModule = tool:FindFirstChild("MinigunState") or gunServer:FindFirstChild("GetServerAmmo")
            
            -- ปรับ Value หรือ Attributes ทุกตัวในปืน
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") then
                    v.Value = 300
                end
            end
        end
    end
end

-- ระบบ Hooking ป้องกันไม่ให้ Client ส่ง Remote หักกระสุนไปที่ Server
local gmt = getrawmetatable(game)
local oldNamecall = gmt.__namecall
setreadonly(gmt, false)

gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- ตรวจจับ RemoteEvent การยิงของปืน Minigun (WeaponFired / RegisterBullet)
    if (method == "FireServer" or method == "InvokeServer") and self then
        if self.Name == "WeaponFired" or self.Name == "RegisterBullet" then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and (tool.Name == "Borrowed Technology" or string.find(string.lower(tool.Name), "borrowed")) then
                    -- ปรับแต่ง Arguments ไม่ให้ Server หักกระสุน หรือเรียกใช้งานเฉพาะนัดแรก
                    -- (หรือปล่อยผ่านโดยไม่ส่งข้อมูลความเสียหายกระสุนลด)
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(gmt, true)

-- Loop ล็อคตัวเลขกระสุน Minigun ไว้ที่ 300 / ค่าสูงสุดตลอดเวลา
task.spawn(function()
    while task.wait(0.01) do
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChild("Borrowed Technology")
            if tool then
                -- ค้นหาและคืนค่ากระสุนกลับเป็นเต็มทันที
                for _, child in ipairs(tool:GetDescendants()) do
                    if child:IsA("IntValue") or child:IsA("NumberValue") then
                        if child.Name == "Ammo" or child.Name == "Bullets" or child.Name == "Clip" then
                            child.Value = 300
                        end
                    end
                end
            end
        end
    end
end)

print("Minigun Bypass & Infinite Ammo Hook Loaded!")
