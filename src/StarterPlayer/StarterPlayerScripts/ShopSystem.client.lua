-- Build a Battles - Shop System
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ShopSystem = {}
local uiElements = {}
local isShopOpen = false

local COLORS = {
    primary = Color3.fromRGB(59, 130, 246),
    secondary = Color3.fromRGB(147, 51, 234),
    accent = Color3.fromRGB(236, 72, 153),
    success = Color3.fromRGB(34, 197, 94),
    dark = Color3.fromRGB(17, 24, 39),
    darker = Color3.fromRGB(11, 15, 25),
    light = Color3.fromRGB(243, 244, 246),
    gray = Color3.fromRGB(75, 85, 99),
}

-- Shop items data
local SHOP_ITEMS = {
    {
        category = "Blocks",
        items = {
            {name = "Neon Wood", type = "block_skin", id = "neon_wood", price = 500, color = Color3.fromRGB(0, 255, 255), rarity = "Rare"},
            {name = "Golden Stone", type = "block_skin", id = "golden_stone", price = 1000, color = Color3.fromRGB(255, 215, 0), rarity = "Epic"},
            {name = "Void Metal", type = "block_skin", id = "void_metal", price = 2000, color = Color3.fromRGB(138, 43, 226), rarity = "Legendary"},
            {name = "Rainbow Block", type = "block_skin", id = "rainbow", price = 5000, color = Color3.fromRGB(255, 0, 255), rarity = "Mythic"},
        }
    },
    {
        category = "Weapons",
        items = {
            {name = "Cyber Sword", type = "weapon_skin", id = "cyber_sword", price = 800, weapon = "SWORD", rarity = "Rare"},
            {name = "Plasma Bow", type = "weapon_skin", id = "plasma_bow", price = 1200, weapon = "BOW", rarity = "Epic"},
            {name = "Golden Launcher", type = "weapon_skin", id = "gold_rocket", price = 2500, weapon = "ROCKET", rarity = "Legendary"},
        }
    },
    {
        category = "Emotes",
        items = {
            {name = "Victory Dance", type = "emote", id = "victory_dance", price = 300, rarity = "Common"},
            {name = "Take the L", type = "emote", id = "take_l", price = 500, rarity = "Rare"},
            {name = "Floss", type = "emote", id = "floss", price = 800, rarity = "Epic"},
        }
    },
    {
        category = "Gamepasses",
        items = {
            {name = "VIP", type = "gamepass", id = 12345, price = 399, description = "2x coins, VIP badge, exclusive colors", robux = true},
            {name = "Builder's Pack", type = "gamepass", id = 12346, price = 299, description = "+100 block limit, instant placement", robux = true},
            {name = "Weapon Master", type = "gamepass", id = 12347, price = 499, description = "All weapon skins unlocked", robux = true},
        }
    }
}

function ShopSystem:Init()
    self:CreateShopUI()
    self:ConnectEvents()
    print("✅ Shop System Initialized")
end

