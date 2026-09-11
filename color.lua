local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local autoBlockPlayer = true
local autoBlockNPC = true
local maxBlockDistance = 14
local isBlocking = false
local lastBlockTime = 0

-- ฟังก์ชันบล็อกความเร็วสูง (ยิง ClientBlock ตรงในอาวุธ + จำลองปุ่ม)
local function executePrecisionBlock()
    local currentTime = tick()
    if isBlocking or (currentTime - lastBlockTime) < 0.25 then return end
    
    isBlocking = true
    lastBlockTime = currentTime

    -- 1. เรียก ClientBlock ของอาวุธที่เราถืออยู่ (ฝั่ง Client สั่งงานทันที ไม่โดน Anti-Cheat เตะ)
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local manualFuncs = tool:FindFirstChild("ManualFunctions")
                if manualFuncs and manualFuncs:FindFirstChild("ClientBlock") then
                    manualFuncs.ClientBlock:Fire()
                end
            end
        end
    end)

    -- 2. จำลองปุ่ม UI Mobile Block
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local blockBtn = playerGui and playerGui:FindFirstChild("MobileButtons") and playerGui.MobileButtons:FindFirstChild("Block")
        if blockBtn then
            local pos = blockBtn.AbsolutePosition
            local size = blockBtn.AbsoluteSize
            VirtualInputManager:SendMouseButtonEvent(pos.X + (size.X / 2), pos.Y + (size.Y / 2) + 36, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(pos.X + (size.X / 2), pos.Y + (size.Y / 2) + 36, 0, false, game, 0)
        end
    end)

    -- 3. จำลองการกด F บน KeyBoard
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.02)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)

    task.wait(0.2)
    isBlocking = false
end

local function getHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
end

-- ระบบคำนวณความเร็ว Animation เพื่อหาจังหวะบล็อกที่แม่นยำที่สุด
local function checkTargetDynamic(char)
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

        -- ตรวจหาเฉพาะ Animation การโจมตี
        if string.find(animName, "swing") or string.find(animName, "heavy") or string.find(animName, "attack") or track.Priority == Enum.AnimationPriority.Action then
            
            -- คำนวณความเร็วของท่าโจมตี (AnimSpeed และ Length)
            local speed = track.Speed > 0 and track.Speed or 1
            local duration = track.Length / speed
            
            -- คำนวณจุด Impact (จังหวะที่อาวุธฟันมาถึงตัว)
            local delayTime = 0
            
            if string.find(animName, "heavy") then
                -- ท่า Heavy มักจะฟันโดนช่วง 60% - 70% ของเวลา Animation ทั้งหมด
                delayTime = math.clamp(duration * 0.55, 0.1, 0.6)
            else
                -- ท่า Swing ปกติ มักจะฟันโดนช่วง 20% - 35% ของ Animation
                delayTime = math.clamp(duration * 0.2, 0, 0.25)
            end

            -- ถ้าระยะเวลาหน่วงสั้นมาก ให้บล็อกทันที
            if delayTime <= 0.03 then
                executePrecisionBlock()
            else
                -- ถ้าง้างช้า ให้รอตามระยะเวลาจริงแล้วค่อยกดบล็อก
                task.delay(delayTime, function()
                    if not isBlocking and getHRP(char) and (myHRP.Position - getHRP(char).Position).Magnitude <= maxBlockDistance then
                        executePrecisionBlock()
                    end
                end)
            end
            break
        end
    end
end

-- ลูปตรวจจับความถี่สูง (รันทุกเฟรม RenderStepped เพื่อความไวสูงสุด)
game:GetService("RunService").RenderStepped:Connect(function()
    pcall(function()
        if autoBlockPlayer then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    checkTargetDynamic(player.Character)
                end
            end
        end

        if autoBlockNPC then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj:FindFirstChildOfClass("Humanoid") then
                    checkTargetDynamic(obj)
                end
            end
        end
    end)
end)

print("Dynamic Speed Auto Block Loaded!")
