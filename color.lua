local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ค่าตั้งค่าระบบ
local currentMode = "TELEPORT" -- "TELEPORT" หรือ "FOLLOW"
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

----------------------------------------------------
-- ⚡ ฟังก์ชัน Teleport Loop ข้างหลัง 1 วินาที แล้วยกเลิก
----------------------------------------------------
local function triggerTeleportLoop()
    if not currentTarget or isTeleporting then return end
    
    local myChar = LocalPlayer.Character
    local targetChar = currentTarget.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(targetChar)
    
    if not myHRP or not targetHRP then return end
    
    -- ตรวจสอบระยะห่าง (ต้องไม่เกิน 30 studs)
    local dist = (myHRP.Position - targetHRP.Position).Magnitude
    if dist > maxTeleportDistance then return end

    isTeleporting = true
    
    local startTime = tick()
    local duration = 1.0 -- ระยะเวลา Loop 1 วินาที
    
    -- วน Loop วาร์ปซ้ำๆ ไปข้างหลังทุกๆ เฟรมเป็นเวลา 1 วินาที
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsedTime = tick() - startTime
        
        -- ตรวจสอบว่ายังไม่หมดเวลา 1 วินาที และตัวละครยังอยู่ครบ
        if elapsedTime < duration and currentTarget and currentTarget.Character and myHRP and targetHRP then
            local currentTargetHRP = getHRP(currentTarget.Character)
            if currentTargetHRP then
                -- คำนวณตำแหน่งด้านหลังเป้าหมาย พร้อมหันหน้าล็อคเป้า
                local targetBehindCF = currentTargetHRP.CFrame * CFrame.new(0, 0, followDistance)
                myHRP.CFrame = CFrame.new(targetBehindCF.Position, currentTargetHRP.Position)
            end
        else
            -- ครบ 1 วินาทีแล้ว ทำการยกเลิก Loop ทันที!
            connection:Disconnect()
            isTeleporting = false
        end
    end)
end

-- ดักจับการกด C และ Double-Click เลือกเป้าหมาย
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C then
        triggerTeleportLoop()
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

-- ระบบติดตามปกติ (สำหรับโหมด FOLLOW)
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

    local predictOffset = Vector3.new(0, 0, 0)
    if enablePrediction then
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -8, 8)
        predictOffset = currentCFrame.RightVector * sideOffset
    end

    local targetPosition = (currentCFrame.Position - (currentCFrame.LookVector * followDistance)) + predictOffset
    myHumanoid:MoveTo(targetPosition)
    
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
-- 🖥️ UI Control Panel
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BodyFollow_UI") then playerGui.BodyFollow_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BodyFollow_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ปุ่ม Toggle เมนูหลัก
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

-- ปุ่มทางลัดมือถือ
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

-- ปุ่มสลับโหมด
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.9, 0, 0, 30)
modeBtn.Position = UDim2.new(0.05, 0, 0, 60)
modeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
modeBtn.Text = "🔄 MODE: TELEPORT LOOP 1s"
modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modeBtn.Font = Enum.Font.SourceSansBold
modeBtn.TextSize = 11
modeBtn.Parent = mainFrame
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 5)

modeBtn.MouseButton1Click:Connect(function()
    if currentMode == "TELEPORT" then
        currentMode = "FOLLOW"
        modeBtn.Text = "🔄 MODE: FOLLOW (LOCK ON)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 200)
        quickActionBtn.Text = "🏃 FOLLOW"
        quickActionBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        currentMode = "TELEPORT"
        modeBtn.Text = "🔄 MODE: TELEPORT LOOP 1s"
        modeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
        quickActionBtn.Text = "⚡ TP"
        quickActionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
end)

quickActionBtn.MouseButton1Click:Connect(function()
    triggerTeleportLoop()
end)

-- ปุ่มปรับระยะห่าง
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

print("Teleport Loop 1s System Loaded!")
