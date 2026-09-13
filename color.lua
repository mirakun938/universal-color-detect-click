local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- ปรับแต่งค่า Timing จังหวะ Perfect
local PERFECT_TAP_DELAY = 0.18   -- หน่วงเวลาจังหวะ Tap
local STAGE2_KEY_DELAY = 0.12   -- หน่วงเวลาจังหวะ Keybind

-- ฟังก์ชันสแกนหาปุ่ม Keybind บนหน้าจอ (A, D, E ฯลฯ)
local function getActiveKeycode()
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible then
                        local text = string.upper(string.gsub(desc.Text, "%s+", ""))
                        -- ตรวจจับตัวอักษรเดี่ยว เช่น A, D, E
                        if #text == 1 and string.match(text, "[A-Z1-9]") then
                            local keyCode = Enum.KeyCode[text]
                            if keyCode then return keyCode end
                        end
                    end
                end
            end
        end
    end)
    return Enum.KeyCode.E -- ค่าสำรองถ้าสแกนไม่เจอ
end

-- ฟังก์ชันกดปุ่มตาม KeyCode ที่ได้รับ
local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- ฟังก์ชัน Tap หน้าจอ
local function simulateTap()
    pcall(function()
        local viewport = Workspace.CurrentCamera.ViewportSize
        VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
    end)
end

if qteRemote and qteRemote:IsA("RemoteEvent") then
    print("Multi-Key Auto QTE (A/D/E) Loaded!")
    
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true
        
        -- Stage 1: Tap จังหวะแรก
        task.wait(PERFECT_TAP_DELAY)
        simulateTap()
        pcall(function() qteRemote:FireServer(true) end)
        
        -- Stage 2: สแกนหาปุ่ม A / D / E แล้วกดตามปุ่มที่ขึ้นบนจอ
        task.wait(STAGE2_KEY_DELAY)
        local keyToPress = getActiveKeycode()
        pressKey(keyToPress)
        
        task.wait(0.4)
        isProcessing = false
    end)
end
