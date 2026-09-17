local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local aiFolder = Workspace:WaitForChild("ai", 10)

-- ตั้งค่า Silent Aim
local FOV_RADIUS = 300 -- ระยะวงเป้าล็อกบนหน้าจอมือถือ (ยิ่งเยอะยิ่งล็อกง่าย)
local TARGET_PART = "Head" -- ล็อกเป้าที่หัว

-- ฟังก์ชันค้นหาหัว AI ที่ใกล้ศูนย์กลางหน้าจอที่สุด และยังมีชีวิตอยู่
local function getClosestZombieHead()
    local closestHead = nil
    local shortestDistance = FOV_RADIUS
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if not aiFolder then return nil end

    for _, model in ipairs(aiFolder:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local head = model:FindFirstChild(TARGET_PART) or model:FindFirstChild("HumanoidRootPart")

            -- เช็คว่ามีหัว และ AI เลือดมากกว่า 0 (ยังไม่ตาย)
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

-- Hook RemoteEvent:FireServer สำหรับระบบปืน
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and (method == "FireServer" or method == "fireServer") then
        local targetHead = getClosestZombieHead()
        
        if targetHead then
            -- แอบดึงตำแหน่ง Vector3 หรือ CFrame ใน Argument ของ Remote ปืน แล้วแก้เป็นตำแหน่งหัว AI
            for i, arg in ipairs(args) do
                if typeof(arg) == "Vector3" then
                    args[i] = targetHead.Position
                elseif typeof(arg) == "CFrame" then
                    args[i] = targetHead.CFrame
                elseif type(arg) == "table" then
                    for k, v in pairs(arg) do
                        if typeof(v) == "Vector3" then
                            arg[k] = targetHead.Position
                        elseif typeof(v) == "CFrame" then
                            arg[k] = targetHead.CFrame
                        end
                    end
                end
            end
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

print("Universal Remote Silent Aim Loaded!")
