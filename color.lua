local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันค้นหาเป้าหมายจาก Value ในตัว Customer NPC
local function getTargetCFrame()
    local npcsFolder = Workspace:FindFirstChild("npcs")
    if not npcsFolder then return nil end

    -- ค้นหา NPC ในโฟลเดอร์ npcs
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc.Name == "Customer" then
            local locValue = npc:FindFirstChild("location")
            if locValue and locValue:IsA("ObjectValue") and locValue.Value then
                local targetObject = locValue.Value
                if targetObject:IsA("BasePart") then
                    return targetObject.CFrame
                elseif targetObject:IsA("Model") then
                    return targetObject:GetPivot()
                end
            end
        end
    end
    return nil
end

-- ฟังก์ชันวาร์ปรถไปยังตำแหน่งเป้าหมาย
local function tpVehicleToLocation()
    local character = LocalPlayer.Character
    if not character then 
        warn("ไม่พบตัวละคร")
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local seat = humanoid and humanoid.SeatPart
    local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
    
    -- หากไม่ได้นั่งบนรถ จะวาร์ปตัวละครแทน
    local targetPivot = vehicle or character
    
    local targetCFrame = getTargetCFrame()
    if targetCFrame then
        -- วาร์ปไปที่ตำแหน่งเป้าหมาย (ยกสูงขึ้นเล็กน้อย +3 กันจมดิน)
        targetPivot:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
        print("วาร์ปไปยังเป้าหมายสำเร็จ!")
    else
        warn("ไม่พบ ObjectValue 'location' หรือยังไม่ได้รับผู้โดยสาร")
    end
end

-- สร้างปุ่มกดบนหน้าจอ
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "DirectLocationTPGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "TPButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "TP to Target Location"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    tpVehicleToLocation()
end)

print("Target Location TP Loaded!")
