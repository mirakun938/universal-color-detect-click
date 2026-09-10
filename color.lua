local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ค่าตั้งค่าระบบ
local isFollowing = false
local currentTarget = nil
local activeMode = "FOLLOW" -- "FOLLOW" หรือ "TELEPORT"
local followDistance = 4
local enablePrediction = true
local predictionAmount = 3
local maxTeleportDistance = 30
local isTeleporting = false

-- ระบบ Double Click Selection
local lastClickTime = 0
local lastClickedPlayer = nil
local doubleClickThreshold = 0.5
local lastTargetYaw = 0

-- สร้าง Highlight โฟลเดอร์
local highlightFolder = CoreGui:FindFirstChild("TargetFollow_Highlight") or Instance.new("Folder", CoreGui)
highlightFolder.Name = "TargetFollow_Highlight"

local function applyTargetHighlight(player)
    highlightFolder:ClearAllChildren()
    if player and player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(0, 255, 120)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = highlightFolder
    end
end

local function getHRP(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end

local function getPlayerFromTarget(targetPart)
    if not targetPart then return nil end
    local model = targetPart:FindFirstAncestorOfClass("Model")
    if model then
        local player = Players:GetPlayerFromCharacter(model)
        if player and player ~= LocalPlayer then
            return player
        end
    end
    return nil
end

-- 1. ฟังก์ชัน Teleport ด้านหลัง 1 วินาที (Keybind C)
local function triggerTeleportBehind()
    if not currentTarget or isTeleporting then return end
    
    local myChar = LocalPlayer.Character
    local targetChar = currentTarget.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(targetChar)
    
    if not myHRP or not targetHRP then return end
    
    local dist = (myHRP.Position - targetHRP.Position).Magnitude
    if dist > maxTeleportDistance then
        print("อยู่ไกลเกินไป! (ระยะปัจจุบัน: " .. math.floor(dist) .. " / สูงสุด: " .. maxTeleportDistance .. ")")
        return
    end

    isTeleporting = true
    local targetBehindCF = targetHRP.CFrame * CFrame.new(0, 0, followDistance)
    myHRP.CFrame = targetBehindCF
    
    task.wait(1)
    isTeleporting = false
end

-- 2. ระบบดักจับปุ่มกด (Keybinds) & Double Click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- [Keybind C]: Teleport ชั่วคราว 1 วินาที
    if input.KeyCode == Enum.KeyCode.C then
        triggerTeleportBehind()
    end
    
    -- [Keybind V]: สลับโหมด Teleport / Follow
    if input.KeyCode == Enum.KeyCode.V then
        activeMode = (activeMode == "FOLLOW") and "TELEPORT" or "FOLLOW"
        if _G.UpdateModeUI then _G.UpdateModeUI(activeMode) end
    end
    
    -- [Keybind X]: เปิด/ปิด UI หลัก
    if input.KeyCode == Enum.KeyCode.X then
        if _G.ToggleMainUI then _G.ToggleMainUI() end
    end

    -- [Double Click]: เล็กล็อคเป้าหมาย
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local clickedPlayer = getPlayerFromTarget(Mouse.Target)
        local currentTime = tick()

        if clickedPlayer then
            if lastClickedPlayer == clickedPlayer and (currentTime - lastClickTime) <= doubleClickThreshold then
                currentTarget = clickedPlayer
                isFollowing = true
                applyTargetHighlight(currentTarget)
                if _G.UpdateTargetUI then _G.UpdateTargetUI(currentTarget.Name) end
                lastClickedPlayer = nil
                lastClickTime = 0
            else
                lastClickedPlayer = clickedPlayer
                lastClickTime = currentTime
            end
        end
    end
end)

