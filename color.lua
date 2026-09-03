local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("TeleportUI") then
    PlayerGui.TeleportUI:Destroy()
end

local savedPositions = {TP1 = nil, TP2 = nil, TP3 = nil}

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Frame (ตรงกลาง)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 420)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "TELEPORTE COORDENADAS"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Scroll Frame สำหรับปุ่มกด
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Scroll

-- External Quick Buttons Frame (ปุ่มกลมลอยด่วนด้านซ้าย)
local ExternalFrame = Instance.new("Frame")
ExternalFrame.Size = UDim2.new(0, 180, 0, 50)
ExternalFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
ExternalFrame.BackgroundTransparency = 1
ExternalFrame.Visible = false
ExternalFrame.Parent = ScreenGui

local ExtList = Instance.new("UIListLayout")
ExtList.FillDirection = Enum.FillDirection.Horizontal
ExtList.Padding = UDim.new(0, 8)
ExtList.Parent = ExternalFrame

-- Helper Functions
local function TeleportTo(pos)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") and pos then
        Character.HumanoidRootPart.CFrame = pos
    end
end

local function CreateButton(text, bgColor, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = bgColor
    btn.LayoutOrder = order
    btn.Parent = Scroll
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

-- สร้างปุ่ม TP 1, 2, 3
for i = 1, 3 do
    local tpBtn = CreateButton("TP " .. i, Color3.fromRGB(50, 95, 240), i)
    tpBtn.MouseButton1Click:Connect(function()
        if savedPositions["TP" .. i] then
            TeleportTo(savedPositions["TP" .. i])
        end
    end)
end

-- สร้างปุ่ม SWP (Gravar) 1, 2, 3
for i = 1, 3 do
    local swpBtn = CreateButton("SWP " .. i .. " (Gravar)", Color3.fromRGB(45, 165, 80), i + 3)
    swpBtn.MouseButton1Click:Connect(function()
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            savedPositions["TP" .. i] = Character.HumanoidRootPart.CFrame
            swpBtn.Text = "SWP " .. i .. " (Saved!)"
            task.wait(1)
            swpBtn.Text = "SWP " .. i .. " (Gravar)"
        end
    end)
end

-- ปุ่ม Toggle External Buttons (BOTÕES EXTERNOS)
local extBtn = CreateButton("BOTÕES EXTERNOS: OFF", Color3.fromRGB(180, 40, 40), 7)
extBtn.MouseButton1Click:Connect(function()
    ExternalFrame.Visible = not ExternalFrame.Visible
    if ExternalFrame.Visible then
        extBtn.Text = "BOTÕES EXTERNOS: ON"
        extBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else
        extBtn.Text = "BOTÕES EXTERNOS: OFF"
        extBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 85)
    end
end)

-- สร้างปุ่มกลม Quick TP (ปุ่มลอยด่วน)
for i = 1, 3 do
    local qBtn = Instance.new("TextButton")
    qBtn.Size = UDim2.new(0, 45, 0, 45)
    qBtn.Text = "TP" .. i
    qBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    qBtn.Font = Enum.Font.SourceSansBold
    qBtn.TextSize = 12
    qBtn.BackgroundColor3 = Color3.fromRGB(50, 95, 240)
    qBtn.Parent = ExternalFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- ทำเป็นทรงกลม
    corner.Parent = qBtn
    
    qBtn.MouseButton1Click:Connect(function()
        if savedPositions["TP" .. i] then
            TeleportTo(savedPositions["TP" .. i])
        end
    end)
end

Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
