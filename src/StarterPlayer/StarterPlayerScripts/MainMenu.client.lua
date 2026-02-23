-- Build a Battles - Main Menu System
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MainMenu = {}
local uiElements = {}
local isMenuOpen = true

local COLORS = {
    primary = Color3.fromRGB(59, 130, 246),
    secondary = Color3.fromRGB(147, 51, 234),
    accent = Color3.fromRGB(236, 72, 153),
    dark = Color3.fromRGB(11, 15, 25),
    darker = Color3.fromRGB(5, 8, 15),
    light = Color3.fromRGB(243, 244, 246),
    gray = Color3.fromRGB(75, 85, 99),
}

function MainMenu:Init()
    self:CreateMainMenu()
    self:CreateSideMenu()
    print("✅ Main Menu Initialized")
end

function MainMenu:CreateMainMenu()
    local menu = Instance.new("ScreenGui")
    menu.Name = "MainMenu"
    menu.ResetOnSpawn = false
    menu.Parent = playerGui
    uiElements.menu = menu
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = COLORS.darker
    bg.Parent = menu
    
    -- Gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 24, 39)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 27, 75)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 28, 135))
    })
    gradient.Rotation = 45
    gradient.Parent = bg
    
    -- Particle effects container
    local particles = Instance.new("Frame")
    particles.Name = "Particles"
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.BackgroundTransparency = 1
    particles.Parent = bg
    self:CreateFloatingParticles(particles)
    
    -- Logo
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "Logo"
    logoContainer.Size = UDim2.new(0, 600, 0, 150)
    logoContainer.Position = UDim2.new(0.5, -300, 0, 80)
    logoContainer.BackgroundTransparency = 1
    logoContainer.Parent = bg
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 0, 80)
    logoText.BackgroundTransparency = 1
    logoText.Text = "BUILD A BATTLES"
    logoText.TextColor3 = COLORS.light
    logoText.TextSize = 64
    logoText.Font = Enum.Font.GothamBlack
    logoText.Parent = logoContainer
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 40)
    subtitle.Position = UDim2.new(0, 0, 0, 85)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "BUILD. BATTLE. DESTROY."
    subtitle.TextColor3 = COLORS.primary
    subtitle.TextSize = 24
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Parent = logoContainer
    
    -- Animated glow
    task.spawn(function()
        while logoContainer.Parent do
            TweenService:Create(logoText, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {TextStrokeTransparency = 0.8}):Play()
            task.wait(2)
        end
    end)
    
    -- Main buttons container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "Buttons"
    buttonContainer.Size = UDim2.new(0, 350, 0, 400)
    buttonContainer.Position = UDim2.new(0.5, -175, 0.5, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = bg
    
    -- Play Button
    self:CreateMenuButton(buttonContainer, "PLAY", 0, COLORS.primary, function()
        self:HideMenu()
    end)
    
    -- Shop Button
    self:CreateMenuButton(buttonContainer, "SHOP", 1, COLORS.secondary, function()
        self:OpenShop()
    end)
    
    -- Inventory Button
    self:CreateMenuButton(buttonContainer, "INVENTORY", 2, COLORS.accent, function()
        self:OpenInventory()
    end)
    
    -- Settings Button
    self:CreateMenuButton(buttonContainer, "SETTINGS", 3, COLORS.gray, function()
        self:OpenSettings()
    end)
    
    -- Credits
    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(0, 400, 0, 30)
    credits.Position = UDim2.new(0.5, -200, 1, -40)
    credits.BackgroundTransparency = 1
    credits.Text = "Created with passion for the Roblox community"
    credits.TextColor3 = COLORS.gray
    credits.TextSize = 14
    credits.Font = Enum.Font.Gotham
    credits.Parent = bg
    
    -- Player stats sidebar
    self:CreateStatsPanel(bg)
end

function MainMenu:CreateMenuButton(parent, text, index, color, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = UDim2.new(1, 0, 0, 60)
    button.Position = UDim2.new(0, 0, 0, index * 75)
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = COLORS.light
    button.TextSize = 24
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.8
    stroke.Thickness = 2
    stroke.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(1.05, 0, 0, 65)}):Play()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 60)}):Play()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function MainMenu:CreateStatsPanel(parent)
    local panel = Instance.new("Frame")
    panel.Name = "StatsPanel"
    panel.Size = UDim2.new(0, 280, 0, 350)
    panel.Position = UDim2.new(0, 30, 0.5, -175)
    panel.BackgroundColor3 = COLORS.dark
    panel.BackgroundTransparency = 0.3
    panel.BorderSizePixel = 0
    panel.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = panel
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "YOUR STATS"
    title.TextColor3 = COLORS.primary
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = panel
    
    local stats = {
        {"Level", "12"},
        {"Wins", "47"},
        {"Kills", "234"},
        {"Blocks Placed", "1,432"},
        {"Play Time", "12h 30m"}
    }
    
    for i, stat in ipairs(stats) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 45)
        row.Position = UDim2.new(0, 10, 0, 50 + (i-1) * 50)
        row.BackgroundColor3 = COLORS.darker
        row.BackgroundTransparency = 0.5
        row.Parent = panel
        
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = stat[1]
        label.TextColor3 = COLORS.gray
        label.TextSize = 16
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        local value = Instance.new("TextLabel")
        value.Size = UDim2.new(0.5, -15, 1, 0)
        value.Position = UDim2.new(0.5, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = stat[2]
        value.TextColor3 = COLORS.light
        value.TextSize = 18
        value.Font = Enum.Font.GothamBold
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Parent = row
    end
end

function MainMenu:CreateSideMenu()
    local sideMenu = Instance.new("ScreenGui")
    sideMenu.Name = "SideMenu"
    sideMenu.ResetOnSpawn = false
    sideMenu.Enabled = false
    sideMenu.Parent = playerGui
    uiElements.sideMenu = sideMenu
    
    -- Menu button (always visible)
    local menuBtn = Instance.new("TextButton")
    menuBtn.Name = "MenuToggle"
    menuBtn.Size = UDim2.new(0, 50, 0, 50)
    menuBtn.Position = UDim2.new(0, 20, 0.5, -25)
    menuBtn.BackgroundColor3 = COLORS.primary
    menuBtn.Text = "☰"
    menuBtn.TextColor3 = COLORS.light
    menuBtn.TextSize = 28
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.Parent = sideMenu
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent = menuBtn

    -- Menu panel
    local panel = Instance.new("Frame")
    panel.Name = "MenuPanel"
    panel.Size = UDim2.new(0, 250, 1, 0)
    panel.Position = UDim2.new(0, -250, 0, 0)
    panel.BackgroundColor3 = COLORS.dark
    panel.BorderSizePixel = 0
    panel.Parent = sideMenu
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 0)
    panelCorner.Parent = panel
    
    -- Menu items
    local items = {"Resume", "Shop", "Inventory", "Settings", "Leave Game"}
    local colors = {COLORS.primary, COLORS.secondary, COLORS.accent, COLORS.gray, COLORS.danger}
    
    for i, item in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 50)
        btn.Position = UDim2.new(0, 10, 0, 80 + (i-1) * 60)
        btn.BackgroundColor3 = colors[i]
        btn.Text = item
        btn.TextColor3 = COLORS.light
        btn.TextSize = 20
        btn.Font = Enum.Font.GothamBold
        btn.Parent = panel
        
        local btnCorner2 = Instance.new("UICorner")
        btnCorner2.CornerRadius = UDim.new(0, 10)
        btnCorner2.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if item == "Resume" then
                self:ToggleSideMenu()
            elseif item == "Shop" then
                self:OpenShop()
            elseif item == "Inventory" then
                self:OpenInventory()
            elseif item == "Settings" then
                self:OpenSettings()
            elseif item == "Leave Game" then
                game:Shutdown()
            end
        end)
    end
    
    uiElements.menuPanel = panel
    uiElements.menuOpen = false
    
    menuBtn.MouseButton1Click:Connect(function()
        self:ToggleSideMenu()
    end)
