-- [[ POSITION-BASED AUTO CLICKER (ตรวจจับตำแหน่งเข็ม) ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ค้นหา UI ของตัวเกม (ต้องใส่ชื่อ Frame ของเข็ม และโซนสีเขียวให้ตรงกับตัวเกม)
-- คุณสามารถใช้ Dex Explorer ส่องดูชื่อ UI ในเกมได้
local isRunning = true

RunService.RenderStepped:Connect(function()
    if not isRunning then return end

    pcall(function()
        -- ตัวอย่าง: ดึง UI เข็ม และ UI โซนเป้าหมายจากเกมจริง
        -- (เปลี่ยน path ให้ตรงกับโครงสร้าง UI ในเกม)
        local barGui = playerGui:FindFirstChild("DrinkGui") or playerGui:FindFirstChild("PourGui")
        if not barGui then return end

        local pointer = barGui:FindFirstChild("Pointer", true) -- ตัวเข็มที่วิ่ง
        local targetZone = barGui:FindFirstChild("GreenZone", true) or barGui:FindFirstChild("Target", true) -- โซนสีเขียว

        if pointer and targetZone then
            local pointerPos = pointer.AbsolutePosition.Y
            local targetMinY = targetZone.AbsolutePosition.Y
            local targetMaxY = targetMinY + targetZone.AbsoluteSize.Y

            -- ถ้าตำแหน่ง Y ของเข็ม วิ่งเข้ามาอยู่ในช่วง Y ของโซนสีเขียว
            if pointerPos >= targetMinY and pointerPos <= targetMaxY then
                -- สั่งกดปุ่ม
                local guiInset = GuiService:GetGuiInset()
                local pourBtn = barGui:FindFirstChild("PourButton", true)
                
                local clickX = pourBtn and (pourBtn.AbsolutePosition.X + pourBtn.AbsoluteSize.X/2) or 200
                local clickY = pourBtn and (pourBtn.AbsolutePosition.Y + pourBtn.AbsoluteSize.Y/2 + guiInset.Y) or 500

                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

                task.wait(0.3) -- Cooldown
            end
        end
    end)
end)
