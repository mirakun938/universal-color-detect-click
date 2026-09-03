local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันจำลองการคลิกบนปุ่ม UI โดยตรง
local function clickButton(button)
    if button and button.Visible then
        local pos = button.AbsolutePosition
        local size = button.AbsoluteSize
        local x = pos.X + size.X / 2
        local y = pos.Y + size.Y / 2 + GuiService:GetGuiInset().Y
        
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end
end

-- 1. ลูปจับมินิเกม (Auto Shake & Left/Right Minigame)
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not PlayerGui then return end
            
            -- ค้นหาปุ่ม SHAKE บน UI แล้วกดทันที
            for _, v in pairs(PlayerGui:GetDescendants()) do
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    -- ตรวจจับปุ่ม Shake
                    if v.Name:upper():find("SHAKE") or (v:IsA("TextLabel") and v.Text:upper():find("SHAKE")) then
                        local btn = v:IsA("GuiObject") and v or v.Parent
                        clickButton(btn)
                    end
                    
                    -- ตรวจจับปุ่ม Left / Right ในมินิเกม
                    if v.Name:upper() == "LEFT" or v.Name:upper() == "RIGHT" then
                        if v.Visible then
                            clickButton(v)
                        end
                    end
                end
            end
        end)
    end
end)

-- 2. ลูป Auto Cast (เหวี่ยงเบ็ดอัตโนมัติ)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character then return end
            
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool then
                -- ลองสั่งใช้งาน Tool (เหวี่ยงเบ็ด) ผ่านฟังก์ชันพื้นฐาน
                Tool:Activate()
            end
        end)
    end
end)
