-- LoadingScreen - Hides UI until server remotes are ready
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local player            = Players.LocalPlayer
local playerGui         = player:WaitForChild("PlayerGui")

-- Build the loading screen immediately (before anything else loads)
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "LoadingScreen"
screenGui.ResetOnSpawn  = false
screenGui.DisplayOrder  = 100    -- On top of everything
screenGui.IgnoreGuiInset = true
screenGui.Parent        = playerGui

local bg = Instance.new("Frame")
bg.Size               = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3   = Color3.fromRGB(15, 20, 30)
bg.BorderSizePixel    = 0
bg.Parent             = screenGui

-- Logo / title
local title = Instance.new("TextLabel")
title.Size               = UDim2.new(0, 500, 0, 70)
title.Position           = UDim2.new(0.5, -250, 0.5, -100)
title.BackgroundTransparency = 1
title.Text               = "🎲  AURA  ROLLER"
title.TextColor3         = Color3.fromRGB(255, 200, 50)
title.TextSize           = 52
title.Font               = Enum.Font.GothamBlack
title.LetterSpacing      = 6
title.Parent             = bg

-- Subtitle
local sub = Instance.new("TextLabel")
sub.Size               = UDim2.new(0, 500, 0, 30)
sub.Position           = UDim2.new(0.5, -250, 0.5, -30)
sub.BackgroundTransparency = 1
sub.Text               = "Roll for glory. Become a legend."
sub.TextColor3         = Color3.fromRGB(160, 160, 180)
sub.TextSize           = 18
sub.Font               = Enum.Font.Gotham
sub.Parent             = bg

-- Animated spinner (3 dots cycling)
local spinnerLbl = Instance.new("TextLabel")
spinnerLbl.Name              = "Spinner"
spinnerLbl.Size              = UDim2.new(0, 300, 0, 30)
spinnerLbl.Position          = UDim2.new(0.5, -150, 0.5, 40)
spinnerLbl.BackgroundTransparency = 1
spinnerLbl.Text              = "Loading..."
spinnerLbl.TextColor3        = Color3.fromRGB(100, 100, 120)
spinnerLbl.TextSize          = 16
spinnerLbl.Font              = Enum.Font.Gotham
spinnerLbl.Parent            = bg

-- Pulse the title color while loading
local pulseConn
pulseConn = game:GetService("RunService").Heartbeat:Connect(function()
    local t = tick()
    local brightness = 0.85 + 0.15 * math.sin(t * 3)
    title.TextColor3 = Color3.fromRGB(
        255,
        math.floor(200 * brightness),
        math.floor(50 * brightness)
    )
    -- Spinning dots
    local dots = math.floor(t * 2) % 4
    spinnerLbl.Text = "Loading" .. string.rep(".", dots)
end)

-- Wait until the key remote is available (signals server is ready)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if Remotes then
    Remotes:WaitForChild("DataUpdateEvent", 30)
end

pulseConn:Disconnect()

-- Extra short delay so first SYNC arrives before we hide
task.wait(0.8)

-- Fade out loading screen
TweenService:Create(bg, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
    BackgroundTransparency = 1
}):Play()
TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
TweenService:Create(sub,   TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
TweenService:Create(spinnerLbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()

task.delay(0.7, function()
    screenGui:Destroy()
end)

print("✅ Loading Screen Dismissed")
