local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SCALE_FACTOR = 5 -- จำนวนเท่าที่ต้องการขยาย

local function resizeButton(button)
    if not button:GetAttribute("OriginalSize") then
        button:SetAttribute("OriginalSize", button.Size)
    end
    
    local origSize = button:GetAttribute("OriginalSize")
    
    -- คำนวณขนาดใหม่ใหญ่ขึ้น 5 เท่า
    local newSize = UDim2.new(
        origSize.X.Scale * SCALE_FACTOR,
        origSize.X.Offset * SCALE_FACTOR,
        origSize.Y.Scale * SCALE_FACTOR,
        origSize.Y.Offset * SCALE_FACTOR
    )
    
    button.Size = newSize
    button.AnchorPoint = Vector2.new(0.5, 0.5) -- จัดจุดหมุนไว้อยู่ตรงกลาง
end

local function setupShakeButton(button)
    resizeButton(button)
    
    -- ล็อกขนาดไว้ไม่ให้เกมปรับกลับเป็นขนาดเดิมตอนกด
    button:GetPropertyChangedSignal("Size"):Connect(function()
        local origSize = button:GetAttribute("OriginalSize")
        local targetSize = UDim2.new(
            origSize.X.Scale * SCALE_FACTOR,
            origSize.X.Offset * SCALE_FACTOR,
            origSize.Y.Scale * SCALE_FACTOR,
            origSize.Y.Offset * SCALE_FACTOR
        )
        if button.Size ~= targetSize then
            button.Size = targetSize
        end
    end)
end

-- ตรวจหา FishingGui และ ShakeButton
local function init()
    local fishingGui = PlayerGui:WaitForChild("FishingGui", 10)
    if fishingGui then
        local shakeButton = fishingGui:WaitForChild("ShakeButton", 10)
        if shakeButton then
            setupShakeButton(shakeButton)
            print(" ShakeButton resized by 5x successfully!")
        end
    end
end

-- ทำงานทันที และดักจับเมื่อ UI ถูกเกิดใหม่ (Respawn/Re-equip)
init()
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "FishingGui" then
        local shakeButton = child:WaitForChild("ShakeButton", 5)
        if shakeButton then
            setupShakeButton(shakeButton)
        end
    end
end)
