-- UISystem - Fortnite Style HUD
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

local C = Config.COLORS

function UISystem:Init()
    self:CreateHUD()
    self:ConnectEvents()
    print("✅ UI System Initialized")
end

-- Create main HUD
function UISystem:CreateHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Health & Shield Bar (bottom left)
    local healthFrame = Instance.new("Frame")
    healthFrame.Name = "HealthBar"
    healthFrame.Size = UDim2.new(0, 250, 0, 60)
    healthFrame.Position = UDim2.new(0, 20, 1, -80)
    healthFrame.BackgroundColor3 = C.dark
    healthFrame.BackgroundTransparency = 0.3
    healthFrame.BorderSizePixel = 0
    healthFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = healthFrame
    
    -- Health bar
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, -20, 0, 20)
    healthBg.Position = UDim2.new(0, 10, 0, 10)
    healthBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = healthFrame
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = C.success
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = C.light
    healthText.TextSize = 14
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthBg
    
    uiElements.healthFill = healthFill
    uiElements.healthText = healthText
    
    -- Phase indicator (top center)
    local phaseFrame = Instance.new("Frame")
    phaseFrame.Name = "PhaseIndicator"
    phaseFrame.Size = UDim2.new(0, 300, 0, 70)
    phaseFrame.Position = UDim2.new(0.5, -150, 0, 20)
    phaseFrame.BackgroundColor3 = C.dark
    phaseFrame.BackgroundTransparency = 0.2
    phaseFrame.BorderSizePixel = 0
    phaseFrame.Parent = screenGui
    
    local phaseCorner = Instance.new("UICorner")
    phaseCorner.CornerRadius = UDim.new(0, 12)
    phaseCorner.Parent = phaseFrame
    
    local phaseText = Instance.new("TextLabel")
    phaseText.Name = "PhaseText"
    phaseText.Size = UDim2.new(1, 0, 0, 35)
    phaseText.Position = UDim2.new(0, 0, 0, 5)
    phaseText.BackgroundTransparency = 1
    phaseText.Text = "LOBBY"
    phaseText.TextColor3 = C.primary
    phaseText.TextSize = 24
    phaseText.Font = Enum.Font.GothamBlack
    phaseText.Parent = phaseFrame
    
    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.Size = UDim2.new(1, 0, 0, 25)
    timerText.Position = UDim2.new(0, 0, 0, 38)
    timerText.BackgroundTransparency = 1
    timerText.Text = "00:00"
    timerText.TextColor3 = C.light
    timerText.TextSize = 20
    timerText.Font = Enum.Font.GothamBold
    timerText.Parent = phaseFrame
    
    uiElements.phaseText = phaseText
    uiElements.timerText = timerText
    
    -- Message display (center)
    local msgFrame = Instance.new("Frame")
    msgFrame.Name = "MessageFrame"
    msgFrame.Size = UDim2.new(0, 400, 0, 50)
    msgFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
    msgFrame.BackgroundColor3 = C.dark
    msgFrame.BackgroundTransparency = 0.5
    msgFrame.BorderSizePixel = 0
    msgFrame.Visible = false
    msgFrame.Parent = screenGui
    
    local msgCorner = Instance.new("UICorner")
    msgCorner.CornerRadius = UDim.new(0, 8)
    msgCorner.Parent = msgFrame
    
    local msgText = Instance.new("TextLabel")
    msgText.Name = "MessageText"
    msgText.Size = UDim2.new(1, -20, 1, 0)
    msgText.Position = UDim2.new(0, 10, 0, 0)
    msgText.BackgroundTransparency = 1
    msgText.Text = ""
    msgText.TextColor3 = C.light
    msgText.TextSize = 18
    msgText.Font = Enum.Font.GothamBold
    msgText.TextWrapped = true
    msgText.Parent = msgFrame
    
    uiElements.messageFrame = msgFrame
    uiElements.messageText = msgText
    
    -- Kill feed (top right)
    local feedFrame = Instance.new("ScrollingFrame")
    feedFrame.Name = "KillFeed"
    feedFrame.Size = UDim2.new(0, 250, 0, 200)
    feedFrame.Position = UDim2.new(1, -260, 0.1, 0)
    feedFrame.BackgroundTransparency = 1
    feedFrame.ScrollBarThickness = 0
    feedFrame.Parent = screenGui
    
    local feedLayout = Instance.new("UIListLayout")
    feedLayout.Padding = UDim.new(0, 5)
    feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    feedLayout.Parent = feedFrame
    
    uiElements.killFeed = feedFrame
