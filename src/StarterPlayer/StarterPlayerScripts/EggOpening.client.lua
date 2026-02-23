-- EggOpening - Client-side egg opening animation and UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage.Shared.Config)
local C = Config.COLORS

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggEvent = Remotes:WaitForChild("EggEvent")

local EggOpening = {}
local uiElements = {}

function EggOpening:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Egg Opening UI Initialized")
end

function EggOpening:CreateUI()
    -- Confirmation Frame
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 350, 0, 200)
    confirmFrame.Position = UDim2.new(0.5, -175, 0.5, -100)
    confirmFrame.BackgroundColor3 = C.dark
    confirmFrame.BackgroundTransparency = 0.1
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Visible = false
    confirmFrame.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = confirmFrame
    
    uiElements.confirmFrame = confirmFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Open Egg?"
    title.TextColor3 = C.primary
    title.TextSize = 28
    title.Font = Enum.Font.GothamBlack
    title.Parent = confirmFrame
    
    -- Egg name
    local eggNameLabel = Instance.new("TextLabel")
    eggNameLabel.Name = "EggName"
    eggNameLabel.Size = UDim2.new(1, 0, 0, 30)
    eggNameLabel.Position = UDim2.new(0, 0, 0, 45)
    eggNameLabel.BackgroundTransparency = 1
    eggNameLabel.Text = "Basic Egg"
    eggNameLabel.TextColor3 = C.light
    eggNameLabel.TextSize = 20
    eggNameLabel.Font = Enum.Font.GothamBold
    eggNameLabel.Parent = confirmFrame
    
    uiElements.eggNameLabel = eggNameLabel
    
    -- Cost
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, 0, 0, 25)
    costLabel.Position = UDim2.new(0, 0, 0, 80)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = "💎 100"
    costLabel.TextColor3 = C.primary
    costLabel.TextSize = 24
    costLabel.Font = Enum.Font.GothamBold
    costLabel.Parent = confirmFrame
    
    uiElements.costLabel = costLabel
    
    -- Yes Button
    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0, 140, 0, 50)
    yesBtn.Position = UDim2.new(0, 20, 1, -70)
    yesBtn.BackgroundColor3 = C.success
    yesBtn.Text = "OPEN"
    yesBtn.TextColor3 = C.light
    yesBtn.TextSize = 20
    yesBtn.Font = Enum.Font.GothamBlack
    yesBtn.Parent = confirmFrame
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 10)
    yesCorner.Parent = yesBtn
    
    uiElements.yesBtn = yesBtn
    
    -- No Button
    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0, 140, 0, 50)
    noBtn.Position = UDim2.new(1, -160, 1, -70)
    noBtn.BackgroundColor3 = C.danger
    noBtn.Text = "CANCEL"
    noBtn.TextColor3 = C.light
    noBtn.TextSize = 20
    noBtn.Font = Enum.Font.GothamBlack
    noBtn.Parent = confirmFrame
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 10)
    noCorner.Parent = noBtn
    
    noBtn.MouseButton1Click:Connect(function()
        self:HideConfirm()
    end)
    
    -- Opening Animation Frame
    local openingFrame = Instance.new("Frame")
    openingFrame.Name = "OpeningFrame"
    openingFrame.Size = UDim2.new(1, 0, 1, 0)
    openingFrame.BackgroundColor3 = C.darker
    openingFrame.BackgroundTransparency = 0.5
    openingFrame.Visible = false
    openingFrame.Parent = playerGui
    
    uiElements.openingFrame = openingFrame
    
    -- Egg
    local egg = Instance.new("Frame")
    egg.Name = "Egg"
    egg.Size = UDim2.new(0, 200, 0, 250)
    egg.Position = UDim2.new(0.5, -100, 0.5, -125)
    egg.BackgroundColor3 = C.gray
    egg.BorderSizePixel = 0
    egg.Parent = openingFrame
    
    local eggCorner = Instance.new("UICorner")
    eggCorner.CornerRadius = UDim.new(0.5, 0)
    eggCorner.Parent = egg
    
    uiElements.egg = egg
    
    -- Result Frame
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 400, 0, 300)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    resultFrame.BackgroundColor3 = C.dark
    resultFrame.BackgroundTransparency = 0.1
    resultFrame.BorderSizePixel = 0
    resultFrame.Visible = false
    resultFrame.Parent = playerGui
    
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 16)
    resultCorner.Parent = resultFrame
    
    uiElements.resultFrame = resultFrame
    
    -- Result Title
    local resultTitle = Instance.new("TextLabel")
    resultTitle.Size = UDim2.new(1, 0, 0, 50)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Text = "🎉 YOU GOT!"
    resultTitle.TextColor3 = C.success
    resultTitle.TextSize = 32
    resultTitle.Font = Enum.Font.GothamBlack
    resultTitle.Parent = resultFrame
    
    -- Pet Icon
    local petIcon = Instance.new("TextLabel")
    petIcon.Name = "PetIcon"
    petIcon.Size = UDim2.new(0, 150, 0, 150)
    petIcon.Position = UDim2.new(0.5, -75, 0, 60)
    petIcon.BackgroundColor3 = C.darker
    petIcon.Text = "❓"
    petIcon.TextSize = 80
    petIcon.Parent = resultFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 20)
    iconCorner.Parent = petIcon
    
    uiElements.petIcon = petIcon
    
    -- Pet Name
    local petName = Instance.new("TextLabel")
    petName.Name = "PetName"
    petName.Size = UDim2.new(1, 0, 0, 40)
    petName.Position = UDim2.new(0, 0, 0, 220)
    petName.BackgroundTransparency = 1
    petName.Text = "???"
    petName.TextColor3 = C.light
    petName.TextSize = 28
    petName.Font = Enum.Font.GothamBold
    petName.Parent = resultFrame
    
    uiElements.petName = petName
    
    -- Rarity
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "RarityLabel"
    rarityLabel.Size = UDim2.new(1, 0, 0, 25)
    rarityLabel.Position = UDim2.new(0, 0, 0, 260)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = "Common"
    rarityLabel.TextColor3 = C.gray
    rarityLabel.TextSize = 18
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = resultFrame
    
    uiElements.rarityLabel = rarityLabel
    
    -- Continue Button
    local continueBtn = Instance.new("TextButton")
    continueBtn.Size = UDim2.new(0, 200, 0, 50)
    continueBtn.Position = UDim2.new(0.5, -100, 1, -60)
    continueBtn.BackgroundColor3 = C.primary
    continueBtn.Text = "AWESOME!"
    continueBtn.TextColor3 = C.dark
    continueBtn.TextSize = 20
    continueBtn.Font = Enum.Font.GothamBlack
    continueBtn.Parent = resultFrame
    
    local continueCorner = Instance.new("UICorner")
    continueCorner.CornerRadius = UDim.new(0, 10)
    continueCorner.Parent = continueBtn
    
    continueBtn.MouseButton1Click:Connect(function()
        self:HideResult()
    end)
