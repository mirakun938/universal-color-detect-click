local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isHolding = false
local spamSpeed = 0.03 -- ระยะเวลารอปุ่มปล่อยและกดใหม่ (ยิ่งน้อยยิ่งสแปมเร็ว)

-- ฟังก์ชันค้นหาปุ่ม Click ใน Use
local function findClickButton()
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui.Name == "Use" then
            local clickBtn = gui:FindFirstChild("Click")
            if clickBtn and (clickBtn:IsA("GuiButton") or clickBtn:IsA("TextButton") or clickBtn:IsA("ImageButton")) then
                return clickBtn
            end
        end
    end
    return nil
end

local clickButton = findClickButton()

if clickButton then
    -- ฟังก์ชันยิงสัญญาณ กด และ ปล่อย (Press -> Release Sequence)
    local function triggerAttackSequence()
        if firesignal then
            -- 1. ยิงสัญญาณกดลง (Press)
            firesignal(clickButton.MouseButton1Down)
            task.wait(0.01)
            -- 2. ยิงสัญญาณปล่อย (Release) เพื่อให้การโจมตีทำงาน
            firesignal(clickButton.MouseButton1Up)
            firesignal(clickButton.MouseButton1Click)
            firesignal(clickButton.Activated)
        end
    end

    -- ลูปสแปมการโจมตีเมื่อกดปุ่มค้างไว้
    local function startSpam()
        task.spawn(function()
            while isHolding do
                triggerAttackSequence()
                task.wait(spamSpeed)
            end
        end)
    end

    -- ตรวจจับเมื่อผู้เล่นเริ่มกดค้างที่ปุ่ม
    clickButton.MouseButton1Down:Connect(function()
        if not isHolding then
            isHolding = true
            startSpam()
        end
    end)

    -- ตรวจจับเมื่อผู้เล่นปล่อยนิ้วออกจากปุ่มจริง
    clickButton.MouseButton1Up:Connect(function()
        isHolding = false
    end)

    clickButton.MouseLeave:Connect(function()
        isHolding = false
    end)

    print("ติดตั้งระบบ Release to Attack Spam ให้กับปุ่ม Use เรียบร้อยแล้ว!")
else
    warn("ไม่พบปุ่ม Click ใน PlayerGui")
end
