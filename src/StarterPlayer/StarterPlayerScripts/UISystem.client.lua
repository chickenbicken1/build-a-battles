-- Build a Battles - Modern UI System
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local UISystem = {}
local uiElements = {}

-- Color Palette
local COLORS = {
    primary = Color3.fromRGB(59, 130, 246),
    secondary = Color3.fromRGB(147, 51, 234),
    success = Color3.fromRGB(34, 197, 94),
    danger = Color3.fromRGB(239, 68, 68),
    warning = Color3.fromRGB(251, 191, 36),
    dark = Color3.fromRGB(17, 24, 39),
    darker = Color3.fromRGB(11, 15, 25),
    light = Color3.fromRGB(243, 244, 246),
    gray = Color3.fromRGB(156, 163, 175),
}

function UISystem:Init()
    self:CreateHUD()
    self:CreatePhaseIndicator()
    self:CreateKillFeed()
    self:CreateDamageIndicators()
    self:ConnectEvents()
    print("✅ Modern UI System Initialized")
end

function UISystem:CreateHUD()
    local hud = Instance.new("ScreenGui")
    hud.Name = "ModernHUD"
    hud.ResetOnSpawn = false
    hud.Parent = playerGui
    uiElements.hud = hud
    
    -- Health Bar
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthBar"
    healthFrame.Size = UDim2.new(0, 250, 0, 60)
    healthFrame.Position = UDim2.new(0, 20, 1, -80)
    healthFrame.BackgroundColor3 = COLORS.darker
    healthFrame.BackgroundTransparency = 0.2
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = hud
    
    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 12)
    healthCorner.Parent = healthFrame
    
    local healthIcon = Instance.new("TextLabel")
    healthIcon.Name = "Icon"
    healthIcon.Size = UDim2.new(0, 40, 0, 40)
    healthIcon.Position = UDim2.new(0, 10, 0.5, -20)
    healthIcon.BackgroundColor3 = COLORS.danger
    healthIcon.Text = ""
    healthIcon.TextSize = 24
    healthIcon.Font = Enum.Font.GothamBold
    healthIcon.Parent = healthFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = healthIcon
    
    local healthBg = Instance.new("Frame")
    healthBg.Name = "Background"
    healthBg.Size = UDim2.new(0, 170, 0, 20)
    healthBg.Position = UDim2.new(0, 60, 0.5, -10)
    healthBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = healthFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 6)
    bgCorner.Parent = healthBg
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = COLORS.danger
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = healthFill
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(0, 170, 0, 20)
    healthText.Position = UDim2.new(0, 60, 0.5, -10)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100/100"
    healthText.TextColor3 = COLORS.light
    healthText.TextSize = 14
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthFrame
    
    uiElements.healthFill = healthFill
    uiElements.healthText = healthText
    
    -- Weapon Info
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Name = "WeaponInfo"
    weaponFrame.Size = UDim2.new(0, 200, 0, 80)
    weaponFrame.Position = UDim2.new(1, -220, 1, -100)
    weaponFrame.BackgroundColor3 = COLORS.darker
    weaponFrame.BackgroundTransparency = 0.2
    weaponFrame.BorderSizePixel = 0
    weaponFrame.Parent = hud
    
    local weaponCorner = Instance.new("UICorner")
    weaponCorner.CornerRadius = UDim.new(0, 12)
    weaponCorner.Parent = weaponFrame
    
    local weaponName = Instance.new("TextLabel")
    weaponName.Name = "WeaponName"
    weaponName.Size = UDim2.new(1, 0, 0, 30)
    weaponName.Position = UDim2.new(0, 0, 0, 5)
    weaponName.BackgroundTransparency = 1
    weaponName.Text = "SWORD"
    weaponName.TextColor3 = COLORS.primary
    weaponName.TextSize = 20
    weaponName.Font = Enum.Font.GothamBold
    weaponName.Parent = weaponFrame
    
    local ammoText = Instance.new("TextLabel")
    ammoText.Name = "Ammo"
    ammoText.Size = UDim2.new(1, 0, 0, 25)
    ammoText.Position = UDim2.new(0, 0, 0, 35)
    ammoText.BackgroundTransparency = 1
    ammoText.Text = ""
    ammoText.TextColor3 = COLORS.light
    ammoText.TextSize = 28
    ammoText.Font = Enum.Font.GothamBold
    ammoText.Parent = weaponFrame
    
    local keyHint = Instance.new("TextLabel")
    keyHint.Name = "KeyHint"
    keyHint.Size = UDim2.new(1, 0, 0, 20)
    keyHint.Position = UDim2.new(0, 0, 0, 62)
    keyHint.BackgroundTransparency = 1
    keyHint.Text = "[1] [2] [3] Switch"
    keyHint.TextColor3 = COLORS.gray
    keyHint.TextSize = 12
    keyHint.Font = Enum.Font.Gotham
    keyHint.Parent = weaponFrame
    
    uiElements.weaponName = weaponName
    uiElements.ammoText = ammoText
    
    -- Blocks Counter
    local blocksFrame = Instance.new("Frame")
    blocksFrame.Name = "BlocksCounter"
    blocksFrame.Size = UDim2.new(0, 150, 0, 50)
    blocksFrame.Position = UDim2.new(0, 20, 0, 20)
    blocksFrame.BackgroundColor3 = COLORS.darker
    blocksFrame.BackgroundTransparency = 0.2
    blocksFrame.BorderSizePixel = 0
    blocksFrame.Parent = hud
    
    local blocksCorner = Instance.new("UICorner")
    blocksCorner.CornerRadius = UDim.new(0, 10)
    blocksCorner.Parent = blocksFrame
    
    local blocksIcon = Instance.new("TextLabel")
    blocksIcon.Size = UDim2.new(0, 30, 0, 30)
    blocksIcon.Position = UDim2.new(0, 10, 0.5, -15)
    blocksIcon.BackgroundColor3 = COLORS.warning
    blocksIcon.Text = "B"
    blocksIcon.TextColor3 = COLORS.dark
    blocksIcon.TextSize = 18
    blocksIcon.Font = Enum.Font.GothamBold
    blocksIcon.Parent = blocksFrame
    
    local iconCorner2 = Instance.new("UICorner")
    iconCorner2.CornerRadius = UDim.new(0, 6)
    iconCorner2.Parent = blocksIcon
    
    local blocksText = Instance.new("TextLabel")
    blocksText.Name = "BlocksText"
    blocksText.Size = UDim2.new(0, 90, 0, 30)
    blocksText.Position = UDim2.new(0, 50, 0.5, -15)
    blocksText.BackgroundTransparency = 1
    blocksText.Text = "0/200"
    blocksText.TextColor3 = COLORS.light
    blocksText.TextSize = 18
    blocksText.Font = Enum.Font.GothamBold
    blocksText.TextXAlignment = Enum.TextXAlignment.Left
    blocksText.Parent = blocksFrame
    
    uiElements.blocksText = blocksText
    
    -- Coins Display
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsDisplay"
    coinsFrame.Size = UDim2.new(0, 150, 0, 45)
    coinsFrame.Position = UDim2.new(1, -170, 0, 20)
    coinsFrame.BackgroundColor3 = COLORS.darker
    coinsFrame.BackgroundTransparency = 0.2
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = hud
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 10)
    coinsCorner.Parent = coinsFrame
    
    local coinsIcon = Instance.new("TextLabel")
    coinsIcon.Size = UDim2.new(0, 30, 0, 30)
    coinsIcon.Position = UDim2.new(0, 10, 0.5, -15)
    coinsIcon.BackgroundColor3 = COLORS.warning
    coinsIcon.Text = "$"
    coinsIcon.TextColor3 = COLORS.dark
    coinsIcon.TextSize = 20
    coinsIcon.Font = Enum.Font.GothamBold
    coinsIcon.Parent = coinsFrame
    
    local iconCorner3 = Instance.new("UICorner")
    iconCorner3.CornerRadius = UDim.new(0, 6)
    iconCorner3.Parent = coinsIcon
    
    local coinsText = Instance.new("TextLabel")
    coinsText.Name = "CoinsText"
    coinsText.Size = UDim2.new(0, 90, 0, 30)
    coinsText.Position = UDim2.new(0, 50, 0.5, -15)
    coinsText.BackgroundTransparency = 1
    coinsText.Text = "0"
    coinsText.TextColor3 = COLORS.warning
    coinsText.TextSize = 22
    coinsText.Font = Enum.Font.GothamBold
    coinsText.TextXAlignment = Enum.TextXAlignment.Left
    coinsText.Parent = coinsFrame
    
    uiElements.coinsText = coinsText
