-- RollController - Client-side rolling UI and logic
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local C = Config.COLORS

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollEvent = Remotes:WaitForChild("RollEvent")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")
local AuraEquipEvent = Remotes:WaitForChild("AuraEquipEvent")

-- State
local currentAura = nil
local currentLuck = 1
local isRolling = false

-- UI Elements
local uiElements = {}

local RollController = {}

function RollController:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Roll Controller Initialized")
end

-- Create main UI
function RollController:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RollUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame (center bottom)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -200, 1, -280)
    mainFrame.BackgroundColor3 = C.dark
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    uiElements.mainFrame = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🎲 AURA RNG ROLLER"
    title.TextColor3 = C.primary
    title.TextSize = 24
    title.Font = Enum.Font.GothamBlack
    title.Parent = mainFrame
    
    -- Current Aura Display
    local auraFrame = Instance.new("Frame")
    auraFrame.Name = "AuraDisplay"
    auraFrame.Size = UDim2.new(1, -20, 0, 80)
    auraFrame.Position = UDim2.new(0, 10, 0, 45)
    auraFrame.BackgroundColor3 = C.darker
    auraFrame.BorderSizePixel = 0
    auraFrame.Parent = mainFrame
    
    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(0, 8)
    auraCorner.Parent = auraFrame
    
    -- Aura Name
    local auraName = Instance.new("TextLabel")
    auraName.Name = "AuraName"
    auraName.Size = UDim2.new(1, -10, 0, 30)
    auraName.Position = UDim2.new(0, 5, 0, 5)
    auraName.BackgroundTransparency = 1
    auraName.Text = "No Aura Equipped"
    auraName.TextColor3 = C.gray
    auraName.TextSize = 20
    auraName.Font = Enum.Font.GothamBold
    auraName.Parent = auraFrame
    
    uiElements.auraName = auraName
    
    -- Aura Rarity
    local auraRarity = Instance.new("TextLabel")
    auraRarity.Name = "AuraRarity"
    auraRarity.Size = UDim2.new(1, -10, 0, 20)
    auraRarity.Position = UDim2.new(0, 5, 0, 35)
    auraRarity.BackgroundTransparency = 1
    auraRarity.Text = ""
    auraRarity.TextColor3 = C.gray
    auraRarity.TextSize = 14
    auraRarity.Font = Enum.Font.Gotham
    auraRarity.Parent = auraFrame
    
    uiElements.auraRarity = auraRarity
    
    -- Luck Display
    local luckFrame = Instance.new("Frame")
    luckFrame.Size = UDim2.new(0, 120, 0, 30)
    luckFrame.Position = UDim2.new(1, -130, 0, 60)
    luckFrame.BackgroundColor3 = C.darker
    luckFrame.BorderSizePixel = 0
    luckFrame.Parent = auraFrame
    
    local luckCorner = Instance.new("UICorner")
    luckCorner.CornerRadius = UDim.new(0, 6)
    luckCorner.Parent = luckFrame
    
    local luckLabel = Instance.new("TextLabel")
    luckLabel.Name = "LuckLabel"
    luckLabel.Size = UDim2.new(1, 0, 1, 0)
    luckLabel.BackgroundTransparency = 1
    luckLabel.Text = "🍀 1.00x"
    luckLabel.TextColor3 = C.success
    luckLabel.TextSize = 16
    luckLabel.Font = Enum.Font.GothamBold
    luckLabel.Parent = luckFrame
    
    uiElements.luckLabel = luckLabel
    
    -- Roll Button
    local rollBtn = Instance.new("TextButton")
    rollBtn.Name = "RollButton"
    rollBtn.Size = UDim2.new(1, -20, 0, 60)
    rollBtn.Position = UDim2.new(0, 10, 0, 135)
    rollBtn.BackgroundColor3 = C.primary
    rollBtn.Text = "🎲 ROLL AURA"
    rollBtn.TextColor3 = C.dark
    rollBtn.TextSize = 24
    rollBtn.Font = Enum.Font.GothamBlack
    rollBtn.Parent = mainFrame
    
    local rollCorner = Instance.new("UICorner")
    rollCorner.CornerRadius = UDim.new(0, 10)
    rollCorner.Parent = rollBtn
    
    uiElements.rollBtn = rollBtn
    
    -- Rolling Animation Frame (hidden by default)
    local rollAnimFrame = Instance.new("Frame")
    rollAnimFrame.Name = "RollAnimation"
    rollAnimFrame.Size = UDim2.new(1, -20, 0, 60)
    rollAnimFrame.Position = UDim2.new(0, 10, 0, 135)
    rollAnimFrame.BackgroundColor3 = C.darker
    rollAnimFrame.BorderSizePixel = 0
    rollAnimFrame.Visible = false
    rollAnimFrame.Parent = mainFrame
    
    local animCorner = Instance.new("UICorner")
    animCorner.CornerRadius = UDim.new(0, 10)
    animCorner.Parent = rollAnimFrame
    
    local animText = Instance.new("TextLabel")
    animText.Name = "AnimText"
    animText.Size = UDim2.new(1, 0, 1, 0)
    animText.BackgroundTransparency = 1
    animText.Text = "Rolling..."
    animText.TextColor3 = C.light
    animText.TextSize = 20
    animText.Font = Enum.Font.GothamBold
    animText.Parent = rollAnimFrame
    
    uiElements.rollAnimFrame = rollAnimFrame
    uiElements.animText = animText
    
    -- Stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -20, 0, 30)
    statsFrame.Position = UDim2.new(0, 10, 0, 205)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = mainFrame
    
    local rollsLabel = Instance.new("TextLabel")
    rollsLabel.Name = "RollsLabel"
    rollsLabel.Size = UDim2.new(0.5, 0, 1, 0)
    rollsLabel.BackgroundTransparency = 1
    rollsLabel.Text = "Rolls: 0"
    rollsLabel.TextColor3 = C.gray
    rollsLabel.TextSize = 14
    rollsLabel.Font = Enum.Font.Gotham
    rollsLabel.TextXAlignment = Enum.TextXAlignment.Left
    rollsLabel.Parent = statsFrame
    
    uiElements.rollsLabel = rollsLabel
    
    local gemsLabel = Instance.new("TextLabel")
    gemsLabel.Name = "GemsLabel"
    gemsLabel.Size = UDim2.new(0.5, 0, 1, 0)
    gemsLabel.Position = UDim2.new(0.5, 0, 0, 0)
    gemsLabel.BackgroundTransparency = 1
    gemsLabel.Text = "💎 0"
    gemsLabel.TextColor3 = C.primary
    gemsLabel.TextSize = 14
    gemsLabel.Font = Enum.Font.GothamBold
    gemsLabel.TextXAlignment = Enum.TextXAlignment.Right
    gemsLabel.Parent = statsFrame
    
    uiElements.gemsLabel = gemsLabel
    
    -- Bind button click
    rollBtn.MouseButton1Click:Connect(function()
        self:DoRoll()
    end)
    
    -- Spacebar support
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Space then
            self:DoRoll()
        end
    end)