end

function MainMenu:CreateFloatingParticles(parent)
    for i = 1, 20 do
        local particle = Instance.new("Frame")
        local size = math.random(4, 12)
        particle.Size = UDim2.new(0, size, 0, size)
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = COLORS.primary
        particle.BackgroundTransparency = math.random() * 0.5 + 0.3
        particle.BorderSizePixel = 0
        particle.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        -- Float animation
        task.spawn(function()
            while particle.Parent do
                local newY = math.random()
                local duration = math.random(5, 15)
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Position = UDim2.new(particle.Position.X.Scale, 0, newY, 0)}):Play()
                task.wait(duration)
            end
        end)
    end
end

function MainMenu:HideMenu()
    isMenuOpen = false
    uiElements.menu.Enabled = false
    uiElements.sideMenu.Enabled = true
    
    -- Enable HUD
    local hud = playerGui:FindFirstChild("ModernHUD")
    if hud then hud.Enabled = true end
end

function MainMenu:ShowMenu()
    isMenuOpen = true
    uiElements.menu.Enabled = true
    uiElements.sideMenu.Enabled = false
    
    -- Disable HUD
    local hud = playerGui:FindFirstChild("ModernHUD")
    if hud then hud.Enabled = false end
end

function MainMenu:ToggleSideMenu()
    uiElements.menuOpen = not uiElements.menuOpen
    
    if uiElements.menuOpen then
        TweenService:Create(uiElements.menuPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(0, 0, 0, 0)}):Play()
    else
        TweenService:Create(uiElements.menuPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(0, -250, 0, 0)}):Play()
    end
end

function MainMenu:OpenShop()
    -- Fire event to ShopSystem
    local shopEvent = Instance.new("BindableEvent")
    shopEvent.Name = "OpenShop"
    shopEvent.Parent = ReplicatedStorage
    shopEvent:Fire()
end

function MainMenu:OpenInventory()
    local invEvent = Instance.new("BindableEvent")
    invEvent.Name = "OpenInventory"
    invEvent.Parent = ReplicatedStorage
    invEvent:Fire()
end

function MainMenu:OpenSettings()
    print("Settings opened")
end

-- Listen for game phase to hide menu
function MainMenu:ConnectEvents()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameStateEvent = remotes:WaitForChild("GameStateEvent")
    
    gameStateEvent.OnClientEvent:Connect(function(type, data)
        if type == "PHASE" then
            if data == "BUILDING" or data == "COMBAT" then
                self:HideMenu()
            end
        elseif type == "MESSAGE" then
            -- Show broadcast messages
        end
    end)
end

MainMenu:Init()
MainMenu:ConnectEvents()
_G.MainMenu = MainMenu
