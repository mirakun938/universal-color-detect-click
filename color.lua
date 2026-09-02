-- [[ PERFECT CENTER CALCULATOR ]] --
local TRIGGER_DISTANCE = 14 -- ระยะพิกเซลจากจุดกลาง
local OFFSET_COMPENSATION = 2.5 -- ค่าชดเชยดีเลย์ (สั่งกดก่อนถึงจุดจริงเล็กน้อย)

-- ตัวแปรเก็บพิกัดเฟรมก่อนหน้าเพื่อหาทิศทาง
local lastIndX = nil

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- ... [โครงสร้างดึง UI เดิม] ...
        
        if indicator and meterBar and pourBtn then
            local indX = indicator.AbsolutePosition.X + (indicator.AbsoluteSize.X / 2)
            local barX = meterBar.AbsolutePosition.X + (meterBar.AbsoluteSize.X / 2)
            
            -- คำนวณทิศทางการวิ่งของเข็ม
            local isMovingRight = true
            if lastIndX then
                isMovingRight = (indX > lastIndX)
            end
            lastIndX = indX

            -- คำนวณพิกัดชดเชยการวิ่ง
            local adjustedIndX = indX
            if isMovingRight then
                adjustedIndX = indX + OFFSET_COMPENSATION -- เข็มวิ่งขวา ให้บวกพิกัดล่วงหน้า
            else
                adjustedIndX = indX - OFFSET_COMPENSATION -- เข็มวิ่งซ้าย ให้ลบพิกัดล่วงหน้า
            end

            local diff = math.abs(adjustedIndX - barX)
            statusLabel.Text = string.format("ระยะห่างชดเชย: %.1f px", diff)

            -- สั่งกดเมื่อระยะห่างใกล้ศูนย์กลางมากที่สุด
            if diff <= TRIGGER_DISTANCE and not isPressed then
                isPressed = true
                
                local guiInset = GuiService:GetGuiInset()
                local clickX = pourBtn.AbsolutePosition.X + (pourBtn.AbsoluteSize.X / 2)
                local clickY = pourBtn.AbsolutePosition.Y + (pourBtn.AbsoluteSize.Y / 2) + guiInset.Y

                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                task.wait(0.005)
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

                VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(clickX, clickY, 0), game)
                task.wait(0.005)
                VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(clickX, clickY, 0), game)
            end
        end
    end)
end)
