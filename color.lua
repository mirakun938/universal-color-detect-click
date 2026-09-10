local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ค่าตั้งค่าระบบ
local currentMode = "FOLLOW" -- "FOLLOW" หรือ "TELEPORT"
local isFollowing = false
local currentTarget = nil
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

-- 1. ฟังก์ชัน Teleport ด้านหลัง 1 วินาที
local function triggerTeleportBehind()
    if not currentTarget or isTeleporting then return end
    
    local myChar = LocalPlayer.Character
    local targetChar = currentTarget.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(targetChar)
    
    if not myHRP or not targetHRP then return end
    
    local dist = (myHRP.Position - targetHRP.Position).Magnitude
    if dist > maxTeleportDistance then return end

    isTeleporting = true
    
    -- คำนวณตำแหน่งด้านหลังเป้าหมายพร้อมหันหน้ามองเป้าหมาย
    local targetBehindCF = targetHRP.CFrame * CFrame.new(0, 0, followDistance)
    myHRP.CFrame = CFrame.new(targetBehindCF.Position, targetHRP.Position)
    
    task.wait(1)
    isTeleporting = false
end

-- 2. ระบบดักจับการกด C และ Double-Click เลือกเป้าหมาย
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C then
        if currentMode == "TELEPORT" or currentMode == "FOLLOW" then
            triggerTeleportBehind()
        end
    end

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

-- 3. ระบบติดตาม + Lock On หันหน้าหา Player + ดักทางล่วงหน้า
RunService.Heartbeat:Connect(function(dt)
    if not isFollowing or isTeleporting or not currentTarget or not currentTarget.Character then return end
    if currentMode ~= "FOLLOW" then return end

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

    -- คำนวณตำแหน่งดักล่วงหน้า
    local predictOffset = Vector3.new(0, 0, 0)
    if enablePrediction then
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -8, 8)
        predictOffset = currentCFrame.RightVector * sideOffset
    end

    local targetPosition = (currentCFrame.Position - (currentCFrame.LookVector * followDistance)) + predictOffset
    
    -- เคลื่อนที่ไปหาเป้าหมาย
    myHumanoid:MoveTo(targetPosition)
    
    -- 🎯 LOCK ON: หมุนตัวละครเราให้หันหน้ามอง Player เป้าหมายตลอดเวลา
    local lookAtCFrame = CFrame.new(myHRP.Position, Vector3.new(targetHRP.Position.X, myHRP.Position.Y, targetHRP.Position.Z))
    myHRP.CFrame = myHRP.CFrame:Lerp(lookAtCFrame, 0.2)
end)

local function stopFollow()
    isFollowing = false
    currentTarget = nil
    highlightFolder:ClearAllChildren()
    if _G.UpdateTargetUI then _G.UpdateTargetUI("None") end
end

----------------------------------------------------
-- 🖥️ UI Control Panel + Mobile Quick Buttons
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BodyFollow_UI") then playerGui.BodyFollow_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BodyFollow_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 🔘 ปุ่มเปิด-ปิด UI หลัก (Toggle Main UI Button)
local toggleUiBtn = Instance.new("TextButton")
toggleUiBtn.Size = UDim2.new(0, 45, 0, 45)
toggleUiBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
toggleUiBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleUiBtn.Text = "MENU"
toggleUiBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
toggleUiBtn.Font = Enum.Font.SourceSansBold
toggleUiBtn.TextSize = 11
toggleUiBtn.Parent = screenGui
Instance.new("UICorner", toggleUiBtn).CornerRadius = UDim.new(1, 0)

-- ⚡ ปุ่มมือถืออย่างรวดเร็ว (Mobile Quick Action Button)
local quickActionBtn = Instance.new("TextButton")
quickActionBtn.Size = UDim2.new(0, 65, 0, 65)
quickActionBtn.Position = UDim2.new(0.82, 0, 0.65, 0)
quickActionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
quickActionBtn.Text = "⚡ TP"
quickActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
quickActionBtn.Font = Enum.Font.SourceSansBold
quickActionBtn.TextSize = 16
quickActionBtn.Parent = screenGui
Instance.new("UICorner", quickActionBtn).CornerRadius = UDim.new(1, 0)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 265)
mainFrame.Position = UDim2.new(0.02, 0, 0.33, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- สลับ ซ่อน/แสดง UI หลัก
toggleUiBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "  Player Follower & TP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.9, 0, 0, 22)
targetLabel.Position = UDim2.new(0.05, 0, 0, 35)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: Double Click Player"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = mainFrame

_G.UpdateTargetUI = function(name)
    targetLabel.Text = (name == "None") and "Target: Double Click Player" or ("Target: " .. name)
    targetLabel.TextColor3 = (name == "None") and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(0, 255, 120)
end

-- 🔀 ปุ่มสลับโหมด Teleport / Follow
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.9, 0, 0, 30)
modeBtn.Position = UDim2.new(0.05, 0, 0, 60)
modeBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 200)
modeBtn.Text = "🔄 MODE: FOLLOW (LOCK ON)"
modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modeBtn.Font = Enum.Font.SourceSansBold
modeBtn.TextSize = 11
modeBtn.Parent = mainFrame
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)

