local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local locationsFolder = Workspace:WaitForChild("locations", 5)

local function getDeliveryRemote()
    return ReplicatedStorage:FindFirstChild("deliveryfinserv", true)
        or ReplicatedStorage:FindFirstChild("deliveryfin", true)
        or Workspace:FindFirstChild("deliveryfinserv", true)
        or Workspace:FindFirstChild("deliveryfin", true)
end

local function getCurrentTargetName()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end
    
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local text = desc.Text
                    if string.find(string.lower(text), "go to ") then
                        return string.gsub(text, "[Gg][Oo] [Tt][Oo] ", "")
                    end
                end
            end
        end
    end
    return nil
end

local function getMatchedLocationName(targetName)
    if not locationsFolder or not targetName then return targetName end
    
    local cleanTarget = string.lower(targetName)
    for _, child in ipairs(locationsFolder:GetChildren()) do
        if string.lower(child.Name) == cleanTarget or string.find(cleanTarget, string.lower(child.Name)) then
            return child.Name -- ส่งชื่อจริงๆ ใน locations กลับไป
        end
    end
    return targetName
end

local function sendRemoteDelivery()
    local remote = getDeliveryRemote()
    if not remote then return end

    local rawName = getCurrentTargetName()
    local exactLocationName = getMatchedLocationName(rawName)

    if exactLocationName then
        if remote:IsA("RemoteEvent") then
            remote:FireServer(exactLocationName)
        elseif remote:IsA("BindableEvent") then
            remote:Fire(exactLocationName)
        end
        print("ส่ง Remote สำเร็จ! สถานที่:", exactLocationName)
    end
end

-- UI Button
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "RemoteDeliveryGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "RemoteButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ToggleButton.Position = UDim2.new(0.02, 0, 0.6, 0)
ToggleButton.Size = UDim2.new(0, 160, 0, 45)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Instant Remote Finish"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.00
ToggleButton.Active = true
ToggleButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    sendRemoteDelivery()
end)
