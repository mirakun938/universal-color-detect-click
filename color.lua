local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ItemTeleporterUI") then
    PlayerGui.ItemTeleporterUI:Destroy()
end

-- Variables
local currentMode = "ALL"
local followConnection = nil
local currentItem = nil
local originalAnchored = false
local originalCanCollide = true

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
Title.Text = "STUCK HEAD FOLLOW (PHYSICS FIX)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
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

-- Stop Following & Restore Physics
local function stopFollow()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    
    -- คืนค่า Physics เดิมให้ไอเทม เพื่อนำไปใช้ประกอบอาหารต่อได้
    if currentItem and currentItem:IsA("BasePart") then
        currentItem.Anchored = originalAnchored
        currentItem.CanCollide = originalCanCollide
    end
    
    currentItem = nil
end

-- Attach & Force Loop Logic
local function startItemFollow()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Head = Character:FindFirstChild("Head")
    if not Head then return end

    stopFollow()

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
        local RaycastResult = workspace:Raycast(Ray.Origin, Ray.Direction * 25)

        if RaycastResult and RaycastResult.Instance then
            local hitObj = RaycastResult.Instance
            targetPart = hitObj:IsA("BasePart") and hitObj or hitObj:FindFirstAncestorOfClass("Model")
            if targetPart and targetPart:IsA("Model") then
                targetPart = targetPart.PrimaryPart or targetPart:FindFirstChildWhichIsA("BasePart")
            end
        end
    end

    -- 3. ล็อกพิกัด และปิด Physics ไม่ให้เกมดึงกลับ
    if targetPart and targetPart:IsA("BasePart") then
        currentItem = targetPart
        
        -- จำค่าเดิมไว้
        originalAnchored = targetPart.Anchored
        originalCanCollide = targetPart.CanCollide
        
        -- ปรับตั้งค่ากันเกมดึงหลุด
        targetPart.Anchored = true
        targetPart.CanCollide = false

        -- บังคับอัปเดตตำแหน่งตามหัวทุกเฟรม
        followConnection = RunService.Heartbeat:Connect(function()
            if currentItem and currentItem.Parent and Character:FindFirstChild("Head") then
                currentItem.CFrame = Head.CFrame * CFrame.new(0, 2.8, 0)
            else
                stopFollow()
            end
        end)
    end
end

-- UI Buttons
local attachBtn = createButton("FORCE HEAD FOLLOW", Color3.fromRGB(45, 90, 225), Scroll)
local releaseBtn = createButton("RELEASE ITEM", Color3.fromRGB(200, 60, 60), Scroll)
local modeBtn = createButton("MODE: ALL (TARGET + HELD)", Color3.fromRGB(120, 60, 180), Scroll)
local extToggleBtn = createButton("EXTERNAL BUTTONS: ON", Color3.fromRGB(180, 45, 50), Scroll)

-- Quick External Buttons
local quickAttach = createButton("HEAD", Color3.fromRGB(45, 90, 225), QuickFrame, UDim2.new(0, 45, 0, 45))
local quickRelease = createButton("REL", Color3.fromRGB(200, 60, 60), QuickFrame, UDim2.new(0, 45, 0, 45))
quickAttach.UICorner.CornerRadius = UDim.new(1, 0)
quickRelease.UICorner.CornerRadius = UDim.new(1, 0)

-- Toggle Main UI Button
local ToggleMainBtn = createButton("UI", Color3.fromRGB(20, 20, 25), ScreenGui, UDim2.new(0, 40, 0, 40))
ToggleMainBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleMainBtn.UICorner.CornerRadius = UDim.new(0, 10)

-- Events
attachBtn.MouseButton1Click:Connect(startItemFollow)
quickAttach.MouseButton1Click:Connect(startItemFollow)

releaseBtn.MouseButton1Click:Connect(stopFollow)
quickRelease.MouseButton1Click:Connect(stopFollow)

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
