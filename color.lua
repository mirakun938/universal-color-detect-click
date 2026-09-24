local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local autoDriving = false
local tapToMoveEnabled = false

-- ฟังก์ชันค้นหาตำแหน่งจุดส่งของจาก Workspace.locations
local function getTargetPosition()
    local locationsFolder = Workspace:FindFirstChild("locations")
    if not locationsFolder then return nil end

    local targetName = nil
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                        local txt = desc.Text
                        if string.find(string.lower(txt), "go to") or string.find(string.lower(txt), "deliver") then
                            targetName = string.gsub(txt, "[Gg][Oo] [Tt][Oo] ", "")
                            targetName = string.gsub(targetName, "[Dd][Ee][Ll][Ii][Vv][Ee][Rr] [Tt][Oo] ", "")
                            break
                        end
                    end
                end
            end
        end
    end

    if targetName then
        local cleanTarget = string.lower(targetName)
        for _, child in ipairs(locationsFolder:GetChildren()) do
            if string.find(string.lower(child.Name), cleanTarget) or string.find(cleanTarget, string.lower(child.Name)) then
                return child:IsA("BasePart") and child.Position or child:GetPivot().Position
            end
        end
    end

    local firstLoc = locationsFolder:GetChildren()[1]
    if firstLoc then
        return firstLoc:IsA("BasePart") and firstLoc.Position or firstLoc:GetPivot().Position
    end
    return nil
end

-- ฟังก์ชันขับรถไปยังจุดหมายด้วย Smart Pathfinding
local function driveToPosition(destinationPos)
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not hum or not rootPart then return end

    -- คำนวณเส้นทางหลบสิ่งกีดขวาง
    local path = PathfindingService:CreatePath({
        AgentRadius = 5, -- ขนาดรัศมีสำหรับตัวรถ
        AgentHeight = 5,
        AgentCanJump = false
    })

    local success, errorMessage = pcall(function()
        path:ComputeAsync(rootPart.Position, destinationPos)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        autoDriving = true
        local waypoints = path:GetWaypoints()

        for _, waypoint in ipairs(waypoints) do
            if not autoDriving then break end
            
            -- สั่งให้ Humanoid เดิน/ขับไปยังจุด Waypoint (รองรับทั้งการเดินและการขับรถในโหมด Touch/Joystick)
            hum:MoveTo(waypoint.Position)
            
            -- รอจนกว่ารถจะวิ่งไปถึงจุดโหนดถัดไป
            local reached = hum.MoveToFinished:Wait()
            if not reached then
                -- ถ้าติดสิ่งกีดขวาง ให้ส่งคำสั่งย้ำอีกครั้ง
                hum:MoveTo(waypoint.Position)
            end
        end
        autoDriving = false
        print("ถึงจุดหมายเรียบร้อยแล้ว!")
    else
        warn("ไม่สามารถคำนวณเส้นทางได้:", errorMessage)
    end
end

-- ระบบ Tap to Drive (แตะบนจอ/พื้นถนนเพื่อสั่งขับไป)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not tapToMoveEnabled then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if Mouse.Target then
            autoDriving = false -- ยกเลิกงานขับเดิม
            task.wait(0.1)
            task.spawn(function()
                driveToPosition(Mouse.Hit.Position)
            end)
        end
    end
end)

-- สร้าง GUI ปุ่มควบคุม
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SmartDriveGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มที่ 1: ขับไปจุดส่งของอัตโนมัติ
local DriveBtn = Instance.new("TextButton")
DriveBtn.Name = "DriveTargetBtn"
DriveBtn.Parent = ScreenGui
DriveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
DriveBtn.Position = UDim2.new(0.02, 0, 0.40, 0)
DriveBtn.Size = UDim2.new(0, 170, 0, 45)
DriveBtn.Font = Enum.Font.SourceSansBold
DriveBtn.Text = "SMART DRIVE TO TARGET"
DriveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DriveBtn.TextSize = 13.00
DriveBtn.Active = true
DriveBtn.Draggable = true

local Corner1 = Instance.new("UICorner")
Corner1.CornerRadius = UDim.new(0, 8)
Corner1.Parent = DriveBtn

DriveBtn.MouseButton1Click:Connect(function()
    local targetPos = getTargetPosition()
    if targetPos then
        autoDriving = false
        task.wait(0.1)
        task.spawn(function()
            driveToPosition(targetPos)
        end)
    else
        warn("ไม่พบพิกัดเป้าหมาย")
    end
end)

-- ปุ่มที่ 2: เปิด/ปิดระบบ Tap to Move (แตะพื้นถนนเพื่อขับไป)
local TapBtn = Instance.new("TextButton")
TapBtn.Name = "TapMoveBtn"
TapBtn.Parent = ScreenGui
TapBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
TapBtn.Position = UDim2.new(0.02, 0, 0.48, 0)
TapBtn.Size = UDim2.new(0, 170, 0, 40)
TapBtn.Font = Enum.Font.SourceSansBold
TapBtn.Text = "TAP TO DRIVE: OFF"
TapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TapBtn.TextSize = 13.00
TapBtn.Active = true
TapBtn.Draggable = true

local Corner2 = Instance.new("UICorner")
Corner2.CornerRadius = UDim.new(0, 8)
Corner2.Parent = TapBtn

TapBtn.MouseButton1Click:Connect(function()
    tapToMoveEnabled = not tapToMoveEnabled
    if tapToMoveEnabled then
        TapBtn.Text = "TAP TO DRIVE: ON"
        TapBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    else
        TapBtn.Text = "TAP TO DRIVE: OFF"
        TapBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        autoDriving = false
    end
end)

print("Smart Auto Drive Loaded!")
