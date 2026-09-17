local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local aiFolder = Workspace:WaitForChild("ai", 10)

-- ตั้งค่า Silent Aim & Camera Lock
local FOV_RADIUS = 500 -- รัศมีวงเป้าดักจับ (พิกเซล)
local TARGET_PART = "Head"

-- ฟังก์ชันค้นหาหัว Zombie ที่ใกล้เป้าเล็งที่สุดและยังไม่ตาย
local function getClosestZombieHead()
    local closestHead = nil
    local shortestDistance = FOV_RADIUS
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if not aiFolder then return nil end

    for _, model in ipairs(aiFolder:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local head = model:FindFirstChild(TARGET_PART) or model:FindFirstChild("HumanoidRootPart")

            -- เช็คว่า AI เลือดมากกว่า 0 (ยังไม่ตาย)
            if head and (not humanoid or humanoid.Health > 0) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestHead = head
                    end
                end
            end
        end
    end
    return closestHead
end

-- 1. Hook Camera CFrame (หลอกระบบคำนวณ Raycast / Auto Fire ของเกม)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and self == Camera and index == "CFrame" then
        local targetHead = getClosestZombieHead()
        if targetHead then
            -- ปรับมุมกล้องจำลองให้หันตรงเข้าหัว Zombie ทันทีในระดับ Script เกม
            return CFrame.new(Camera.CFrame.Position, targetHead.Position)
        end
    end
    return oldIndex(self, index)
end)

-- 2. Hook Mouse.Hit & Target (รองรับระบบกดหรือล็อกเป้าผ่าน Mouse)
local oldMouseIndex
oldMouseIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and self:IsA("Mouse") and (index == "Hit" or index == "Target") then
        local targetHead = getClosestZombieHead()
        if targetHead then
            if index == "Hit" then
                return targetHead.CFrame
            elseif index == "Target" then
                return targetHead
            end
        end
    end
    return oldIndex(self, index)
end)

print("Camera Hook Silent Aim for Auto-Shoot Loaded!")
