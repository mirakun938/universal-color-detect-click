local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- ฟังก์ชันจำลองการ Tap กลางหน้าจอ
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

-- ฟังก์ชันจำลองกดปุ่ม E
local function pressEKey()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

if qteRemote and qteRemote:IsA("RemoteEvent") then
    print("Sequence Auto QTE Loaded!")
    
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true
        
        -- Step 1: สั่ง Tap + ยิง Event เพื่อเปิดทางให้ QTE เปลี่ยนโหมด
        simulateTap()
        pcall(function() qteRemote:FireServer(true) end)
        
        -- หน่วงเวลาสั้นๆ ให้ระบบเกมสลับไป Stage 2 (Keybind E)
        task.wait(0.08)
        
        -- Step 2: รัวปุ่ม E เพื่อผ่านจังหวะ Keybind
        for i = 1, 3 do
            pressEKey()
            task.wait(0.03)
        end
        
        task.wait(0.3)
        isProcessing = false
    end)
end
