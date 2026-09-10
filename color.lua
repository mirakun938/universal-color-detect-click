local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ค่าตั้งค่ามุมมองและการติดตาม
local isFollowing = false
local currentTarget = nil
local cameraOffset = Vector3.new(0, 3, 12) -- ระยะห่าง (สูง 3 studs, ถอยหลัง 12 studs)
local enablePrediction = true -- เปิดโหมดเอียงกล้องล่วงหน้า
local predictionAmount = 1.8 -- ความแรงของการเอียงกล้องล่วงหน้า
local smoothness = 0.15 -- ความนุ่มนวลของการเคลื่อนกล้อง (ยิ่งน้อยยิ่งนุ่ม)

-- ระบบ Double-Click
local lastClickTime = 0
local lastClickedPlayer = nil
local doubleClickThreshold = 0.4 -- ระยะเวลาคลิกซ้ำ (วินาที)

-- ค่าคำนวณการหันของเป้าหมาย
local lastTargetYaw = 0

-- ฟังก์ชันค้นหา Player จาก Instance/Part ที่คลิกโดน
local function getPlayerFromHit(hitInstance)
    if not hitInstance then return nil end
    local model = hitInstance:FindFirstAncestorOfClass("Model")
    if model then
        local player = Players:GetPlayerFromCharacter(model)
        if player and player ~= LocalPlayer then
            return player
        end
    end
    return nil
end

-- 1. ระบบตรวจจับการดับเบิ้ลคลิก (Double-Click Selection)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = UserInputService:GetMouseLocation()
        local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        
        local raycastParams = RaycastParams.new()
        if LocalPlayer.Character then
            raycastParams.FilterAncestors:Clear()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        end
        
        local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        
        if raycastResult and raycastResult.Instance then
            local clickedPlayer = getPlayerFromHit(raycastResult.Instance)
            local currentTime = tick()
            
            if clickedPlayer then
                if lastClickedPlayer == clickedPlayer and (currentTime - lastClickTime) <= doubleClickThreshold then
                    -- เลือกผู้เล่นสำเร็จ! (Double-Click Triggered)
                    currentTarget = clickedPlayer
                    isFollowing = true
                    print("Locked Target: " .. currentTarget.Name)
                    
                    -- แสดงเอฟเฟกต์แจ้งเตือนสั้นๆ บน UI
                    if _G.UpdateTargetUI then
                        _G.UpdateTargetUI(currentTarget.Name)
                    end
                    
                    lastClickedPlayer = nil
                    lastClickTime = 0
                else
                    lastClickedPlayer = clickedPlayer
                    lastClickTime = currentTime
                end
            else
                lastClickedPlayer = nil
            end
        end
    end
end)

-- 2. ระบบกล้องติดตาม + หันมองล่วงหน้า (Camera Render Loop)
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

    -- เปลี่ยนพฤติกรรมกล้องหลักเป็น Scriptable
    Camera.CameraType = Enum.CameraType.Scriptable

    -- คำนวณทิศทางการหัน (Yaw Velocity) เพื่อทำระบบเอียงกล้องล่วงหน้า
    local currentCFrame = targetHRP.CFrame
    local currentYaw = math.atan2(-currentCFrame.LookVector.X, -currentCFrame.LookVector.Z)
    
    local yawDelta = currentYaw - lastTargetYaw
    -- ปรับองศาให้อยู่ในช่วง -pi ถึง pi
    if yawDelta > math.pi then yawDelta = yawDelta - (math.pi * 2) end
    if yawDelta < -math.pi then yawDelta = yawDelta + (math.pi * 2) end
    
    lastTargetYaw = currentYaw

    -- คำนวณค่าเอียงล่วงหน้า (Prediction Offset)
    local predictOffsetVector = Vector3.new(0, 0, 0)
    if enablePrediction then
        -- ถ้าเป้าหมายหันซ้าย/ขวา กล้องจะเบี่ยงไปทางนั้นล่วงหน้า
        local turnSpeed = yawDelta / math.max(dt, 0.001)
        local sideOffset = math.clamp(-turnSpeed * predictionAmount, -6, 6)
        predictOffsetVector = currentCFrame.RightVector * sideOffset
    end

    -- คำนวณตำแหน่งเป้าหมายของกล้อง (ด้านหลังตัวละคร + Offset ล่วงหน้า)
    local desiredCamPos = currentCFrame.Position 
        - (currentCFrame.LookVector * cameraOffset.Z) 
        + (Vector3.new(0, cameraOffset.Y, 0)) 
        + predictOffsetVector

    -- คำนวณจุดที่กล้องส่องไปหา (มองไปข้างหน้าตัวละคร + เบี่ยงล่วงหน้า)
    local lookAtPos = currentCFrame.Position + (currentCFrame.LookVector * 10) + (predictOffsetVector * 1.5)

    -- Lerp กล้องให้นุ่มนวล
    local targetCFrame = CFrame.new(desiredCamPos, lookAtPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(dt / smoothness, 0, 1))
end)

-- คืนค่ากล้องเดิมเมื่อหยุดติดตาม
local function stopFollow()
    isFollowing = false
    currentTarget = nil
    Camera.CameraType = Enum.CameraType.Custom
    if _G.UpdateTargetUI then
        _G.UpdateTargetUI("None")
    end
end

----------------------------------------------------
-- 🖥️ UI ควบคุมระบบเปิด/ปิด และแสดงชื่อเป้าหมาย
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
targetLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 13
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = mainFrame

_G.UpdateTargetUI = function(name)
    if name == "None" then
        targetLabel.Text = "Target: Double Click Player"
        targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        targetLabel.Text = "Target: " .. name
        targetLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
    end
end

-- ปุ่มยกเลิกการติดตาม (Unfollow)
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

-- ปุ่มสลับเปิด-ปิด โหมดหันกล้องล่วงหน้า (Predictive Lookahead)
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

print("Target Follow (Double Click + Lookahead) Loaded!")