end

-- Do a roll
function RollController:DoRoll()
    if isRolling then return end
    
    isRolling = true
    
    -- Hide button, show animation
    uiElements.rollBtn.Visible = false
    uiElements.rollAnimFrame.Visible = true
    
    -- Animation
    local startTime = tick()
    local animConnection
    
    animConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed < 1.5 then
            -- Cycle through random auras
            local randomAura = Config.AURAS[math.random(1, #Config.AURAS)]
            uiElements.animText.Text = randomAura.name
            uiElements.animText.TextColor3 = Config.RARITIES[randomAura.rarity].color
        else
            animConnection:Disconnect()
        end
    end)
    
    -- Send request to server
    RollEvent:FireServer()
end

-- Handle roll result
function RollController:HandleRollResult(result, data)
    isRolling = false
    
    if result == "SUCCESS" then
        local aura = data
        local rarityConfig = Config.RARITIES[aura.rarity]
        
        -- Show result
        uiElements.animText.Text = aura.name
        uiElements.animText.TextColor3 = rarityConfig.color
        
        task.wait(1)
        
        -- Update display
        self:UpdateAuraDisplay(aura)
        
        -- Show notification
        self:ShowNotification(string.format("You rolled %s! (%s)", aura.name, aura.rarity), rarityConfig.color)
    else
        uiElements.animText.Text = "Failed!"
        uiElements.animText.TextColor3 = C.danger
        
        task.wait(1)
    end
    
    -- Reset UI
    uiElements.rollAnimFrame.Visible = false
    uiElements.rollBtn.Visible = true
end

-- Update aura display
function RollController:UpdateAuraDisplay(aura)
    currentAura = aura
    
    uiElements.auraName.Text = aura.name
    uiElements.auraName.TextColor3 = Config.RARITIES[aura.rarity].color
    
    uiElements.auraRarity.Text = aura.rarity
    uiElements.auraRarity.TextColor3 = Config.RARITIES[aura.rarity].color
end

-- Update stats display
function RollController:UpdateStats(data)
    if data.totalLuck then
        currentLuck = data.totalLuck
        uiElements.luckLabel.Text = string.format("🍀 %sx", Utils.FormatLuck(currentLuck))
    end
    
    if data.rollCount then
        uiElements.rollsLabel.Text = string.format("Rolls: %s", Utils.FormatNumber(data.rollCount))
    end
    
    if data.gems then
        uiElements.gemsLabel.Text = string.format("💎 %s", Utils.FormatNumber(data.gems))
    end
end

-- Show notification
function RollController:ShowNotification(text, color)
    color = color or C.light
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 50)
    notif.Position = UDim2.new(0.5, -150, 0, -60)
    notif.BackgroundColor3 = C.darker
    notif.BorderSizePixel = 0
    notif.Parent = playerGui:WaitForChild("RollUI")
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Parent = notif
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.Parent = notif
    
    -- Animate in
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, 20)}):Play()
    
    -- Remove after delay
    task.delay(3, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 0, -60)}):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- Connect events
function RollController:ConnectEvents()
    -- Roll response
    RollEvent.OnClientEvent:Connect(function(result, data)
        self:HandleRollResult(result, data)
    end)
    
    -- Data updates
    DataUpdateEvent.OnClientEvent:Connect(function(type, data)
        if type == "SYNC" then
            self:UpdateStats(data)
            if data.equippedAura then
                self:UpdateAuraDisplay(data.equippedAura)
            end
        elseif type == "RARE_ROLL" then
            -- Someone else got a rare roll
            self:ShowNotification(
                string.format("🔥 %s rolled %s!", data.playerName, data.auraName),
                data.color
            )
        end
    end)
    
    -- Aura equip (for visual updates)
    AuraEquipEvent.OnClientEvent:Connect(function(playerId, auraId)
        -- Could update other players' aura visuals here
    end)
end

RollController:Init()
return RollController
