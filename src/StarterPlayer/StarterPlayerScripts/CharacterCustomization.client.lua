-- Build a Battles - Character Customization
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CharacterCustomization = {}
local uiElements = {}
local currentOutfit = {}

local COLORS = {
    primary = Color3.fromRGB(59, 130, 246),
    secondary = Color3.fromRGB(147, 51, 234),
    accent = Color3.fromRGB(236, 72, 153),
    dark = Color3.fromRGB(17, 24, 39),
    darker = Color3.fromRGB(11, 15, 25),
    light = Color3.fromRGB(243, 244, 246),
    gray = Color3.fromRGB(75, 85, 99),
}

-- Outfit presets
local OUTFITS = {
    {
        name = "Default Warrior",
        colors = {
            Head = Color3.fromRGB(255, 200, 150),
            LeftArm = Color3.fromRGB(255, 200, 150),
            RightArm = Color3.fromRGB(255, 200, 150),
            LeftLeg = Color3.fromRGB(50, 50, 60),
            RightLeg = Color3.fromRGB(50, 50, 60),
            Torso = Color3.fromRGB(100, 100, 110)
        }
    },
    {
        name = "Cyber Ninja",
        colors = {
            Head = Color3.fromRGB(30, 30, 35),
            LeftArm = Color3.fromRGB(20, 20, 25),
            RightArm = Color3.fromRGB(20, 20, 25),
            LeftLeg = Color3.fromRGB(20, 20, 25),
            RightLeg = Color3.fromRGB(20, 20, 25),
            Torso = Color3.fromRGB(30, 30, 35)
        }
    },
    {
        name = "Golden Knight",
        colors = {
            Head = Color3.fromRGB(255, 215, 150),
            LeftArm = Color3.fromRGB(255, 200, 100),
            RightArm = Color3.fromRGB(255, 200, 100),
            LeftLeg = Color3.fromRGB(200, 170, 80),
            RightLeg = Color3.fromRGB(200, 170, 80),
            Torso = Color3.fromRGB(255, 215, 0)
        }
    },
    {
        name = "Crimson Mercenary",
        colors = {
            Head = Color3.fromRGB(255, 180, 150),
            LeftArm = Color3.fromRGB(150, 30, 30),
            RightArm = Color3.fromRGB(150, 30, 30),
            LeftLeg = Color3.fromRGB(100, 20, 20),
            RightLeg = Color3.fromRGB(100, 20, 20),
            Torso = Color3.fromRGB(180, 40, 40)
        }
    }
}

-- Skin tones
local SKIN_TONES = {
    Color3.fromRGB(255, 220, 177),
    Color3.fromRGB(240, 200, 150),
    Color3.fromRGB(200, 150, 120),
    Color3.fromRGB(160, 110, 80),
    Color3.fromRGB(100, 60, 40),
    Color3.fromRGB(60, 40, 30)
}

function CharacterCustomization:Init()
    self:CreateCustomizationUI()
    self:ConnectEvents()
    print("Character Customization Initialized")
end

