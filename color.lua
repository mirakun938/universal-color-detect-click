local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ลบทิ้งของเก่าถ้าเคยรันไว้
if CoreGui:FindFirstChild("ScrapESP_Folder") then CoreGui.ScrapESP_Folder:Destroy() end
if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ScrapESP_UI") then LocalPlayer.PlayerGui.ScrapESP_UI:Destroy() end

local espFolder = Instance.new("Folder")
espFolder.Name = "ScrapESP_Folder"
espFolder.Parent = CoreGui

local espStates = {
    DIAMOND = true, GOLD = true, NEON = true,
    RUSTY = true, METAL = true, PURE_METAL = true
}

local collectTargets = {
    DIAMOND = false, GOLD = false, NEON = false,
    RUSTY = false, METAL = false, PURE_METAL = false
}

local autoCollectMode = false
local collectMethod = "TP" -- "TP" หรือ "TWEEN"
local isCollecting = false

-- ฟังก์ชันดักจับตัวละครเมื่อเกิดใหม่
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 10)
end

local function getScrapCategory(name)
    local upper = string.upper(name)
    if string.find(upper, "LEAF") or string.find(upper, "PART") or upper == "NEON2" or upper == "NEON" then return nil end
    
    if string.find(upper, "SCRAPDIAMOND") or upper:sub(1, 7) == "DIAMOND" then
        return "DIAMOND", Color3.fromRGB(0, 255, 255)
    elseif string.find(upper, "SCRAPGOLD") or upper:sub(1, 4) == "GOLD" then
        return "GOLD", Color3.fromRGB(255, 215, 0)
    elseif string.find(upper, "SCRAPNEON") then
        return "NEON", Color3.fromRGB(50, 255, 50)
    elseif string.find(upper, "SCRAPRUSTY") then
        return "RUSTY", Color3.fromRGB(255, 140, 0)
    elseif string.find(upper, "SCRAPMETAL2_") then
        return "PURE_METAL", Color3.fromRGB(255, 255, 255)
    elseif string.find(upper, "SCRAPMETAL_") then
        return "METAL", Color3.fromRGB(150, 150, 150)
    end
    return nil
end

local function applyESP(target)
    if not target or target:FindFirstChild("ScrapESP_Added") then return end
    local category, color = getScrapCategory(target.Name)
    if not category then return end
    
    local tag = Instance.new("StringValue")
    tag.Name = "ScrapESP_Added"
    tag.Value = category
    tag.Parent = target

    local highlight = Instance.new("Highlight")
    highlight.Name = "ScrapHighlight"
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = (category == "PURE_METAL") and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = espStates[category]
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ScrapNameTag"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = espStates[category]
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = target.Name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 13
    label.Parent = billboard

    highlight:SetAttribute("Category", category)
    billboard:SetAttribute("Category", category)

    target.AncestryChanged:Connect(function(_, parent)
        if not parent then
            highlight:Destroy()
            billboard:Destroy()
        end
    end)
end

local function scan()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) then applyESP(obj) end
    end
end
scan()

----------------------------------------------------
-- ⚡ ฟังก์ชั่น Teleport/Tween + Return to Origin
----------------------------------------------------
local function getTargetCFrame(target)
    if target:IsA("BasePart") then return target.CFrame end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.CFrame end
        local part = target:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
    end
    return nil
end

local function moveToPosition(hrp, targetCF, mode)
    if mode == "TP" then
        hrp.CFrame = targetCF + Vector3.new(0, 2, 0)
        task.wait(0.2)
    elseif mode == "TWEEN" then
        local dist = (hrp.Position - targetCF.Position).Magnitude
        if dist > 3 then
            local tweenInfo = TweenInfo.new(dist / 35, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCF + Vector3.new(0, 2, 0)})
            tween:Play()
            tween.Completed:Wait()
            task.wait(0.1)
        end
    end
end

local function collectScraps(mode)
    if isCollecting then return end
    isCollecting = true

    local hrp = getHRP()
    if not hrp then isCollecting = false return end

    -- บันทึกจุดเริ่มต้นเดิมไว้ก่อนเดินทาง
    local originalCFrame = hrp.CFrame
    local collectedCount = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- เช็กว่าตัวละครยังไม่ตาย
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
            break
        end

        local cat = getScrapCategory(obj.Name)
        if cat and collectTargets[cat] and obj.Parent then
            local targetCF = getTargetCFrame(obj)
            if targetCF then
                collectedCount = collectedCount + 1
                moveToPosition(hrp, targetCF, mode)
            end
        end
    end

    -- เมื่อเก็บหมดแล้ว ให้เดินทางกลับจุดเดิม (ถ้าตัวละครยังไม่ตาย)
    if collectedCount > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
        moveToPosition(hrp, originalCFrame, mode)
    end

    isCollecting = false
end

