-- [[ AUTO FISHING & SKILL CHECK (DIRECT EVENT FIX) ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- หน้าจอแสดงสถานะ
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "AutoFishingStatus"
statusGui.ResetOnSpawn = false

pcall(function() statusGui.Parent = CoreGui end)
if not statusGui.Parent then statusGui.Parent = playerGui end

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusGui
statusLabel.Size = UDim2.new(0, 280, 0, 40)
statusLabel.Position = UDim2.new(0.5, -140, 0.05, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "🎣 ระบบทำงาน..."
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)

-- ฟังก์ชันกดปุ่มแบบผสม (ยิง Direct Signal + Virtual Click)
local function triggerButton(btn)
    if not btn then return end
    
    -- 1. ยิง Signal ของ Roblox UI ตรงๆ
    pcall(function()
        for _, connection in pairs(getconnections(btn.Activated)) do connection:Fire() end
        for _, connection in pairs(getconnections(btn.MouseButton1Click)) do connection:Fire() end
        for _, connection in pairs(getconnections(btn.MouseButton1Down)) do connection:Fire() end
    end)

    -- 2. ยิง Touch Event
    local guiInset = GuiService:GetGuiInset()
    local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
    local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + guiInset.Y

    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
    task.wait(0.005)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(x, y, 0), game)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local minigameGui = playerGui:FindFirstChild("FishingMinigameGui")
        
        -- 🎯 1. ทำงานมินิเกมเลื่อนหลอด + Shake (เมื่อมินิเกมเปิด)
        if minigameGui and minigameGui.Enabled then
            local root = minigameGui:FindFirstChild("Root")
            if root and root.Visible then
                
                -- 1.1 เช็กกด Shake
                local qteBounds = root:FindFirstChild("QTEBounds")
                if qteBounds and qteBounds.Visible then
                    for _, child in pairs(qteBounds:GetChildren()) do
                        if child:IsA("GuiObject") and child.Visible then
                            statusLabel.Text = "⚡ กด SHAKE!"
                            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
                            triggerButton(child)
                        end
                    end
                end

                -- 1.2 เช็กคุมหลอดซ้าย-ขวา
                local controls = root:FindFirstChild("ControlsFrame")
                local trackContainer = root:FindFirstChild("TrackContainer") or root:FindFirstChild("Track") or root
                local safeZone = trackContainer:FindFirstChild("SafeZone", true)
                local marker = trackContainer:FindFirstChild("Marker", true)

                if safeZone and marker and controls then
                    local leftBtn = controls:FindFirstChild("LeftButton")
                    local rightBtn = controls:FindFirstChild("RightButton")

                    local fishX = marker.AbsolutePosition.X + (marker.AbsoluteSize.X / 2)
                    local safeCenterX = safeZone.AbsolutePosition.X + (safeZone.AbsoluteSize.X / 2)
                    local diff = fishX - safeCenterX

                    if math.abs(diff) <= 12 then
                        statusLabel.Text = "🎯 หลอดตรงตัวปลา"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif diff > 12 and rightBtn then
                        statusLabel.Text = "➡️ เลื่อนขวา"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                        triggerButton(rightBtn)
                    elseif diff < -12 and leftBtn then
                        statusLabel.Text = "⬅️ เลื่อนซ้าย"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                        triggerButton(leftBtn)
                    end
                end
                return
            end
        end

        -- 🎣 2. เช็กปุ่ม ReelIn
        local fishingGui = playerGui:FindFirstChild("FishingGui")
        if fishingGui then
            local reelIn = fishingGui:FindFirstChild("ReelIn")
            if reelIn and reelIn.Visible then
                statusLabel.Text = "🎣 กด Reel In!"
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                
                -- เช็กกดปุ่ม TextLabel หรือ ReelIn Frame
                triggerButton(reelIn)
                local textLabel = reelIn:FindFirstChildOfClass("TextLabel")
                if textLabel then triggerButton(textLabel) end
            else
                statusLabel.Text = "⏳ รอเริ่มมินิเกม..."
                statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
end)
