local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ค่าตั้งค่าระบบ
local isFollowing = false
local currentTarget = nil
local followDistance = 4 -- ระยะห่างเริ่มต้นจากด้านหลัง Player (ปรับได้)
local enablePrediction = true -- เปิด/ปิดโหมดดักล่วงหน้า
local predictionAmount = 3 -- ความแรงของการไปดักล่วงหน้า
local maxTeleportDistance = 30 -- ระยะทำการ Teleport (30 Studs)
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

-- 1. ฟังก์ชัน Teleport ด้านหลัง 1 วินาที (Keybind C / ปุ่ม Mobile)
local function triggerTeleportBehind()
    if not currentTarget or isTeleporting then return end
    
    local myChar = LocalPlayer.Character
    local targetChar = currentTarget.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(targetChar)
    
    if not myHRP or not targetHRP then return end
    
    -- เช็กระยะห่าง ต้องไม่เกิน 30 studs
    local dist = (myHRP.Position - targetHRP.Position).Magnitude
    if dist > maxTeleportDistance then
        print("อยู่ไกลเกินไป! (ระยะปัจจุบัน: " .. math.floor(dist) .. " / สูงสุด: " .. maxTeleportDistance .. ")")
        return
    end

    isTeleporting = true
    local oldCFrame = myHRP.CFrame
    
    -- คำนวณตำแหน่งด้านหลังเป้าหมาย
    local targetBehindCF = targetHRP.CFrame * CFrame.new(0, 0, followDistance)
    myHRP.CFrame = targetBehindCF
    
    -- ค้างไว้ 1 วินาที
    task.wait(1)
    
    isTeleporting = false
end

-- 2. ดักจับการดับเบิลคลิกเพื่อเลือกเป้าหมาย
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Keybind กด C เพื่อ Teleport
    if input.KeyCode == Enum.KeyCode.C then
        triggerTeleportBehind()
    end

    -- คลิก 2 ครั้งเพื่อเล็กล็อค
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

-- 3. ระบบตัวเราเดินตามด้านหลัง + ดักทางล่วงหน้า (Predictive Character Follow)
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

    -- คำนวณตำแหน่งไปดักล่วงหน้าเมื่อหันซ้าย-ขวา
    local predictOffset = Vector3.new(0, 0, 0)
    if enablePrediction then
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -8, 8)
        predictOffset = currentCFrame.RightVector * sideOffset
    end

    -- คำนวณจุดเป้าหมายด้านหลัง + ทิศทางดักล่วงหน้า
    local targetPosition = (currentCFrame.Position - (currentCFrame.LookVector * followDistance)) + predictOffset
    
    -- สั่งให้ตัวเราเดิน/วิ่งไปตำแหน่งนั้น
    myHumanoid:MoveTo(targetPosition)
end)

local function stopFollow()
    isFollowing = false
    currentTarget = nil
    highlightFolder:ClearAllChildren()
    if _G.UpdateTargetUI then _G.UpdateTargetUI("None") end
end

----------------------------------------------------
-- 🖥️ UI Control Panel (รองรับปุ่มกดบน Mobile)
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("BodyFollow_UI") then playerGui.BodyFollow_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BodyFollow_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 230)
mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

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

-- ปรับระยะห่าง (Distance Control)
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.9, 0, 0, 20)
distLabel.Position = UDim2.new(0.05, 0, 0, 60)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Follow Distance: " .. followDistance .. " Studs"
distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distLabel.Font = Enum.Font.SourceSansBold
distLabel.TextSize = 12
distLabel.Parent = mainFrame

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.42, 0, 0, 25)
minusBtn.Position = UDim2.new(0.05, 0, 0, 82)
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
plusBtn.Position = UDim2.new(0.53, 0, 0, 82)
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

-- ปุ่ม Teleport สำหรับมือถือ (หรือกด C)
local tpMobileBtn = Instance.new("TextButton")
tpMobileBtn.Size = UDim2.new(0.9, 0, 0, 32)
tpMobileBtn.Position = UDim2.new(0.05, 0, 0, 115)
tpMobileBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
tpMobileBtn.Text = "⚡ TP Behind (Key C) [Range < 30]"
tpMobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpMobileBtn.Font = Enum.Font.SourceSansBold
tpMobileBtn.TextSize = 11
tpMobileBtn.Parent = mainFrame
Instance.new("UICorner", tpMobileBtn).CornerRadius = UDim.new(0, 5)

tpMobileBtn.MouseButton1Click:Connect(function()
    triggerTeleportBehind()
end)

-- ปุ่มสลับเปิด-ปิด โหมดดักล่วงหน้า
local predictBtn = Instance.new("TextButton")
predictBtn.Size = UDim2.new(0.9, 0, 0, 30)
predictBtn.Position = UDim2.new(0.05, 0, 0, 152)
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

print("Character Follower & TP Behind System Loaded!")