-- 3. Loop การทำงาน (Follow + Lock-On / Continuous Teleport)
RunService.Heartbeat:Connect(function(dt)
    if not isFollowing or isTeleporting or not currentTarget or not currentTarget.Character then return end

    local myChar = LocalPlayer.Character
    local targetChar = currentTarget.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(targetChar)
    local myHumanoid = myChar and myChar:FindFirstChildOfClass("Humanoid")

    if not myHRP or not targetHRP or not myHumanoid then return end

    local currentCFrame = targetHRP.CFrame
    local currentYaw = math.atan2(-currentCFrame.LookVector.X, -currentCFrame.LookVector.Z)
    
    local yawDelta = currentYaw - lastTargetYaw
    if yawDelta > math.pi then yawDelta = yawDelta - (math.pi * 2) end
    if yawDelta < -math.pi then yawDelta = yawDelta + (math.pi * 2) end
    lastTargetYaw = currentYaw

    -- คำนวณตำแหน่งดักทางล่วงหน้า
    local predictOffset = Vector3.new(0, 0, 0)
    if enablePrediction then
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -8, 8)
        predictOffset = currentCFrame.RightVector * sideOffset
    end

    local targetPosition = (currentCFrame.Position - (currentCFrame.LookVector * followDistance)) + predictOffset

    if activeMode == "FOLLOW" then
        -- โหมดเดินตาม + Lock-On หันหน้าหาเป้าหมาย
        myHumanoid:MoveTo(targetPosition)
        
        -- Lock-On (ปรับให้ตัวเราหันหน้าล็อคเป้าตลอดเวลา)
        local lookPos = Vector3.new(targetHRP.Position.X, myHRP.Position.Y, targetHRP.Position.Z)
        myHRP.CFrame = CFrame.new(myHRP.Position, lookPos)

    elseif activeMode == "TELEPORT" then
        -- โหมดวาร์ปติดตัวอย่างต่อเนื่อง
        myHRP.CFrame = CFrame.new(targetPosition, targetHRP.Position)
    end
end)

local function stopFollow()
    isFollowing = false
    currentTarget = nil
    highlightFolder:ClearAllChildren()
    if _G.UpdateTargetUI then _G.UpdateTargetUI("None") end
end

----------------------------------------------------
-- 🖥️ UI Control Panel (+ ปุ่มซ่อน UI และ ปุ่มลอยเปิด)
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BodyFollow_UI") then playerGui.BodyFollow_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BodyFollow_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 290)
mainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "  Target Lock & Teleport"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- ปุ่ม Minimize (พับเมนู)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 4)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = mainFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -32)
contentFrame.Position = UDim2.new(0, 0, 0, 32)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentFrame.Visible = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 240, 0, 32) or UDim2.new(0, 240, 0, 290)
    minimizeBtn.Text = isMinimized and "+" or "-"
end)

-- ปุ่ม Toggle ลอยสำหรับเปิด-ปิด UI (ปุ่มเล็กมุมซ้าย)
local toggleOpenBtn = Instance.new("TextButton")
toggleOpenBtn.Size = UDim2.new(0, 80, 0, 30)
toggleOpenBtn.Position = UDim2.new(0.02, 0, 0.23, 0)
toggleOpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleOpenBtn.Text = "Menu (X)"
toggleOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleOpenBtn.Font = Enum.Font.SourceSansBold
toggleOpenBtn.TextSize = 12
toggleOpenBtn.Parent = screenGui
Instance.new("UICorner", toggleOpenBtn).CornerRadius = UDim.new(0, 6)

_G.ToggleMainUI = function()
    mainFrame.Visible = not mainFrame.Visible
end
toggleOpenBtn.MouseButton1Click:Connect(_G.ToggleMainUI)

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.9, 0, 0, 20)
targetLabel.Position = UDim2.new(0.05, 0, 0, 5)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: Double Click Player"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = contentFrame

_G.UpdateTargetUI = function(name)
    targetLabel.Text = (name == "None") and "Target: Double Click Player" or ("Target: " .. name)
    targetLabel.TextColor3 = (name == "None") and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(0, 255, 120)
end

-- ปุ่มสลับโหมด Teleport / Follow
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.9, 0, 0, 28)
modeBtn.Position = UDim2.new(0.05, 0, 0, 28)
modeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
modeBtn.Text = "🔄 Mode: FOLLOW + LockOn (Key V)"
modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modeBtn.Font = Enum.Font.SourceSansBold
modeBtn.TextSize = 11
modeBtn.Parent = contentFrame
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)

