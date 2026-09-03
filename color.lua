-- [[ AUTO FISHING & SKILL CHECK (FIXED VERSION) ]] --
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

-- ฟังก์ชันยิงคลิกปุ่ม
local function clickGuiObject(btn)
    if not btn then return end
    local guiInset = GuiService:GetGuiInset()
    local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
    local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + guiInset.Y

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.005)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin, Vector3.new(x, y, 0), game)
    task.wait(0.005)
    VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End, Vector3.new(x, y, 0), game)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local minigameGui = playerGui:FindFirstChild("FishingMinigameGui")
        
        -- 🎯 1. ถ้ามินิเกมเปิดอยู่ ให้คุมหลอดซ้าย-ขวา และ กด SHAKE ทันที (ให้ความสำคัญอันดับ 1)
        if minigameGui and minigameGui.Enabled then
            local root = minigameGui:FindFirstChild("Root")
            if root and root.Visible then
                
                -- 1.1 เช็กและกดปุ่ม SHAKE
                local qteBounds = root:FindFirstChild("QTEBounds")
                if qteBounds and qteBounds.Visible then
                    local shakeBtn = qteBounds:FindFirstChildWhichIsA("GuiObject", true)
                    if shakeBtn and shakeBtn.Visible then
                        statusLabel.Text = "⚡ กด SHAKE อัตโนมัติ!"
                        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
                        clickGuiObject(shakeBtn)
                    end
                end

                -- 1.2 เช็กตำแหน่งหลอดสีเขียว (SafeZone) และ ปลา (Marker)
                local trackContainer = root:FindFirstChild("TrackContainer") or root:FindFirstChild("Track") or root
                local safeZone = trackContainer:FindFirstChild("SafeZone", true)
                local marker = trackContainer:FindFirstChild("Marker", true)
                local controls = root:FindFirstChild("ControlsFrame")

                if safeZone and marker and controls then
                    local leftBtn = controls:FindFirstChild("LeftButton")
                    local rightBtn = controls:FindFirstChild("RightButton")

                    -- คำนวณจุดศูนย์กลางบนหน้าจอจริง
                    local fishX = marker.AbsolutePosition.X + (marker.AbsoluteSize.X / 2)
                    local safeCenterX = safeZone.AbsolutePosition.X + (safeZone.AbsoluteSize.X / 2)

                    local diff = fishX - safeCenterX

                    if math.abs(diff) <= 15 then
                        statusLabel.Text = "🎯 หลอดครอบตัวปลาอยู่"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif diff > 15 and rightBtn then
                        statusLabel.Text = "➡️ กดปุ่มขวา"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                        clickGuiObject(rightBtn)
                    elseif diff < -15 and leftBtn then
                        statusLabel.Text = "⬅️ กดปุ่มซ้าย"
                        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                        clickGuiObject(leftBtn)
                    end
                end
                return -- จบการทำงานเฟรมนี้ ถ้าเล่นมินิเกมอยู่
            end
        end

        -- 🎣 2. เช็กปุ่ม ReelIn (ทำเฉพาะตอนที่ไม่ได้เล่นมินิเกม)
        local fishingGui = playerGui:FindFirstChild("FishingGui")
        if fishingGui then
            local reelIn = fishingGui:FindFirstChild("ReelIn")
            if reelIn and reelIn.Visible then
                statusLabel.Text = "🎣 กด Reel In!"
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                clickGuiObject(reelIn)
                return
            end
        end

        statusLabel.Text = "⏳ รอเริ่มมินิเกม..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end)
end)