end

function UISystem:CreatePhaseIndicator()
    local phaseFrame = Instance.new("Frame")
    phaseFrame.Name = "PhaseIndicator"
    phaseFrame.Size = UDim2.new(0, 300, 0, 80)
    phaseFrame.Position = UDim2.new(0.5, -150, 0, 20)
    phaseFrame.BackgroundColor3 = COLORS.darker
    phaseFrame.BackgroundTransparency = 0.1
    phaseFrame.BorderSizePixel = 0
    phaseFrame.Parent = uiElements.hud
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = phaseFrame
    
    local phaseText = Instance.new("TextLabel")
    phaseText.Name = "PhaseText"
    phaseText.Size = UDim2.new(1, 0, 0, 40)
    phaseText.Position = UDim2.new(0, 0, 0, 8)
    phaseText.BackgroundTransparency = 1
    phaseText.Text = "LOBBY PHASE"
    phaseText.TextColor3 = COLORS.primary
    phaseText.TextSize = 28
    phaseText.Font = Enum.Font.GothamBlack
    phaseText.Parent = phaseFrame
    
    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.Size = UDim2.new(1, 0, 0, 30)
    timerText.Position = UDim2.new(0, 0, 0, 45)
    timerText.BackgroundTransparency = 1
    timerText.Text = "00:30"
    timerText.TextColor3 = COLORS.light
    timerText.TextSize = 24
    timerText.Font = Enum.Font.GothamBold
    timerText.Parent = phaseFrame
    
    uiElements.phaseText = phaseText
    uiElements.timerText = timerText