_G.UpdateModeUI = function(mode)
    if mode == "FOLLOW" then
        modeBtn.Text = "🔄 Mode: FOLLOW + LockOn (Key V)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    else
        modeBtn.Text = "⚡ Mode: TELEPORT (Key V)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
    end
end

modeBtn.MouseButton1Click:Connect(function()
    activeMode = (activeMode == "FOLLOW") and "TELEPORT" or "FOLLOW"
    _G.UpdateModeUI(activeMode)
end)

-- ปรับระยะห่าง
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.9, 0, 0, 18)
distLabel.Position = UDim2.new(0.05, 0, 0, 60)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Distance: " .. followDistance .. " Studs"
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.Font = Enum.Font.SourceSansBold
distLabel.TextSize = 11
distLabel.Parent = contentFrame

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.42, 0, 0, 24)
minusBtn.Position = UDim2.new(0.05, 0, 0, 80)
minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
minusBtn.Text = "- Distance"
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.TextSize = 11
minusBtn.Parent = contentFrame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

minusBtn.MouseButton1Click:Connect(function()
    followDistance = math.max(1, followDistance - 1)
    distLabel.Text = "Distance: " .. followDistance .. " Studs"
end)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.42, 0, 0, 24)
plusBtn.Position = UDim2.new(0.53, 0, 0, 80)
plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
plusBtn.Text = "+ Distance"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.Font = Enum.Font.SourceSansBold
plusBtn.TextSize = 11
plusBtn.Parent = contentFrame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

plusBtn.MouseButton1Click:Connect(function()
    followDistance = followDistance + 1
    distLabel.Text = "Distance: " .. followDistance .. " Studs"
end)

-- ปุ่ม Teleport สำหรับมือถือ / Key C
local tpMobileBtn = Instance.new("TextButton")
tpMobileBtn.Size = UDim2.new(0.9, 0, 0, 28)
tpMobileBtn.Position = UDim2.new(0.05, 0, 0, 110)
tpMobileBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
tpMobileBtn.Text = "⚡ Quick TP 1s (Key C) [<30 Studs]"
tpMobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpMobileBtn.Font = Enum.Font.SourceSansBold
tpMobileBtn.TextSize = 11
tpMobileBtn.Parent = contentFrame
Instance.new("UICorner", tpMobileBtn).CornerRadius = UDim.new(0, 5)

tpMobileBtn.MouseButton1Click:Connect(function()
    triggerTeleportBehind()
end)

-- ปุ่มเปิด/ปิด โหมดดักล่วงหน้า
local predictBtn = Instance.new("TextButton")
predictBtn.Size = UDim2.new(0.9, 0, 0, 28)
predictBtn.Position = UDim2.new(0.05, 0, 0, 144)
predictBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
predictBtn.Text = "🔮 Predict (ดักทาง): ON"
predictBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
predictBtn.Font = Enum.Font.SourceSansBold
predictBtn.TextSize = 11
predictBtn.Parent = contentFrame
Instance.new("UICorner", predictBtn).CornerRadius = UDim.new(0, 5)

predictBtn.MouseButton1Click:Connect(function()
    enablePrediction = not enablePrediction
    predictBtn.Text = enablePrediction and "🔮 Predict (ดักทาง): ON" or "🔮 Predict (ดักทาง): OFF"
    predictBtn.BackgroundColor3 = enablePrediction and Color3.fromRGB(40, 150, 90) or Color3.fromRGB(90, 90, 100)
end)

-- ปุ่มหยุดติดตาม
local unfollowBtn = Instance.new("TextButton")
unfollowBtn.Size = UDim2.new(0.9, 0, 0, 28)
unfollowBtn.Position = UDim2.new(0.05, 0, 0, 178)
unfollowBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
unfollowBtn.Text = "❌ Stop Follow"
unfollowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unfollowBtn.Font = Enum.Font.SourceSansBold
unfollowBtn.TextSize = 11
unfollowBtn.Parent = contentFrame
Instance.new("UICorner", unfollowBtn).CornerRadius = UDim.new(0, 5)

unfollowBtn.MouseButton1Click:Connect(function()
    stopFollow()
end)

print("Advanced Target Follower & Keybind System Activated!")
