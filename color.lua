local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ItemTeleporterUI") then
    PlayerGui.ItemTeleporterUI:Destroy()
end

-- Variables
local currentMode = "ALL" -- "ALL" หรือ "HELD"
local tetherConnection = nil
local activeBeam = nil
local activeAttachment0 = nil
local activeAttachment1 = nil
local currentTargetPart = nil

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ItemTeleporterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 360)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -180)
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
Title.Text = "ITEM LINE TETHER & MAGNET"
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
Scroll.CanvasSize = UDim2.new(0, 0, 0, 320)
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Scroll

-- Quick External Buttons Frame
local QuickFrame = Instance.new("Frame")
QuickFrame.Size = UDim2.new(0, 110, 0, 50)
QuickFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
QuickFrame.BackgroundTransparency = 1
QuickFrame.Parent = ScreenGui

local QuickLayout = Instance.new("UIListLayout")
QuickLayout.FillDirection = Enum.FillDirection.Horizontal
QuickLayout.Padding = UDim.new(0, 8)
QuickLayout.Parent = QuickFrame

-- Helper UI Function
local function createButton(text, bgColor, parent, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0.95, 0, 0, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    return btn
end

-- Clear Tether / Magnet Line
local function clearTether()
    if tetherConnection then
        tetherConnection:Disconnect()
        tetherConnection = nil
    end
    if activeBeam then activeBeam:Destroy() activeBeam = nil end
    if activeAttachment0 then activeAttachment0:Destroy() activeAttachment0 = nil end
    if activeAttachment1 then activeAttachment1:Destroy() activeAttachment1 = nil end
    currentTargetPart = nil
end

-- Start Tether / Magnet Pull
local function startTether()
    local Character = LocalPlayer.Character
    if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    clearTether()

    local targetPart = nil

    -- 1. เช็คของในมือ
    local HeldTool = Character:FindFirstChildOfClass("Tool")
    if HeldTool then
        targetPart = HeldTool:FindFirstChild("Handle") or HeldTool:FindFirstChildWhichIsA("BasePart")
    end

    -- 2. เช็คของกลางจอ (Mode ALL)
    if not targetPart and currentMode == "ALL" then
        local Camera = workspace.CurrentCamera
        local Ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local RaycastResult = workspace:Raycast(Ray.Origin, Ray.Direction * 30)

        if RaycastResult and RaycastResult.Instance then
            local hitObj = RaycastResult.Instance
            targetPart = hitObj:IsA("BasePart") and hitObj or hitObj:FindFirstAncestorOfClass("Model")
            if targetPart and targetPart:IsA("Model") then
                targetPart = targetPart.PrimaryPart or targetPart:FindFirstChildWhichIsA("BasePart")
            end
        end
    end

    if targetPart and targetPart:IsA("BasePart") then
        currentTargetPart = targetPart

        -- สร้างจุดยึด Attachment
        activeAttachment0 = Instance.new("Attachment", HumanoidRootPart)
        activeAttachment1 = Instance.new("Attachment", targetPart)

        -- สร้างเส้นโยง Beam
        activeBeam = Instance.new("Beam")
        activeBeam.Attachment0 = activeAttachment0
        activeBeam.Attachment1 = activeAttachment1
        activeBeam.Width0 = 0.2
        activeBeam.Width1 = 0.2
        activeBeam.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255))
        activeBeam.FaceCamera = true
        activeBeam.Parent = HumanoidRootPart

        -- ลูปใช้ฟิสิกส์แม่เหล็กดูดไอเทมเข้ามาหาตัวละคร
        tetherConnection = RunService.Heartbeat:Connect(function()
            if currentTargetPart and currentTargetPart.Parent and HumanoidRootPart then
                local goalPosition = HumanoidRootPart.CFrame * CFrame.new(0, 1, -3) -- ให้ของลอยอยู่หน้าเราเล็กน้อย
                currentTargetPart.CFrame = currentTargetPart.CFrame:Lerp(goalPosition, 0.25)
            else
                clearTether()
            end
        end)
    end
end

-- UI Buttons
local attachBtn = createButton("TETHER / MAGNET ITEM", Color3.fromRGB(45, 90, 225), Scroll)
local releaseBtn = createButton("RELEASE TETHER", Color3.fromRGB(200, 60, 60), Scroll)
local modeBtn = createButton("MODE: ALL (TARGET + HELD)", Color3.fromRGB(120, 60, 180), Scroll)
local extToggleBtn = createButton("EXTERNAL BUTTONS: ON", Color3.fromRGB(180, 45, 50), Scroll)

-- Quick External Buttons
local quickAttach = createButton("MAG", Color3.fromRGB(45, 90, 225), QuickFrame, UDim2.new(0, 45, 0, 45))
local quickRelease = createButton("REL", Color3.fromRGB(200, 60, 60), QuickFrame, UDim2.new(0, 45, 0, 45))
quickAttach.UICorner.CornerRadius = UDim.new(1, 0)
quickRelease.UICorner.CornerRadius = UDim.new(1, 0)

-- Toggle Main UI Button
local ToggleMainBtn = createButton("UI", Color3.fromRGB(20, 20, 25), ScreenGui, UDim2.new(0, 40, 0, 40))
ToggleMainBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleMainBtn.UICorner.CornerRadius = UDim.new(0, 10)

-- Events
attachBtn.MouseButton1Click:Connect(startTether)
quickAttach.MouseButton1Click:Connect(startTether)

releaseBtn.MouseButton1Click:Connect(clearTether)
quickRelease.MouseButton1Click:Connect(clearTether)

modeBtn.MouseButton1Click:Connect(function()
    if currentMode == "ALL" then
        currentMode = "HELD"
        modeBtn.Text = "MODE: HELD ITEM ONLY"
        modeBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
    else
        currentMode = "ALL"
        modeBtn.Text = "MODE: ALL (TARGET + HELD)"
        modeBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
    end
end)

local extVisible = true
extToggleBtn.MouseButton1Click:Connect(function()
    extVisible = not extVisible
    QuickFrame.Visible = extVisible
    extToggleBtn.Text = "EXTERNAL BUTTONS: " .. (extVisible and "ON" or "OFF")
    extToggleBtn.BackgroundColor3 = extVisible and Color3.fromRGB(180, 45, 50) or Color3.fromRGB(80, 80, 85)
end)

ToggleMainBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