function CharacterCustomization:CreateCustomizationUI()
    local ui = Instance.new("ScreenGui")
    ui.Name = "CharacterCustomization"
    ui.ResetOnSpawn = false
    ui.Enabled = false
    ui.Parent = playerGui
    uiElements.ui = ui
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = COLORS.darker
    bg.BackgroundTransparency = 0.1
    bg.Parent = ui
    
    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = COLORS.dark
    main.BorderSizePixel = 0
    main.Parent = bg
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = COLORS.darker
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 300, 0, 40)
    title.Position = UDim2.new(0, 30, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "CHARACTER"
    title.TextColor3 = COLORS.primary
    title.TextSize = 28
    title.Font = Enum.Font.GothamBlack
    title.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 45, 0, 45)
    closeBtn.Position = UDim2.new(1, -60, 0, 12)
    closeBtn.BackgroundColor3 = COLORS.danger
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.light
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:CloseUI()
    end)
    
    -- Preview area (left)
    local previewArea = Instance.new("Frame")
    previewArea.Size = UDim2.new(0, 350, 1, -70)
    previewArea.Position = UDim2.new(0, 0, 0, 70)
    previewArea.BackgroundColor3 = COLORS.darker
    previewArea.BorderSizePixel = 0
    previewArea.Parent = main
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 20)
    previewCorner.Parent = previewArea
    
    local previewLabel = Instance.new("TextLabel")
    previewLabel.Size = UDim2.new(1, 0, 0, 30)
    previewLabel.Position = UDim2.new(0, 0, 0, 20)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = "PREVIEW"
    previewLabel.TextColor3 = COLORS.gray
    previewLabel.TextSize = 16
    previewLabel.Font = Enum.Font.GothamBold
    previewLabel.Parent = previewArea
    
    -- Customization options (right)
    local optionsArea = Instance.new("ScrollingFrame")
    optionsArea.Size = UDim2.new(1, -370, 1, -90)
    optionsArea.Position = UDim2.new(0, 360, 0, 80)
    optionsArea.BackgroundTransparency = 1
    optionsArea.ScrollBarThickness = 6
    optionsArea.ScrollBarImageColor3 = COLORS.primary
    optionsArea.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.Parent = optionsArea
    
    -- Outfit presets
    self:CreateSection(optionsArea, "OUTFIT PRESETS")
    local presetContainer = Instance.new("Frame")
    presetContainer.Size = UDim2.new(1, -10, 0, 100)
    presetContainer.BackgroundTransparency = 1
    presetContainer.Parent = optionsArea
    
    local presetLayout = Instance.new("UIGridLayout")
    presetLayout.CellSize = UDim2.new(0, 100, 0, 100)
    presetLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    presetLayout.Parent = presetContainer
    
    for i, outfit in ipairs(OUTFITS) do
        local btn = self:CreatePresetButton(presetContainer, outfit, i)
        btn.MouseButton1Click:Connect(function()
            self:ApplyOutfit(outfit)
        end)
    end
    
    -- Skin tone picker
    self:CreateSection(optionsArea, "SKIN TONE")
    local skinContainer = Instance.new("Frame")
    skinContainer.Size = UDim2.new(1, -10, 0, 50)
    skinContainer.BackgroundTransparency = 1
    skinContainer.Parent = optionsArea
    
    local skinLayout = Instance.new("UIListLayout")
    skinLayout.FillDirection = Enum.FillDirection.Horizontal
    skinLayout.Padding = UDim.new(0, 10)
    skinLayout.Parent = skinContainer
    
    for _, color in ipairs(SKIN_TONES) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.Parent = skinContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:ChangeSkinTone(color)
        end)
    end
    
    -- Color picker for body parts
    self:CreateSection(optionsArea, "BODY COLORS")
    local bodyParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    
    for _, partName in ipairs(bodyParts) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 45)
        row.BackgroundColor3 = COLORS.darker
        row.BorderSizePixel = 0
        row.Parent = optionsArea
        
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 120, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = partName
        label.TextColor3 = COLORS.light
        label.TextSize = 16
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        local colorBtn = Instance.new("TextButton")
        colorBtn.Name = partName:gsub(" ", "")
        colorBtn.Size = UDim2.new(0, 80, 0, 35)
        colorBtn.Position = UDim2.new(1, -95, 0.5, -17)
        colorBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        colorBtn.Text = "PICK"
        colorBtn.TextColor3 = COLORS.dark
        colorBtn.TextSize = 14
        colorBtn.Font = Enum.Font.GothamBold
        colorBtn.Parent = row
        
        local colorCorner = Instance.new("UICorner")
        colorCorner.CornerRadius = UDim.new(0, 6)
        colorCorner.Parent = colorBtn
    end
    
    -- Save button
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(1, -10, 0, 50)
    saveBtn.BackgroundColor3 = COLORS.success
    saveBtn.Text = "SAVE OUTFIT"
    saveBtn.TextColor3 = COLORS.light
    saveBtn.TextSize = 20
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Parent = optionsArea
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 10)
    saveCorner.Parent = saveBtn
    
    saveBtn.MouseButton1Click:Connect(function()
        self:SaveOutfit()
    end)
end

function CharacterCustomization:CreateSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = text
    section.TextColor3 = COLORS.gray
    section.TextSize = 14
    section.Font = Enum.Font.GothamBold
    section.Parent = parent
    return section
end

function CharacterCustomization:CreatePresetButton(parent, outfit, index)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 100)
    btn.BackgroundColor3 = outfit.colors.Torso
    btn.Text = outfit.name
    btn.TextColor3 = COLORS.light
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.TextWrapped = true
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.light
    stroke.Transparency = 0.8
    stroke.Thickness = 2
    stroke.Parent = btn
    
    return btn
end

function CharacterCustomization:ApplyOutfit(outfit)
    local character = player.Character
    if not character then return end
    
    for partName, color in pairs(outfit.colors) do
        local part = character:FindFirstChild(partName)
        if part then
            part.Color = color
        end
    end
    
    currentOutfit = outfit
end

function CharacterCustomization:ChangeSkinTone(color)
    local character = player.Character
    if not character then return end
    
    local parts = {"Head", "LeftArm", "RightArm"}
    for _, partName in ipairs(parts) do
        local part = character:FindFirstChild(partName)
        if part then
            part.Color = color
        end
    end
end

function CharacterCustomization:SaveOutfit()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local saveEvent = remotes:FindFirstChild("SaveOutfit")
    if saveEvent then
        saveEvent:FireServer(currentOutfit)
    end
    
    self:ShowNotification("Outfit Saved!")
end

function CharacterCustomization:ShowNotification(text)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, 50)
    notif.Position = UDim2.new(0.5, -125, 0, -60)
    notif.BackgroundColor3 = COLORS.success
    notif.BorderSizePixel = 0
    notif.Parent = uiElements.ui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notif
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.light
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.Parent = notif
    
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -125, 0, 20)}):Play()
    
    task.delay(2, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -125, 0, -60)}):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

function CharacterCustomization:OpenUI()
    uiElements.ui.Enabled = true
    
    local main = uiElements.ui.Background.MainFrame
    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back), 
        {Size = UDim2.new(0, 800, 0, 550)}):Play()
end

function CharacterCustomization:CloseUI()
    uiElements.ui.Enabled = false
end

function CharacterCustomization:ConnectEvents()
    local openEvent = ReplicatedStorage:FindFirstChild("OpenInventory")
    if openEvent then
        openEvent.Event:Connect(function()
            self:OpenUI()
        end)
    end
end

CharacterCustomization:Init()
_G.CharacterCustomization = CharacterCustomization