modeBtn.MouseButton1Click:Connect(function()
    if currentMode == "FOLLOW" then
        currentMode = "TELEPORT"
        modeBtn.Text = "🔄 MODE: TELEPORT ONLY"
        modeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
        quickActionBtn.Text = "⚡ TP"
        quickActionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    else
        currentMode = "FOLLOW"
        modeBtn.Text = "🔄 MODE: FOLLOW (LOCK ON)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 200)
        quickActionBtn.Text = "🏃 FOLLOW"
        quickActionBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    end
end)

-- การทำงานของปุ่มทางลัดมือถือ
quickActionBtn.MouseButton1Click:Connect(function()
    if currentMode == "TELEPORT" or currentMode == "FOLLOW" then
        triggerTeleportBehind()
    end
end)

-- ปรับระยะห่าง (Distance Control)
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.9, 0, 0, 20)
distLabel.Position = UDim2.new(0.05, 0, 0, 95)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Follow Distance: " .. followDistance .. " Studs"
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.Font = Enum.Font.SourceSansBold
distLabel.TextSize = 12
distLabel.Parent = mainFrame

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.42, 0, 0, 25)
minusBtn.Position = UDim2.new(0.05, 0, 0, 117)
minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
minusBtn.Text = "- Distance"
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.TextSize = 11
minusBtn.Parent = mainFrame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

minusBtn.MouseButton1Click:Connect(function()
    followDistance = math.max(1, followDistance - 1)
    distLabel.Text = "Follow Distance: " .. followDistance .. " Studs"
end)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.42, 0, 0, 25)
plusBtn.Position = UDim2.new(0.53, 0, 0, 117)
plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
plusBtn.Text = "+ Distance"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.Font = Enum.Font.SourceSansBold
plusBtn.TextSize = 11
plusBtn.Parent = mainFrame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

plusBtn.MouseButton1Click:Connect(function()
    followDistance = followDistance + 1
    distLabel.Text = "Follow Distance: " .. followDistance .. " Studs"
end)

-- ปุ่มสลับเปิด-ปิด โหมดดักล่วงหน้า
local predictBtn = Instance.new("TextButton")
predictBtn.Size = UDim2.new(0.9, 0, 0, 30)
predictBtn.Position = UDim2.new(0.05, 0, 0, 150)
predictBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
predictBtn.Text = "🔮 Predict (ดักทาง): ON"
predictBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
predictBtn.Font = Enum.Font.SourceSansBold
predictBtn.TextSize = 11
predictBtn.Parent = mainFrame
Instance.new("UICorner", predictBtn).CornerRadius = UDim.new(0, 5)

predictBtn.MouseButton1Click:Connect(function()
    enablePrediction = not enablePrediction
    predictBtn.Text = enablePrediction and "🔮 Predict (ดักทาง): ON" or "🔮 Predict (ดักทาง): OFF"
    predictBtn.BackgroundColor3 = enablePrediction and Color3.fromRGB(40, 150, 90) or Color3.fromRGB(90, 90, 100)
end)

-- ปุ่มหยุดติดตาม
local unfollowBtn = Instance.new("TextButton")
unfollowBtn.Size = UDim2.new(0.9, 0, 0, 30)
unfollowBtn.Position = UDim2.new(0.05, 0, 0, 188)
unfollowBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
unfollowBtn.Text = "❌ Stop Follow"
unfollowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unfollowBtn.Font = Enum.Font.SourceSansBold
unfollowBtn.TextSize = 11
unfollowBtn.Parent = mainFrame
Instance.new("UICorner", unfollowBtn).CornerRadius = UDim.new(0, 5)

unfollowBtn.MouseButton1Click:Connect(function()
    stopFollow()
end)

print("Advanced Player Follower & Quick Action Loaded!")