end

-- Update health
function UISystem:UpdateHealth(current, max)
    local percent = math.clamp(current / max, 0, 1)
    uiElements.healthFill.Size = UDim2.new(percent, 0, 1, 0)
    uiElements.healthText.Text = string.format("%d", math.floor(current))
    
    -- Color based on health
    if percent > 0.5 then
        uiElements.healthFill.BackgroundColor3 = C.success
    elseif percent > 0.25 then
        uiElements.healthFill.BackgroundColor3 = C.warning
    else
        uiElements.healthFill.BackgroundColor3 = C.danger
    end
end

-- Update phase
function UISystem:UpdatePhase(phaseName)
    local phaseColors = {
        LOBBY = C.gray,
        BUILD = C.primary,
        COMBAT = C.danger,
        END = C.secondary
    }
    
    local color = phaseColors[phaseName] or C.light
    uiElements.phaseText.Text = phaseName
    uiElements.phaseText.TextColor3 = color
end

-- Update timer
function UISystem:UpdateTimer(seconds)
    uiElements.timerText.Text = Utils.FormatTime(seconds)
end

-- Show message
function UISystem:ShowMessage(text, duration)
    duration = duration or 3
    
    uiElements.messageText.Text = text
    uiElements.messageFrame.Visible = true
    uiElements.messageFrame.BackgroundTransparency = 0.5
    
    -- Fade in
    TweenService:Create(uiElements.messageFrame, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.3
    }):Play()
    
    -- Fade out after duration
    task.delay(duration, function()
        TweenService:Create(uiElements.messageFrame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.5)
        uiElements.messageFrame.Visible = false
    end)
end

-- Add to kill feed
function UISystem:AddKillFeed(killer, victim)
    local item = Instance.new("Frame")
    item.Size = UDim2.new(0, 230, 0, 30)
    item.BackgroundColor3 = C.dark
    item.BackgroundTransparency = 0.3
    item.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 1, 0)
    text.Position = UDim2.new(0, 5, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = string.format("%s eliminated %s", killer, victim)
    text.TextColor3 = C.light
    text.TextSize = 12
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Right
    text.Parent = item
    
    item.Parent = uiElements.killFeed
    
    -- Remove after 5 seconds
    task.delay(5, function()
        item:Destroy()
    end)
end

-- Connect to server events
function UISystem:ConnectEvents()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local GameStateEvent = Remotes:WaitForChild("GameStateEvent")
    local CombatEvent = Remotes:WaitForChild("CombatEvent")
    
    GameStateEvent.OnClientEvent:Connect(function(type, data)
        if type == "PHASE" then
            self:UpdatePhase(data.phase)
        elseif type == "TIMER" then
            self:UpdateTimer(data)
        elseif type == "MESSAGE" then
            self:ShowMessage(data)
        elseif type == "KILL" then
            self:AddKillFeed(data.killer, data.victim)
        end
    end)
    
    CombatEvent.OnClientEvent:Connect(function(type, ...)
        if type == "HEALTH_UPDATE" then
            self:UpdateHealth(...)
        end
    end)
    
    -- Track character health
    local function onCharacterAdded(char)
        local hum = char:WaitForChild("Humanoid")
        self:UpdateHealth(hum.Health, hum.MaxHealth)
        
        hum.HealthChanged:Connect(function(health)
            self:UpdateHealth(health, hum.MaxHealth)
        end)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

UISystem:Init()
return UISystem