end

function EggOpening:ShowConfirm(eggType, cost, eggName)
    uiElements.eggNameLabel.Text = eggName or eggType .. " Egg"
    uiElements.costLabel.Text = "💎 " .. tostring(cost)
    
    uiElements.confirmFrame.Visible = true
    
    -- Store egg type for opening
    uiElements.pendingEggType = eggType
    
    uiElements.yesBtn.MouseButton1Click:Connect(function()
        self:OpenEgg(uiElements.pendingEggType)
    end)
end

function EggOpening:HideConfirm()
    uiElements.confirmFrame.Visible = false
end

function EggOpening:OpenEgg(eggType)
    self:HideConfirm()
    uiElements.openingFrame.Visible = true
    
    -- Shake animation
    local egg = uiElements.egg
    local startPos = egg.Position
    
    -- Shake
    for i = 1, 30 do
        local offset = UDim2.new(0, math.random(-10, 10), 0, math.random(-10, 10))
        egg.Position = startPos + offset
        egg.Rotation = math.random(-5, 5)
        task.wait(0.05)
    end
    
    -- Send to server
    EggEvent:FireServer("OPEN_EGG", eggType)
end

function EggOpening:ShowResult(pet)
    uiElements.openingFrame.Visible = false
    uiElements.resultFrame.Visible = true
    
    -- Pet icons mapping
    local icons = {
        skibidi = "🚽",
        sigma = "💪",
        ohio = "👹",
        grimace = "🥤",
        fanum = "💰",
        quandale = "🐢",
        gronk = "👶",
        rizzler = "✨"
    }
    
    uiElements.petIcon.Text = icons[pet.id] or "❓"
    uiElements.petName.Text = pet.name
    uiElements.rarityLabel.Text = pet.rarity
    uiElements.rarityLabel.TextColor3 = pet.color
    uiElements.petIcon.TextColor3 = pet.color
    
    -- Animation
    uiElements.resultFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(uiElements.resultFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 400, 0, 300)
    }):Play()
end

function EggOpening:HideResult()
    uiElements.resultFrame.Visible = false
end

function EggOpening:ConnectEvents()
    EggEvent.OnClientEvent:Connect(function(action, data)
        if action == "CONFIRM_OPEN" then
            self:ShowConfirm(data.eggType, data.cost, data.eggName)
        elseif action == "ERROR" then
            -- Show error notification
            print("Error:", data)
        elseif action == "EGG_OPENED" then
            self:ShowResult(data.pet)
        end
    end)
end

EggOpening:Init()
return EggOpening
