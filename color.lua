local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isHolding = false
local spamSpeed = 0.05 -- ปรับความเร็วในการสแปม (ยิ่งน้อยยิ่งเร็ว)

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
    -- ฟังก์ชันรันสแปมเมื่อกดค้าง
    local function startSpam()
        task.spawn(function()
            while isHolding do
                -- จำลองการกดปุ่ม Click ด้วย firesignal หรือ VirtualInput
                if firesignal then
                    firesignal(clickButton.MouseButton1Click)
                    firesignal(clickButton.Activated)
                end
                task.wait(spamSpeed)
            end
        end)
    end

    -- ตรวจจับการกดปุ่มค้าง (MouseButton1Down / InputBegan)
    clickButton.MouseButton1Down:Connect(function()
        if not isHolding then
            isHolding = true
            startSpam()
        end
    end)

    -- ตรวจจับการปล่อยปุ่ม (MouseButton1Up / MouseLeave)
    clickButton.MouseButton1Up:Connect(function()
        isHolding = false
    end)

    clickButton.MouseLeave:Connect(function()
        isHolding = false
    end)

    print("ติดตั้งระบบ Hold to Spam ให้กับปุ่ม Use เรียบร้อยแล้ว")
else
    warn("ไม่พบปุ่ม Click ใน Gui ตัวเกม")
end
