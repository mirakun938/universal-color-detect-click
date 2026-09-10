local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ค่าตั้งค่าการติดตาม
local isFollowing = false
local currentTarget = nil
local cameraOffset = Vector3.new(0, 3, 12)
local enablePrediction = true
local predictionAmount = 1.8
local smoothness = 0.15

-- ระบบ Double-Click
local lastClickTime = 0
local lastClickedPlayer = nil
local doubleClickThreshold = 0.5 -- เพิ่มเวลาเป็น 0.5 วินาที กดง่ายขึ้น

local lastTargetYaw = 0

-- สร้าง Highlight โฟลเดอร์
local highlightFolder = CoreGui:FindFirstChild("TargetFollow_Highlight")
if not highlightFolder then
    highlightFolder = Instance.new("Folder")
    highlightFolder.Name = "TargetFollow_Highlight"
    highlightFolder.Parent = CoreGui
end

-- ฟังก์ชันสร้าง Highlight ใส่ตัวเป้าหมาย
local function applyTargetHighlight(player)
    highlightFolder:ClearAllChildren() -- ลบ Highlight เก่าออกก่อน
    
    if player and player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = "TargetHighlight"
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(0, 255, 120) -- สีเขียวมะนาวสว่าง
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = highlightFolder
    end
end

-- ฟังก์ชันค้นหา Player จากชิ้นส่วนที่กดโดน
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

-- ระบบตรวจจับการกด Double-Click
local function handleSelectInput()
    local clickedPart = Mouse.Target
    local clickedPlayer = getPlayerFromTarget(clickedPart)
    local currentTime = tick()

    if clickedPlayer then
        if lastClickedPlayer == clickedPlayer and (currentTime - lastClickTime) <= doubleClickThreshold then
            -- เลือกผู้เล่นสำเร็จ!
            currentTarget = clickedPlayer
            isFollowing = true
            
            -- สร้าง Highlight
            applyTargetHighlight(currentTarget)

            -- อัปเดต UI
            if _G.UpdateTargetUI then
                _G.UpdateTargetUI(currentTarget.Name)
            end

            lastClickedPlayer = nil
            lastClickTime = 0
        else
            lastClickedPlayer = clickedPlayer
            lastClickTime = currentTime
        end
    end
end

-- ดักจับการคลิกเมาส์และหน้าจอมือถือ
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        handleSelectInput()
    end
end)

-- Loop การทำงานของกล้อง
RunService:BindToRenderStep("PredictiveTargetFollow", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not isFollowing or not currentTarget or not currentTarget.Character then
        return
    end

    local targetChar = currentTarget.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("UpperTorso")
    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")

    if not targetHRP or (targetHumanoid and targetHumanoid.Health <= 0) then
        return
    end

    Camera.CameraType = Enum.CameraType.Scriptable

    -- คำนวณระบบหันล่วงหน้า (Prediction Angle)
    local currentCFrame = targetHRP.CFrame
    local currentYaw = math.atan2(-currentCFrame.LookVector.X, -currentCFrame.LookVector.Z)
    
    local yawDelta = currentYaw - lastTargetYaw
    if yawDelta > math.pi then yawDelta = yawDelta - (math.pi * 2) end
    if yawDelta < -math.pi then yawDelta = yawDelta + (math.pi * 2) end
    lastTargetYaw = currentYaw

    local predictOffsetVector = Vector3.new(0, 0, 0)
    if enablePrediction then
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -6, 6)
        predictOffsetVector = currentCFrame.RightVector * sideOffset
    end

    local desiredCamPos = currentCFrame.Position 
        - (currentCFrame.LookVector * cameraOffset.Z) 
        + (Vector3.new(0, cameraOffset.Y, 0)) 
        + predictOffsetVector

    local lookAtPos = currentCFrame.Position + (currentCFrame.LookVector * 10) + (predictOffsetVector * 1.5)

    local targetCFrame = CFrame.new(desiredCamPos, lookAtPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(dt / smoothness, 0, 1))
end)

-- คืนค่ากล้องเดิมเมื่อกด Unfollow
local function stopFollow()
    isFollowing = false
    currentTarget = nil
    highlightFolder:ClearAllChildren()
    Camera.CameraType = Enum.CameraType.Custom
    if _G.UpdateTargetUI then
        _G.UpdateTargetUI("None")
    end
end

----------------------------------------------------
-- 🖥️ UI ควบคุม
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("TargetFollow_UI") then
    playerGui.TargetFollow_UI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TargetFollow_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 150)
mainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "  Target Follow Cam"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.9, 0, 0, 25)
targetLabel.Position = UDim2.new(0.05, 0, 0, 38)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: Double Click Player"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 12
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = mainFrame

_G.UpdateTargetUI = function(name)
    if name == "None" then
        targetLabel.Text = "Target: Double Click Player"
        targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        targetLabel.Text = "Target: " .. name
        targetLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
    end
end

local unfollowBtn = Instance.new("TextButton")
unfollowBtn.Size = UDim2.new(0.9, 0, 0, 30)
unfollowBtn.Position = UDim2.new(0.05, 0, 0, 70)
unfollowBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
unfollowBtn.Text = "❌ Stop Follow / Reset Cam"
unfollowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unfollowBtn.Font = Enum.Font.SourceSansBold
unfollowBtn.TextSize = 12
unfollowBtn.Parent = mainFrame
Instance.new("UICorner", unfollowBtn).CornerRadius = UDim.new(0, 5)

unfollowBtn.MouseButton1Click:Connect(function()
    stopFollow()
end)

local predictBtn = Instance.new("TextButton")
predictBtn.Size = UDim2.new(0.9, 0, 0, 30)
predictBtn.Position = UDim2.new(0.05, 0, 0, 108)
predictBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 90)
predictBtn.Text = "🔮 Predict Mode: ON"
predictBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
predictBtn.Font = Enum.Font.SourceSansBold
predictBtn.TextSize = 12
predictBtn.Parent = mainFrame
Instance.new("UICorner", predictBtn).CornerRadius = UDim.new(0, 5)

predictBtn.MouseButton1Click:Connect(function()
    enablePrediction = not enablePrediction
    predictBtn.Text = enablePrediction and "🔮 Predict Mode: ON" or "🔮 Predict Mode: OFF"
    predictBtn.BackgroundColor3 = enablePrediction and Color3.fromRGB(40, 150, 90) or Color3.fromRGB(90, 90, 100)
end)

print("Target Follow (Fix Double-Click + Added Highlight) Loaded!")