end

function UISystem:CreateKillFeed()
    local feedFrame = Instance.new("ScrollingFrame")
    feedFrame.Name = "KillFeed"
    feedFrame.Size = UDim2.new(0, 280, 0, 200)
    feedFrame.Position = UDim2.new(1, -300, 0.3, 0)
    feedFrame.BackgroundTransparency = 1
    feedFrame.ScrollBarThickness = 0
    feedFrame.ScrollingEnabled = false
    feedFrame.Parent = uiElements.hud
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Parent = feedFrame
    
    uiElements.killFeed = feedFrame
    uiElements.killFeedItems = {}
end

function UISystem:CreateDamageIndicators()
    uiElements.damageLabels = {}
end

function UISystem:ShowDamage(position, damage, isCritical)
    local camera = workspace.CurrentCamera
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = workspace
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(damage)
    label.TextColor3 = isCritical and COLORS.warning or COLORS.danger
    label.TextSize = isCritical and 36 or 28
    label.Font = Enum.Font.GothamBlack
    label.Parent = billboard
    
    -- Animate
    task.spawn(function()
        for i = 1, 30 do
            billboard.StudsOffset = billboard.StudsOffset + Vector3.new(0, 0.15, 0)
            label.TextTransparency = i / 30
            task.wait(0.03)
        end
        billboard:Destroy()
    end)
end

