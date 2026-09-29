local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isHolding = false
local spamDelay = 0.03 -- ปรับความเร็วในการสแปม (ยิ่งน้อยยิ่งเร็ว)

-- ฟังก์ชันค้นหาปุ่ม Click หรือ Use
local function getClickButton()
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui.Name == "Use" then
            local clickBtn = gui:FindFirstChild("Click") or gui
            if clickBtn:IsA("GuiObject") then
                return clickBtn
            end
        end
    end
    return nil
end

local targetBtn = getClickButton()

if targetBtn then
    -- ฟังก์ชันยิงการแตะหน้าจอ (Touch / Mouse Press & Release)
    local function sendClickAtButton()
        local pos = targetBtn.AbsolutePosition
        local size = targetBtn.AbsoluteSize
        -- คำนวณจุดกึ่งกลางของปุ่มบนหน้าจอ
        local centerX = pos.X + (size.X / 2)
        local centerY = pos.Y + (size.Y / 2) + 36 -- +36 สำหรับชดเชยแถบ Topbar ของ Roblox

        -- 1. ส่งสัญญาณ Touch/Click ลง
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.01)
        -- 2. ส่งสัญญาณ Touch/Click ปล่อยทันทีเพื่อให้โจมตีออก
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end

    -- ลูปสแปมเมื่อกดค้าง
    local function startSpam()
        task.spawn(function()
            while isHolding do
                sendClickAtButton()
                task.wait(spamDelay)
            end
        end)
    end

    -- ตรวจจับเมื่อผู้เล่นกดค้างที่ปุ่ม
    targetBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not isHolding then
                isHolding = true
                startSpam()
            end
        end
    end)

    -- ตรวจจับเมื่อผู้เล่นปล่อยนิ้ว/คลิก
    targetBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isHolding = false
        end
    end)

    print("ติดตั้งระบบ Touch/Click Spam สำหรับปุ่ม Use สำเร็จ!")
else
    warn("ไม่พบปุ่ม Use บน UI หน้าจอ")
end