function ShopSystem:CreateShopUI()
    local shop = Instance.new("ScreenGui")
    shop.Name = "ShopUI"
    shop.ResetOnSpawn = false
    shop.Enabled = false
    shop.Parent = playerGui
    uiElements.shop = shop
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = COLORS.darker
    bg.BackgroundTransparency = 0.1
    bg.Parent = shop
    
    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 900, 0, 600)
    main.Position = UDim2.new(0.5, -450, 0.5, -300)
    main.BackgroundColor3 = COLORS.dark
    main.BorderSizePixel = 0
    main.Parent = bg
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = COLORS.darker
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 40)
    title.Position = UDim2.new(0, 30, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "ITEM SHOP"
    title.TextColor3 = COLORS.primary
    title.TextSize = 32
    title.Font = Enum.Font.GothamBlack
    title.Parent = header
    
    -- Coin display
    local coinDisplay = Instance.new("Frame")
    coinDisplay.Size = UDim2.new(0, 150, 0, 45)
    coinDisplay.Position = UDim2.new(1, -320, 0, 17)
    coinDisplay.BackgroundColor3 = COLORS.darker
    coinDisplay.BorderSizePixel = 0
    coinDisplay.Parent = header
    
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 10)
    coinCorner.Parent = coinDisplay
    
    local coinIcon = Instance.new("TextLabel")
    coinIcon.Size = UDim2.new(0, 35, 0, 35)
    coinIcon.Position = UDim2.new(0, 5, 0.5, -17)
    coinIcon.BackgroundColor3 = COLORS.warning
    coinIcon.Text = "$"
    coinIcon.TextColor3 = COLORS.dark
    coinIcon.TextSize = 20
    coinIcon.Font = Enum.Font.GothamBold
    coinIcon.Parent = coinDisplay
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = coinIcon
    
    local coinText = Instance.new("TextLabel")
    coinText.Name = "ShopCoinText"
    coinText.Size = UDim2.new(0, 100, 0, 35)
    coinText.Position = UDim2.new(0, 45, 0.5, -17)
    coinText.BackgroundTransparency = 1
    coinText.Text = "0"
    coinText.TextColor3 = COLORS.warning
    coinText.TextSize = 24
    coinText.Font = Enum.Font.GothamBold
    coinText.TextXAlignment = Enum.TextXAlignment.Left
    coinText.Parent = coinDisplay
    
    uiElements.coinText = coinText
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 45, 0, 45)
    closeBtn.Position = UDim2.new(1, -60, 0, 17)
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
        self:CloseShop()
    end)
    
    -- Category tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "Tabs"
    tabContainer.Size = UDim2.new(0, 200, 1, -80)
    tabContainer.Position = UDim2.new(0, 0, 0, 80)
    tabContainer.BackgroundColor3 = COLORS.darker
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 0)
    tabCorner.Parent = tabContainer
    
    uiElements.tabs = {}
    uiElements.currentCategory = 1
    
    for i, category in ipairs(SHOP_ITEMS) do
        local tab = Instance.new("TextButton")
        tab.Name = category.category
        tab.Size = UDim2.new(1, -10, 0, 50)
        tab.Position = UDim2.new(0, 5, 0, 10 + (i-1) * 60)
        tab.BackgroundColor3 = i == 1 and COLORS.primary or COLORS.gray
        tab.Text = category.category
        tab.TextColor3 = COLORS.light
        tab.TextSize = 18
        tab.Font = Enum.Font.GothamBold
        tab.Parent = tabContainer
        
        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 10)
        tabBtnCorner.Parent = tab
        
        tab.MouseButton1Click:Connect(function()
            self:SelectCategory(i)
        end)
        
        uiElements.tabs[i] = tab
    end
    
    -- Items container
    local itemsContainer = Instance.new("ScrollingFrame")
    itemsContainer.Name = "ItemsContainer"
    itemsContainer.Size = UDim2.new(1, -220, 1, -90)
    itemsContainer.Position = UDim2.new(0, 210, 0, 85)
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.ScrollBarThickness = 8
    itemsContainer.ScrollBarImageColor3 = COLORS.primary
    itemsContainer.Parent = main
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 200, 0, 240)
    grid.CellPadding = UDim2.new(0, 15, 0, 15)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
    grid.Parent = itemsContainer
    
    uiElements.itemsContainer = itemsContainer
    
    self:LoadItems(1)
end

function ShopSystem:SelectCategory(index)
    uiElements.currentCategory = index
    
    for i, tab in ipairs(uiElements.tabs) do
        tab.BackgroundColor3 = i == index and COLORS.primary or COLORS.gray
    end
    
    self:LoadItems(index)
end

function ShopSystem:LoadItems(categoryIndex)
    local container = uiElements.itemsContainer
    
    -- Clear existing items
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local category = SHOP_ITEMS[categoryIndex]
    
    for _, item in ipairs(category.items) do
        local card = self:CreateItemCard(item)
        card.Parent = container
    end
end

