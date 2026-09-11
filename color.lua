local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ตั้งค่า Auto Block
local autoBlockPlayer = true
local autoBlockNPC = true
local maxBlockDistance = 12
local isBlocking = false
local lastBlockTime = 0
local blockCooldown = 0.5 -- เว้นระยะการกดบล็อกอย่างน้อย 0.5 วินาที

-- ฟังก์ชันกดบล็อกแบบปลอดภัย (Safe Block Input)
local function executeSafeBlock()
    local currentTime = tick()
    if isBlocking or (currentTime - lastBlockTime) < blockCooldown then return end
    
    isBlocking = true
    lastBlockTime = currentTime

    -- วิธีที่ 1: จำลองการกดปุ่ม UI บล็อกบนหน้าจอ (สำหรับ Mobile UI ที่เห็นในวิดีโอ)
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local blockBtn = playerGui and playerGui:FindFirstChild("MobileButtons") and playerGui.MobileButtons:FindFirstChild("Block")
        if blockBtn then
            local pos = blockBtn.AbsolutePosition
            local size = blockBtn.AbsoluteSize
            local clickX = pos.X + (size.X / 2)
            local clickY = pos.Y + (size.Y / 2) + 36 -- ชดเชยระยะ Topbar

            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
        end
    end)

    -- วิธีที่ 2: จำลองการกดปุ่ม F (Keyboard Input)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)

    task.wait(0.3)
    isBlocking = false
end

local function getHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
end

-- ตรวจสอบ Animation การโจมตี
local function checkTarget(char)
    if not char or isBlocking then return end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not myHRP or not targetHRP or not humanoid then return end

    local distance = (myHRP.Position - targetHRP.Position).Magnitude
    if distance > maxBlockDistance then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local animName = string.lower(track.Name)

        -- ท่า Heavy (ง้างช้า)
        if string.find(animName, "heavy") then
            task.delay(0.2, function()
                if not isBlocking and getHRP(char) and (myHRP.Position - getHRP(char).Position).Magnitude <= maxBlockDistance then
                    executeSafeBlock()
                end
            end)
            break
            
        -- ท่า Swing หรือ Attack ปกติ
        elseif string.find(animName, "swing") or string.find(animName, "attack") or track.Priority == Enum.AnimationPriority.Action then
            executeSafeBlock()
            break
        end
    end
end

-- ลูปตรวจจับแบบประหยัด Resource (รันทุกๆ 0.05 วินาที แทนที่จะเป็นทุกเฟรม)
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if autoBlockPlayer then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        checkTarget(player.Character)
                    end
                end
            end

            if autoBlockNPC then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj:FindFirstChildOfClass("Humanoid") then
                        checkTarget(obj)
                    end
                end
            end
        end)
    end
end)

print("Safe Auto Block Loaded!")