-- ดักจับเศษเหล็กเกิดใหม่สำหรับโหมด Auto
Workspace.DescendantAdded:Connect(function(obj)
    if (obj:IsA("Model") or obj:IsA("BasePart")) then
        task.wait(0.1)
        applyESP(obj)
        
        if autoCollectMode and not isCollecting then
            local cat = getScrapCategory(obj.Name)
            if cat and collectTargets[cat] then
                task.spawn(function() collectScraps(collectMethod) end)
            end
        end
    end
end)

----------------------------------------------------
-- 🖥️ UI Control Panel
----------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScrapESP_UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 410)
mainFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "  Scrap ESP & Auto Collector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 16
minimizeBtn.Parent = mainFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentFrame.Visible = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 230, 0, 35) or UDim2.new(0, 230, 0, 410)
    minimizeBtn.Text = isMinimized and "+" or "-"
end)

local categories = {
    {ID = "DIAMOND", Name = "DIAMOND", Color = Color3.fromRGB(0, 255, 255)},
    {ID = "GOLD", Name = "GOLD", Color = Color3.fromRGB(255, 215, 0)},
    {ID = "NEON", Name = "NEON", Color = Color3.fromRGB(50, 255, 50)},
    {ID = "RUSTY", Name = "RUSTY", Color = Color3.fromRGB(255, 140, 0)},
    {ID = "METAL", Name = "METAL", Color = Color3.fromRGB(150, 150, 150)},
    {ID = "PURE_METAL", Name = "PURE METAL", Color = Color3.fromRGB(230, 230, 230)}
}

for i, cat in ipairs(categories) do
    local yPos = 5 + ((i - 1) * 35)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.65, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = cat.Color
    btn.Text = cat.Name .. ": ON"
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = contentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        espStates[cat.ID] = not espStates[cat.ID]
        btn.Text = cat.Name .. (espStates[cat.ID] and ": ON" or ": OFF")
        btn.BackgroundTransparency = espStates[cat.ID] and 0 or 0.6
        for _, child in ipairs(espFolder:GetChildren()) do
            if child:GetAttribute("Category") == cat.ID then child.Enabled = espStates[cat.ID] end
        end
    end)

    local chkBtn = Instance.new("TextButton")
    chkBtn.Size = UDim2.new(0.22, 0, 0, 30)
    chkBtn.Position = UDim2.new(0.73, 0, 0, yPos)
    chkBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    chkBtn.Text = "GET"
    chkBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    chkBtn.Font = Enum.Font.SourceSansBold
    chkBtn.TextSize = 11
    chkBtn.Parent = contentFrame
    Instance.new("UICorner", chkBtn).CornerRadius = UDim.new(0, 5)

    chkBtn.MouseButton1Click:Connect(function()
        collectTargets[cat.ID] = not collectTargets[cat.ID]
        chkBtn.BackgroundColor3 = collectTargets[cat.ID] and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(60, 60, 70)
        chkBtn.TextColor3 = collectTargets[cat.ID] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    end)
end

-- ปุ่ม Teleport
local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.42, 0, 0, 32)
tpBtn.Position = UDim2.new(0.05, 0, 0, 280)
tpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
tpBtn.Text = "⚡ TP ONCE"
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.Font = Enum.Font.SourceSansBold
tpBtn.TextSize = 11
tpBtn.Parent = contentFrame
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

tpBtn.MouseButton1Click:Connect(function()
    collectMethod = "TP"
    task.spawn(function() collectScraps("TP") end)
end)

-- ปุ่ม Tween
local tweenBtn = Instance.new("TextButton")
tweenBtn.Size = UDim2.new(0.45, 0, 0, 32)
tweenBtn.Position = UDim2.new(0.5, 0, 0, 280)
tweenBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 180)
tweenBtn.Text = "✈️ FLY ONCE"
tweenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tweenBtn.Font = Enum.Font.SourceSansBold
tweenBtn.TextSize = 11
tweenBtn.Parent = contentFrame
Instance.new("UICorner", tweenBtn).CornerRadius = UDim.new(0, 6)

tweenBtn.MouseButton1Click:Connect(function()
    collectMethod = "TWEEN"
    task.spawn(function() collectScraps("TWEEN") end)
end)

-- ปุ่ม AUTO LOOP (เปิด/ปิด โหมดอัตโนมัติ)
local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0.9, 0, 0, 35)
autoBtn.Position = UDim2.new(0.05, 0, 0, 325)
autoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
autoBtn.Text = "🔄 AUTO COLLECT: OFF"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Font = Enum.Font.SourceSansBold
autoBtn.TextSize = 12
autoBtn.Parent = contentFrame
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

autoBtn.MouseButton1Click:Connect(function()
    autoCollectMode = not autoCollectMode
    if autoCollectMode then
        autoBtn.Text = "🔄 AUTO COLLECT: ON (" .. collectMethod .. ")"
        autoBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 200)
        task.spawn(function() collectScraps(collectMethod) end)
    else
        autoBtn.Text = "🔄 AUTO COLLECT: OFF"
        autoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    end
end)

print("Scrap Auto Collector (Respawn Fix & Return To Origin) Loaded!")