function ShopSystem:CreateItemCard(item)
    local card = Instance.new("Frame")
    card.Name = item.name
    card.Size = UDim2.new(0, 200, 0, 240)
    card.BackgroundColor3 = COLORS.darker
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card
    
    -- Rarity color
    local rarityColors = {
        Common = Color3.fromRGB(169, 169, 169),
        Rare = Color3.fromRGB(0, 150, 255),
        Epic = Color3.fromRGB(150, 50, 200),
        Legendary = Color3.fromRGB(255, 165, 0),
        Mythic = Color3.fromRGB(255, 50, 100)
    }
    
    local rarityColor = rarityColors[item.rarity] or COLORS.gray
    
    -- Rarity bar
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(1, 0, 0, 4)
    rarityBar.BackgroundColor3 = rarityColor
    rarityBar.BorderSizePixel = 0
    rarityBar.Parent = card
    
    local rarityCorner = Instance.new("UICorner")
    rarityCorner.CornerRadius = UDim.new(0, 2)
    rarityCorner.Parent = rarityBar
    
    -- Preview
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 120, 0, 120)
    preview.Position = UDim2.new(0.5, -60, 0, 20)
    preview.BackgroundColor3 = item.color or COLORS.gray
    preview.BorderSizePixel = 0
    preview.Parent = card
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 10)
    previewCorner.Parent = preview
    
    -- Item name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 145)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.name
    nameLabel.TextColor3 = COLORS.light
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = card
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -10, 0, 18)
    rarityLabel.Position = UDim2.new(0, 5, 0, 168)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = item.rarity or "Special"
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.TextSize = 14
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = card
    
    -- Price button
    local priceBtn = Instance.new("TextButton")
    priceBtn.Size = UDim2.new(1, -20, 0, 40)
    priceBtn.Position = UDim2.new(0, 10, 0, 190)
    priceBtn.BackgroundColor3 = COLORS.success
    priceBtn.Text = item.robux and item.price .. " R$" or "$" .. item.price
    priceBtn.TextColor3 = COLORS.light
    priceBtn.TextSize = 18
    priceBtn.Font = Enum.Font.GothamBold
    priceBtn.Parent = card
    
    local priceCorner = Instance.new("UICorner")
    priceCorner.CornerRadius = UDim.new(0, 8)
    priceCorner.Parent = priceBtn
    
    priceBtn.MouseButton1Click:Connect(function()
        self:PurchaseItem(item)
    end)
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.dark}):Play()
    end)
    
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.darker}):Play()
    end)
    
    return card
end

function ShopSystem:PurchaseItem(item)
    if item.robux then
        -- Purchase with Robux
        MarketplaceService:PromptGamePassPurchase(player, item.id)
    else
        -- Purchase with in-game coins
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        local purchaseEvent = remotes:FindFirstChild("PurchaseItem")
        if purchaseEvent then
            purchaseEvent:FireServer(item.type, item.id)
        end
    end
end

function ShopSystem:OpenShop()
    isShopOpen = true
    uiElements.shop.Enabled = true
    
    -- Update coin display
    self:UpdateCoins()
    
    -- Animation
    local main = uiElements.shop.Background.MainFrame
    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back), 
        {Size = UDim2.new(0, 900, 0, 600)}):Play()
end

function ShopSystem:CloseShop()
    isShopOpen = false
    uiElements.shop.Enabled = false
end

function ShopSystem:UpdateCoins()
    -- Request coins from server
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local coinsRequest = remotes:FindFirstChild("GetCoins")
    if coinsRequest then
        local coins = coinsRequest:InvokeServer()
        uiElements.coinText.Text = tostring(coins)
    end
end

function ShopSystem:ConnectEvents()
    -- Listen for open shop event
    local openEvent = ReplicatedStorage:FindFirstChild("OpenShop")
    if openEvent then
        openEvent.Event:Connect(function()
            self:OpenShop()
        end)
    end
end

ShopSystem:Init()
_G.ShopSystem = ShopSystem
