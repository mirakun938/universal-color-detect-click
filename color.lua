local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันหาพื้นดินด้วย Raycast เพื่อกันร่วง Void หรือลอยกลางอากาศ
local function getGroundPosition(targetPos)
    -- ยิง Ray จากจุดเป้าหมายลงมาด้านล่าง 500 หน่วย
    local rayOrigin = targetPos + Vector3.new(0, 50, 0)
    local rayDirection = Vector3.new(0, -500, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = RaycastFilterType.Exclude
    
    -- ไม่ตรวจจับตัวละครผู้โดยสารและรถของผู้เล่น
    local ignoreList = {}
    if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
    local npcsFolder = Workspace:FindFirstChild("npcs")
    if npcsFolder then table.insert(ignoreList, npcsFolder) end
    
    raycastParams.FilterDescendantsInstances = ignoreList

    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult then
        -- เจอพื้นดิน! คืนค่าตำแหน่งบนพื้นดิน + ยกสูง 3 หน่วยกันจม
        return raycastResult.Position + Vector3.new(0, 3, 0)
    end
    
    -- หากยิงไม่เจอพื้นจริงๆ ให้ใช้ตำแหน่งเดิมแต่ปรับความสูงให้อยู่ระดับพื้นปกติ (ประมาณ Y = 10)
    return Vector3.new(targetPos.X, math.max(targetPos.Y, 10), targetPos.Z)
end

-- ฟังก์ชันหา CFrame ของเป้าหมายจาก Customer.location
local function getTargetCFrame()
    local npcsFolder = Workspace:FindFirstChild("npcs")
    if not npcsFolder then return nil end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc.Name == "Customer" then
            local locValue = npc:FindFirstChild("location")
            if locValue and locValue:IsA("ObjectValue") and locValue.Value then
                local targetObject = locValue.Value
                
                -- หาก Value ชี้ไปที่ Part โดยตรง
                if targetObject:IsA("BasePart") then
                    return targetObject.CFrame
                -- หาก Value ชี้ไปที่ Model ให้หา PrimaryPart หรือ Part ตัวแรกใน Model
                elseif targetObject:IsA("Model") then
                    if targetObject.PrimaryPart then
                        return targetObject.PrimaryPart.CFrame
                    else
                        local part = targetObject:FindFirstChildWhichIsA("BasePart", true)
                        if part then return part.CFrame end
                    end
                    return targetObject:GetPivot()
                end
            end
        end
    end
    return nil
end

-- ฟังก์ชันวาร์ปรถ/ตัวละคร
local function safeTPToLocation()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local seat = humanoid and humanoid.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    
    local targetPivot = vehicle or character
    local targetCFrame = getTargetCFrame()
    
    if targetCFrame then
        -- หาตำแหน่งพื้นดินจริงก่อนวาร์ป
        local groundPos = getGroundPosition(targetCFrame.Position)
        local safeCFrame = CFrame.new(groundPos) * (targetCFrame - targetCFrame.Position)
        
        targetPivot:PivotTo(safeCFrame)
        print("วาร์ปลงพื้นดินเรียบร้อยแล้ว!")
    else
        warn("ไม่พบตำแหน่งเป้าหมาย หรือไม่ได้อุ้ม/รับ Customer อยู่")
    end
end

-- สร้าง UI Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "SafeLocationTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "SafeTPButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Safe TP to Location"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    safeTPToLocation()
end)

print("Safe Location TP Loaded!")
