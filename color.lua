local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ดึง Remote Upgrade จากตำแหน่งจริงใน ReplicatedStorage
local upgradeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gui"):WaitForChild("Upgrade")

local function autoRefillMinigun()
    print("กำลังทำ Auto Refill กระสุน Minigun...")
    
    -- 1. สั่งลดระดับ (Downgrade) เพื่อเอาพอยต์คืน (Argument 4 = false)
    pcall(function()
        upgradeRemote:FireServer("Borrowed Technology", "MaxAmmo", "Primary", false)
    end)
    
    task.wait(0.05) -- หน่วงเวลาเล็กน้อยเพื่อให้ Server รับคำสั่งแรกทัน
    
    -- 2. สั่งอัปเกรดกลับ (Upgrade) เพื่อสั่งให้ Refill กระสุนทำงาน (Argument 4 = true)
    pcall(function()
        upgradeRemote:FireServer("Borrowed Technology", "MaxAmmo", "Primary", true)
    end)
end

-- ==================== ปุ่มกด GUI หน้าจอ ====================
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinigunRefillGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local RefillBtn = Instance.new("TextButton")
RefillBtn.Name = "RefillButton"
RefillBtn.Parent = ScreenGui
RefillBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
RefillBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
RefillBtn.Size = UDim2.new(0, 140, 0, 45)
RefillBtn.Font = Enum.Font.SourceSansBold
RefillBtn.Text = "AUTO REFILL (0 Points)"
RefillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefillBtn.TextSize = 15
RefillBtn.Active = true
RefillBtn.Draggable = true

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = RefillBtn

RefillBtn.MouseButton1Click:Connect(function()
    autoRefillMinigun()
end)

print("Minigun Upgrade-Refill Loaded Successfully!")
