local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ค้นหา Remote Event จาก ReplicatedStorage
local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- ฟังก์ชันจำลองการกดปุ่ม E บน คีย์บอร์ด/ระบบ
local function pressEKey()
    pcall(function()
        -- กดปุ่ม E
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

if qteRemote and qteRemote:IsA("RemoteEvent") then
    print("Direct E-Key Auto QTE Ready!")
    
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true
        
        -- 1. หน่วงเวลาเล็กน้อยเพื่อหลบ Anti-Cheat
        task.wait(0.04)
        
        -- 2. ส่งค่า true ไปหาเซิร์ฟเวอร์โดยตรง
        pcall(function()
            qteRemote:FireServer(true)
        end)
        
        -- 3. สั่งกดปุ่ม E ทันที 2 ครั้งติดกันเพื่อความแน่นอน
        pressEKey()
        task.wait(0.05)
        pressEKey()
        
        task.wait(0.3)
        isProcessing = false
    end)
else
    warn("ไม่พบ QTE RemoteEvent")
end
