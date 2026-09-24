local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันค้นหาจุดส่งใน Workspace.locations
local function getTargetLocation()
    local locationsFolder = Workspace:FindFirstChild("locations")
    if not locationsFolder then return nil end

    -- อ่านชื่อจาก UI ถ้ามี
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

    -- แมตช์ชื่อสถานที่กับ Object ใน locations
    if targetName then
        local cleanTarget = string.lower(targetName)
        for _, child in ipairs(locationsFolder:GetChildren()) do
            if string.find(string.lower(child.Name), cleanTarget) or string.find(cleanTarget, string.lower(child.Name)) then
                return child
            end
        end
    end

    -- ถ้าหาชื่อไม่เจอ คืนค่าสถานที่แรกในโฟลเดอร์มาใช้
    return locationsFolder:GetChildren()[1]
end

-- ฟังก์ชันส่งงานแบบ Force Touch + Fire Remote
local function forceCompleteDelivery()
    local char = LocalPlayer.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    
    local targetObj = getTargetLocation()
    
    if targetObj then
        -- หา BasePart สำหรับจำลองการแตะ (Touch)
        local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
        
        if targetPart and rootPart then
            -- 1. วาร์ประยะประชิดไปที่จุดส่ง
            local tpTarget = vehicle or char
            tpTarget:PivotTo(targetPart.CFrame + Vector3.new(0, 2, 0))
            
            -- 2. จำลองการแตะโซนส่ง (Touch Simulation)
            if firetouchinterest then
                firetouchinterest(rootPart, targetPart, 0)
                task.wait(0.1)
                firetouchinterest(rootPart, targetPart, 1)
                
                if seat then
                    firetouchinterest(seat, targetPart, 0)
                    task.wait(0.1)
                    firetouchinterest(seat, targetPart, 1)
                end
            end
            print("จำลองการแตะจุดส่งสำเร็จ:", targetObj.Name)
        end
    end

    -- 3. ยิง Remote Event ยืนยันการส่งงานทั้งหมด
    local remotes = {"deliveryfinserv", "deliveryfin", "delinterrupt"}
    for _, remoteName in ipairs(remotes) do
        local remote = ReplicatedStorage:FindFirstChild(remoteName, true) or Workspace:FindFirstChild(remoteName, true)
        if remote and remote:IsA("RemoteEvent") then
            if targetObj then
                remote:FireServer(targetObj.Name)
                remote:FireServer(targetObj)
            end
            remote:FireServer()
        end
    end
end

-- สร้าง UI Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "ForceDeliveryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ForceBtn"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 30, 60)
ToggleButton.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleButton.Size = UDim2.new(0, 170, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "FORCE FINISH (TOUCH)"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    forceCompleteDelivery()
end)

print("Force Touch Delivery Loaded!")
