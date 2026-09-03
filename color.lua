local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ItemTeleporterUI") then
    PlayerGui.ItemTeleporterUI:Destroy()
end

local savedPositions = {
    TP1 = nil,
    TP2 = nil,
    TP3 = nil
}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ItemTeleporterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 420)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "ITEM TELEPORT COORDINATES"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

-- Scroll Container
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -50)
Scroll.Position = UDim2.new(0, 10, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 380)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Scroll

-- Quick Buttons Frame (External Circle Buttons)
local QuickFrame = Instance.new("Frame")
QuickFrame.Size = UDim2.new(0, 150, 0, 50)
QuickFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
QuickFrame.BackgroundTransparency = 1
QuickFrame.Parent = ScreenGui

local QuickLayout = Instance.new("UIListLayout")
QuickLayout.FillDirection = Enum.FillDirection.Horizontal
QuickLayout.Padding = UDim.new(0, 8)
QuickLayout.Parent = QuickFrame

-- Helper UI Functions
local function createButton(text, bgColor, parent, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0.95, 0, 0, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 15
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

-- Teleport Action Logic
local function teleportItemTo(cframe)
    if not cframe then return end
    local Character = LocalPlayer.Character
    if not Character then return end

    -- 1. Check Held Tool
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        local Handle = Tool:FindFirstChild("Handle") or Tool:FindFirstChildWhichIsA("BasePart")
        if Handle then
            Handle.CFrame = cframe
        else
            Tool:PivotTo(cframe)
        end
        return
    end

    -- 2. Raycast Target Item in Screen Center
    local Camera = workspace.CurrentCamera
    local Ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local RaycastResult = workspace:Raycast(Ray.Origin, Ray.Direction * 25)

    if RaycastResult and RaycastResult.Instance then
        local hitObj = RaycastResult.Instance
        local targetModel = hitObj:FindFirstAncestorOfClass("Model") or hitObj
        
        if targetModel:IsA("BasePart") then
            targetModel.CFrame = cframe
        elseif targetModel:IsA("Model") then
            targetModel:PivotTo(cframe)
        end
    end
end

-- Create Main UI Buttons
local tp1 = createButton("TP 1", Color3.fromRGB(45, 90, 225), Scroll)
local tp2 = createButton("TP 2", Color3.fromRGB(45, 90, 225), Scroll)
local tp3 = createButton("TP 3", Color3.fromRGB(45, 90, 225), Scroll)

local swp1 = createButton("SWP 1 (Save Pos)", Color3.fromRGB(40, 160, 90), Scroll)
local swp2 = createButton("SWP 2 (Save Pos)", Color3.fromRGB(40, 160, 90), Scroll)
local swp3 = createButton("SWP 3 (Save Pos)", Color3.fromRGB(40, 160, 90), Scroll)

local extToggleBtn = createButton("EXTERNAL BUTTONS: ON", Color3.fromRGB(180, 45, 50), Scroll)

-- Create Quick Circle Buttons
local q1 = createButton("TP1", Color3.fromRGB(45, 90, 225), QuickFrame, UDim2.new(0, 42, 0, 42))
local q2 = createButton("TP2", Color3.fromRGB(45, 90, 225), QuickFrame, UDim2.new(0, 42, 0, 42))
local q3 = createButton("TP3", Color3.fromRGB(45, 90, 225), QuickFrame, UDim2.new(0, 42, 0, 42))
q1.UICorner.CornerRadius = UDim.new(1, 0)
q2.UICorner.CornerRadius = UDim.new(1, 0)
q3.UICorner.CornerRadius = UDim.new(1, 0)

-- Toggle Main UI Button (Top-Left Logo Button)
local ToggleMainBtn = createButton("UI", Color3.fromRGB(20, 20, 25), ScreenGui, UDim2.new(0, 40, 0, 40))
ToggleMainBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleMainBtn.UICorner.CornerRadius = UDim.new(0, 10)

-- Button Connections
local function savePos(key, btn)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        savedPositions[key] = Character.HumanoidRootPart.CFrame
        local oldText = btn.Text
        btn.Text = key .. " Saved!"
        task.wait(0.8)
        btn.Text = oldText
    end
end

swp1.MouseButton1Click:Connect(function() savePos("TP1", swp1) end)
swp2.MouseButton1Click:Connect(function() savePos("TP2", swp2) end)
swp3.MouseButton1Click:Connect(function() savePos("TP3", swp3) end)

tp1.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP1) end)
tp2.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP2) end)
tp3.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP3) end)

q1.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP1) end)
q2.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP2) end)
q3.MouseButton1Click:Connect(function() teleportItemTo(savedPositions.TP3) end)

-- Toggle External Quick Buttons
local extVisible = true
extToggleBtn.MouseButton1Click:Connect(function()
    extVisible = not extVisible
    QuickFrame.Visible = extVisible
    extToggleBtn.Text = "EXTERNAL BUTTONS: " .. (extVisible and "ON" or "OFF")
    extToggleBtn.BackgroundColor3 = extVisible and Color3.fromRGB(180, 45, 50) or Color3.fromRGB(80, 80, 85)
end)

-- Toggle Main UI Window
ToggleMainBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