function UISystem:AddKillFeed(killer, victim, weapon)
    local item = Instance.new("Frame")
    item.Size = UDim2.new(0, 260, 0, 35)
    item.BackgroundColor3 = COLORS.darker
    item.BackgroundTransparency = 0.2
    item.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 1, 0)
    text.Position = UDim2.new(0, 5, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = killer .. " > " .. victim
    text.TextColor3 = COLORS.light
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.Parent = item
    
    item.Parent = uiElements.killFeed
    table.insert(uiElements.killFeedItems, item)
    
    item.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(item, TweenInfo.new(0.3), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    task.delay(5, function()
        TweenService:Create(item, TweenInfo.new(0.3), {Position = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.3)
        item:Destroy()
    end)
    
    if #uiElements.killFeedItems > 5 then
        local old = table.remove(uiElements.killFeedItems, 1)
        if old then old:Destroy() end
    end
end

function UISystem:UpdateHealth(current, max)
    local percent = math.clamp(current / max, 0, 1)
    uiElements.healthFill.Size = UDim2.new(percent, 0, 1, 0)
    uiElements.healthText.Text = string.format("%d/%d", math.floor(current), max)
    
    if percent > 0.5 then
        uiElements.healthFill.BackgroundColor3 = COLORS.danger
    elseif percent > 0.25 then
        uiElements.healthFill.BackgroundColor3 = COLORS.warning
    else
        uiElements.healthFill.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    end
end

function UISystem:UpdatePhase(phase, timeLeft)
    local phaseColors = {
        LOBBY = COLORS.gray,
        BUILDING = COLORS.success,
        COMBAT = COLORS.danger,
        END = COLORS.secondary
    }
    
    local color = phaseColors[phase] or COLORS.primary
    uiElements.phaseText.Text = phase .. " PHASE"
    uiElements.phaseText.TextColor3 = color
    uiElements.timerText.Text = Utils.FormatTime(timeLeft or 0)
end

function UISystem:UpdateBlocks(current, max)
    uiElements.blocksText.Text = string.format("%d/%d", current, max)
    uiElements.blocksText.TextColor3 = current >= max and COLORS.danger or COLORS.light
end

function UISystem:UpdateCoins(amount)
    uiElements.coinsText.Text = tostring(amount)
    TweenService:Create(uiElements.coinsText, TweenInfo.new(0.1), {TextSize = 28}):Play()
    task.delay(0.1, function()
        TweenService:Create(uiElements.coinsText, TweenInfo.new(0.1), {TextSize = 22}):Play()
    end)
end

function UISystem:ConnectEvents()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    local gameStateEvent = remotes:WaitForChild("GameStateEvent")
    gameStateEvent.OnClientEvent:Connect(function(type, data)
        if type == "PHASE" then
            self:UpdatePhase(data.phase, data.timeLeft)
        elseif type == "TIMER" then
            uiElements.timerText.Text = Utils.FormatTime(data)
        elseif type == "KILL" then
            self:AddKillFeed(data.killer, data.victim, data.weapon)
        elseif type == "BLOCKS_UPDATE" then
            self:UpdateBlocks(data.current, data.max)
        elseif type == "COINS_UPDATE" then
            self:UpdateCoins(data.amount)
        end
    end)
    
    local combatEvent = remotes:WaitForChild("CombatEvent")
    combatEvent.OnClientEvent:Connect(function(action, data)
        if action == "HEALTH_UPDATE" then
            self:UpdateHealth(data.current, data.max)
        elseif action == "DAMAGE_NUMBER" then
            self:ShowDamage(data.position, data.damage, data.isCritical)
        end
    end)
    
    local function setupHealthTracking()
        local char = player.Character
        if not char then return end
        
        local humanoid = char:WaitForChild("Humanoid")
        self:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
        
        humanoid.HealthChanged:Connect(function(health)
            self:UpdateHealth(health, humanoid.MaxHealth)
        end)
    end
    
    player.CharacterAdded:Connect(setupHealthTracking)
    if player.Character then setupHealthTracking() end
end

UISystem:Init()
_G.UISystem = UISystem
