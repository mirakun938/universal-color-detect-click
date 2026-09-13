local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- ฟังก์ชันจำลอง Tap คลิกกลางหน้าจอ (สำหรับปลดล็อก QTE Stage แรก)
local function simulateTap()
    pcall(function()
        local viewport = Workspace.CurrentCamera.ViewportSize
        local clickX = viewport.X / 2
        local clickY = viewport.Y / 2
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
    end)
end

-- ฟังก์ชันส่งสัญญาณกด Keybind
local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

if qteRemote and qteRemote:IsA("RemoteEvent") then
    print("Multi-Key Auto QTE System Active!")
    
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true
        
        -- 1. Tap 1 ครั้ง + ส่ง Remote true เพื่อ Trigger เปลี่ยนเป็น Keybind Mode
        simulateTap()
        pcall(function() qteRemote:FireServer(true) end)
        
        task.wait(0.06)
        
        -- 2. รัวกด Keybind (ทั้ง A และ E) เพื่อรองรับปุ่มใหม่
        for i = 1, 3 do
            pressKey(Enum.KeyCode.A)
            pressKey(Enum.KeyCode.E)
            task.wait(0.03)
        end
        
        task.wait(0.2)
        isProcessing = false
    end)
end
