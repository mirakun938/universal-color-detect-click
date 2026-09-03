local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ลบ UI เก่าออกหากเคยรันไว้
if PlayerGui:FindFirstChild("ItemTP_UI") then
    PlayerGui.ItemTP_UI:Destroy()
end

local targetCFrame = nil

-- Create UI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ItemTP_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Position = UDim2.new(0.05, 0, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.Active = true
Frame.Draggable = true -- สามารถลาก UI ไปมาได้
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Item Teleporter UI"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Parent = Frame

-- ปุ่ม 1: ตั้งค่าจุด Teleport
local SetPosBtn = Instance.new("TextButton")
SetPosBtn.Size = UDim2.new(0.9, 0, 0, 30)
SetPosBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
SetPosBtn.Text = "Set TP Position"
SetPosBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SetPosBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetPosBtn.Parent = Frame

-- ปุ่ม 2: วาร์ปไอเทมไปจุดที่ตั้งไว้
local BringBtn = Instance.new("TextButton")
BringBtn.Size = UDim2.new(0.9, 0, 0, 30)
BringBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
BringBtn.Text = "Teleport Item Here"
BringBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
BringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BringBtn.Parent = Frame

-- Logic การทำงาน
SetPosBtn.MouseButton1Click:Connect(function()
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        targetCFrame = Character.HumanoidRootPart.CFrame
        SetPosBtn.Text = "Position Set!"
        task.wait(1)
        SetPosBtn.Text = "Set TP Position"
    end
end)

BringBtn.MouseButton1Click:Connect(function()
    if not targetCFrame then
        BringBtn.Text = "Please Set Pos First!"
        task.wait(1)
        BringBtn.Text = "Teleport Item Here"
        return
    end

    local Character = LocalPlayer.Character
    if not Character then return end

    -- 1. เช็คกรณีถือไอเทมอยู่ในมือ (Tool)
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        local Handle = Tool:FindFirstChild("Handle") or Tool:FindFirstChildWhichIsA("BasePart")
        if Handle then
            Handle.CFrame = targetCFrame
        else
            Tool:ScaleTo(1) -- Refresh model position if needed
        end
        return
    end

    -- 2. เช็คกรณีไอเทมลอยอยู่ตรงกลางจอ (ใช้ Raycast ค้นหาไอเทมที่มองอยู่)
    local Camera = workspace.CurrentCamera
    local Ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local RaycastResult = workspace:Raycast(Ray.Origin, Ray.Direction * 20)

    if RaycastResult and RaycastResult.Instance then
        local hitObj = RaycastResult.Instance
        local targetModel = hitObj:FindFirstAncestorOfClass("Model") or hitObj
        
        if targetModel:IsA("BasePart") then
            targetModel.CFrame = targetCFrame
        elseif targetModel:IsA("Model") then
            targetModel:PivotTo(targetCFrame)
        end
    end
end)
