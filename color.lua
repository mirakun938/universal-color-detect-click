local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local isHolding = false
local isLocked = true -- ล็อคการลากปุ่มตั้งต้น
local MAX_LOCK_DISTANCE = 100 -- ระยะสูงสุดในการตรวจจับ NPC (Studs)

-- ลบ UI เก่าออกหากมีอยู่
pcall(function()
    local oldGui = (gethui and gethui():FindFirstChild("CenterLMBSpamGui")) or CoreGui:FindFirstChild("CenterLMBSpamGui")
    if oldGui then oldGui:Destroy() end
end)

-- สร้าง UI หลัก
local ScreenGui = Instance.new("ScreenGui")
local HoldButton = Instance.new("TextButton")
local HoldCorner = Instance.new("UICorner")

local LockButton = Instance.new("TextButton")
local LockCorner = Instance.new("UICorner")

ScreenGui.Name = "CenterLMBSpamGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- 1. ปุ่มสแปมหลัก (ตรงกลางหน้าจอ)
HoldButton.Name = "HoldSpamBtn"
HoldButton.Parent = ScreenGui
HoldButton.AnchorPoint = Vector2.new(0.5, 0.5)
HoldButton.Position = UDim2.new(0.5, 0, 0.5, 0)
HoldButton.Size = UDim2.new(0, 90, 0, 90)
HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
HoldButton.BackgroundTransparency = 0.3
HoldButton.Text = "HOLD TO\nSPAM LMB"
HoldButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HoldButton.TextSize = 14
HoldButton.Font = Enum.Font.SourceSansBold
HoldButton.Active = true
HoldButton.Draggable = not isLocked

HoldCorner.CornerRadius = UDim.new(0, 45)
HoldCorner.Parent = HoldButton

-- 2. ปุ่มเล็กสำหรับ ล็อค/ปลดล็อก การลาก
LockButton.Name = "LockToggleBtn"
LockButton.Parent = ScreenGui
LockButton.AnchorPoint = Vector2.new(0.5, 0)
LockButton.Position = UDim2.new(0.5, 0, 0.5, 55)
LockButton.Size = UDim2.new(0, 70, 0, 25)
LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LockButton.BackgroundTransparency = 0.2
LockButton.Text = "🔒 Lock"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextSize = 12
LockButton.Font = Enum.Font.SourceSansBold
LockButton.Active = true

LockCorner.CornerRadius = UDim.new(0, 6)
LockCorner.Parent = LockButton

-- สลับสถานะ ล็อค/ปลดล็อก
LockButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    HoldButton.Draggable = not isLocked
    
    if isLocked then
        LockButton.Text = "🔒 Lock"
        LockButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        LockButton.Text = "🔓 Unlock"
        LockButton.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
    end
end)

-- ฟังก์ชันค้นหา NPC หรือศัตรูที่ใกล้ที่สุด
local function getNearestNPC()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closestTarget = nil
    local shortestDistance = MAX_LOCK_DISTANCE

    -- ตรวจหา NPC ใน Workspace (ค้นหาจาก Folder npcs หรือ Model ที่มี Humanoid)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= char and obj.Health > 0 then
            local targetChar = obj.Parent
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChildWhichIsA("BasePart")
            
            -- ตรวจสอบว่าไม่ใช่ Player คนอื่น
            local isOtherPlayer = Players:GetPlayerFromCharacter(targetChar)
            if targetRoot and not isOtherPlayer then
                local dist = (targetRoot.Position - myRoot.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestTarget = targetRoot
                end
            end
        end
    end
    return closestTarget
end

-- ฟังก์ชันหันมุมกล้องและตัวละครไปที่เป้าหมาย
local function lookAtTarget(targetPart)
    local char = LocalPlayer.Character
    if not char then return end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    
    if myRoot and targetPart then
        local targetPos = targetPart.Position
        
        -- 1. หมุนตัวละครให้หันไปหา NPC
        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
        
        -- 2. หมุนมุมกล้องให้มองไปที่ NPC
        if Camera then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end

-- ฟังก์ชันจำลองการคลิกเมาส์ซ้าย (LMB Click)
local function clickLMB()
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

-- ลูปสแปม LMB + Auto Look At
local function startSpam()
    task.spawn(function()
        while isHolding do
            local nearestNPC = getNearestNPC()
            if nearestNPC then
                lookAtTarget(nearestNPC)
            end
            
            clickLMB()
            task.wait() -- รอน้อยที่สุดตาม Frame Rate (ไม่ค้าง)
        end
    end)
end

-- ตรวจจับการกดค้าง
HoldButton.MouseButton1Down:Connect(function()
    if not isHolding then
        isHolding = true
        HoldButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        startSpam()
    end
end)

HoldButton.MouseButton1Up:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)

HoldButton.MouseLeave:Connect(function()
    isHolding = false
    HoldButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)
