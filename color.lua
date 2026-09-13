local ReplicatedStorage = game:GetService("ReplicatedStorage")
local qteRemote = ReplicatedStorage:FindFirstChild("Animations") and ReplicatedStorage.Animations:FindFirstChild("QTE") 
                  or ReplicatedStorage:FindFirstChild("QTE", true)

-- 1. Hook Remote Event (บังคับให้ Client ส่งค่า True เสมอ)
if qteRemote and qteRemote:IsA("RemoteEvent") then
    local oldFireServer
    oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if self == qteRemote and (method == "FireServer" or method == "fireServer") then
            -- บังคับเปลี่ยน Argument เป็น true ทุกครั้งที่ยิง Event
            return oldFireServer(self, true)
        end

        return oldFireServer(self, ...)
    end)
end

-- 2. Hook ModuleScript QTEHandler (ถ้า Executor รองรับ require/hookfunction)
pcall(function()
    local qteHandlerModule = ReplicatedStorage:FindFirstChild("QTEHandler", true)
    if qteHandlerModule and getloadedmodules then
        for _, module in ipairs(getloadedmodules()) do
            if module == qteHandlerModule or module.Name == "QTEHandler" then
                local succ, table = pcall(require, module)
                if succ and type(table) == "table" then
                    -- ปรับเปลี่ยนฟังก์ชันภายในให้ตอบกลับเป็น Win/Success 100%
                    for key, val in pairs(table) do
                        if type(val) == "function" then
                            table[key] = function(...)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 3. Auto Response เมื่อได้รับการแจ้งเตือน QTE จากเซิร์ฟเวอร์
if qteRemote then
    qteRemote.OnClientEvent:Connect(function(...)
        task.wait(0.05)
        qteRemote:FireServer(true)
    end)
end

print("100% Guaranteed QTE Win Loaded!")
