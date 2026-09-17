local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local aiFolder = Workspace:WaitForChild("ai", 10)

-- ตั้งค่า Silent Aim
local FOV_RADIUS = 150 -- ระยะวงเป้าล็อก (พิกเซลบนหน้าจอมือถือ)
local TARGET_PART = "Head" -- ล็อกเป้าที่หัว

-- ค้นหา AI ที่ใกล้จุดศูนย์กลางหน้าจอที่สุด
local function getClosestAI()
    local closestTarget = nil
    local shortestDistance = FOV_RADIUS
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if not aiFolder then return nil end

    for _, model in ipairs(aiFolder:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local targetPart = model:FindFirstChild(TARGET_PART) or model:FindFirstChild("HumanoidRootPart")

            -- เช็คว่า AI ยังมีชีวิตอยู่
            if targetPart and (not humanoid or humanoid.Health > 0) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen then
                    local mouseDistance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if mouseDistance < shortestDistance then
                        shortestDistance = mouseDistance
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    return closestTarget
end

-- Hook การล็อกเป้า (Raycast / Mouse Target)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and (method == "Raycast" or method == "FindPartOnWithIgnoreList" or method == "findPartOnWithIgnoreList") then
        local target = getClosestAI()
        if target then
            -- ปรับทิศทางกระสุนพุ่งตรงเข้าหัว AI เป้าหมายทันที
            if method == "Raycast" and args[1] and args[2] then
                local origin = args[1]
                args[2] = (target.Position - origin).Unit * 1000
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

-- Hook ตำแหน่ง CFrame ของกล้อง/เมาส์ (สำหรับปืนที่ใช้ Mouse.Hit)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and self:IsA("Mouse") and (index == "Hit" or index == "Target") then
        local target = getClosestAI()
        if target then
            if index == "Hit" then
                return target.CFrame
            elseif index == "Target" then
                return target
            end
        end
    end
    return oldIndex(self, index)
end)

print("Mobile Silent Aim Loaded Successfully!")
