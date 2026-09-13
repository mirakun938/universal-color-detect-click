local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local animationsFolder = ReplicatedStorage:WaitForChild("Animations", 5)
local qteRemote = animationsFolder and animationsFolder:WaitForChild("QTE", 5) or ReplicatedStorage:FindFirstChild("QTE", true)

local isProcessing = false

-- ฟังก์ชันค้นหาและดึงปุ่ม Keybind ที่ขึ้นมาบน GUI จริง
local function getActiveQTEKey()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local text = string.upper(string.gsub(desc.Text, "%s+", ""))
                    -- ค้นหาตัวอักษรคีย์บอร์ด (เช่น E, Q, R, F, Z, X, C)
                    if #text == 1 and string.match(text, "[A-Z1-9]") then
                        local keyCode = Enum.KeyCode[text]
                        if keyCode then
                            return keyCode
                        end
                    end
                end
            end
        end
    end
    return Enum.KeyCode.E -- Default fallback หากหาไม่เจอ ให้กด E
end

-- ฟังก์ชันรันการกด Keybind
local function pressKey(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.03)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

-- 1. ดักจับจาก RemoteEvent
if qteRemote and qteRemote:IsA("RemoteEvent") then
    qteRemote.OnClientEvent:Connect(function(...)
        if isProcessing then return end
        isProcessing = true

        -- ส่งสัญญาณ Server
        task.wait(0.04)
        pcall(function() qteRemote:FireServer(true) end)

        -- ตรวจหาและกดปุ่ม Keybind (เช่น ปุ่ม E)
        local targetKey = getActiveQTEKey()
        pressKey(targetKey)

        task.wait(0.3)
        isProcessing = false
    end)
end

-- 2. ดักจับ GUI ที่โผล่ขึ้นมาทันที (สำรองเผื่อ Remote ไม่ส่ง ClientEvent)
PlayerGui.ChildAdded:Connect(function(gui)
    task.wait(0.02)
    if not isProcessing and (string.find(string.lower(gui.Name), "qte") or string.find(string.lower(gui.Name), "key")) then
        isProcessing = true
        
        if qteRemote then pcall(function() qteRemote:FireServer(true) end) end
        
        local targetKey = getActiveQTEKey()
        pressKey(targetKey)
        
        task.wait(0.3)
        isProcessing = false
    end
end)

print("Smart Keybind Auto QTE Loaded!")
