local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ค่าตั้งค่า Auto Block
local autoBlockPlayer = true
local autoBlockNPC = true
local maxBlockDistance = 12
local isBlocking = false

-- ฟังก์ชันกดบล็อก (Parry)
local function executeBlock()
    if isBlocking then return end
    isBlocking = true

    -- 1. ยิง RemoteEvent ของระบบเกมโดยตรง (ถ้ามีอาวุธในมือ)
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("ToolRemote") then
            tool.ToolRemote:FireServer("Block")
            tool.ToolRemote:FireServer("Parry")
        end
    end

    -- 2. จำลองการกดปุ่ม F (เผื่อเกมใช้ระบบ Input)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)

    task.wait(0.3) -- Cooldown ป้องกันกดซ้ำติดกัน
    isBlocking = false
end

-- ตรวจสอบ HumanoidRootPart
local function getHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
end

-- ตรวจจับ Animation การโจมตี + หน่วงเวลาตามท่า
local function checkAndBlock(char)
    if not char then return end
    
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    local targetHRP = getHRP(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not myHRP or not targetHRP or not humanoid then return end

    -- เช็กระยะ
    local distance = (myHRP.Position - targetHRP.Position).Magnitude
    if distance > maxBlockDistance then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local animName = string.lower(track.Name)

        -- 1. ท่า Heavy Attack (ตีช้า/ง้างนาน) -> รอจังหวะก่อนบล็อก
        if string.find(animName, "heavy") then
            task.delay(0.25, function() -- หน่วงเวลา 0.25 วินาทีให้ตรงจังหวะฟันลงมา
                if (myHRP.Position - targetHRP.Position).Magnitude <= maxBlockDistance then
                    executeBlock()
                end
            end)
            break
            
        -- 2. ท่า Swing_1 / Swing_2 / ตีปกติ -> บล็อกทันที
        elseif string.find(animName, "swing") or string.find(animName, "attack") or track.Priority == Enum.AnimationPriority.Action then
            executeBlock()
            break
        end
    end
end

-- Loop ตรวจสอบ Player & NPC
RunService.Heartbeat:Connect(function()
    if autoBlockPlayer then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                checkAndBlock(player.Character)
            end
        end
    end

    if autoBlockNPC then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj:FindFirstChildOfClass("Humanoid") then
                checkAndBlock(obj)
            end
        end
    end
end)

print("Perfect Auto Block Loaded!")
