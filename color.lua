local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- หน่วงเวลาจังหวะ Perfect (ปรับจูนตามความเหมาะสม)
local PERFECT_TAP_DELAY = 0.18
local STAGE2_KEY_DELAY = 0.12

-- ฟังก์ชันจำลอง Tap หน้าจอ
local function simulateTap()
    pcall(function()
        local viewport = Workspace.CurrentCamera.ViewportSize
        VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
    end)
end

-- ฟังก์ชันจำลองการกดปุ่ม Keybind บนคีย์บอร์ด
local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- ตรวจหาตัวอักษรที่ขึ้นบน UI หน้าจอ (A หรือ E)
local function detectActiveKey()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local text = string.upper(string.gsub(desc.Text, "%s+", ""))
                    if text == "A" or text == "E" then
                        return Enum.KeyCode[text]
                    end
                end
            end
        end
    end
    return nil
end

if qteRemote and qteRemote:IsA("RemoteEvent") then
    print("Multi-Key Auto QTE (A/E Supported) Loaded!")
    
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true
        
        -- Stage 1: Tap ในจังหวะ Perfect
        task.wait(PERFECT_TAP_DELAY)
        simulateTap()
        pcall(function() qteRemote:FireServer(true) end)
        
        -- Stage 2: สลับเข้าสู่โหมด Keybind
        task.wait(STAGE2_KEY_DELAY)
        
        local detectedKey = detectActiveKey()
        if detectedKey then
            pressKey(detectedKey)
        else
            -- หากอ่าน UI ไม่ทัน สั่งกดทั้ง A และ E สำรองไว้
            pressKey(Enum.KeyCode.A)
            task.wait(0.02)
            pressKey(Enum.KeyCode.E)
        end
        
        task.wait(0.4)
        isProcessing = false
    end)
end
