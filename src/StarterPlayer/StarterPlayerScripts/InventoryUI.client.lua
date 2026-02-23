-- InventoryUI - Shows all collected auras
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local C = Config.COLORS

local InventoryUI = {}
local uiElements = {}
local inventoryData = {}
local isOpen = false

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InventoryEvent = Instance.new("RemoteEvent")
InventoryEvent.Name = "InventoryEvent"
InventoryEvent.Parent = Remotes

function InventoryUI:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Inventory UI Initialized")
end

function InventoryUI:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    uiElements.screenGui = screenGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = C.dark
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    uiElements.mainFrame = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = C.darker
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎒 AURA INVENTORY"
    title.TextColor3 = C.primary
    title.TextSize = 24
    title.Font = Enum.Font.GothamBlack
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0, 100, 1, 0)
    countLabel.Position = UDim2.new(1, -120, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0/99"
    countLabel.TextColor3 = C.gray
    countLabel.TextSize = 16
    countLabel.Font = Enum.Font.GothamBold
    countLabel.Parent = header
    
    uiElements.countLabel = countLabel
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 5)
    closeBtn.BackgroundColor3 = C.danger
    closeBtn.Text = "X"
    closeBtn.TextColor3 = C.light
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Rarity Filter
    local filterFrame = Instance.new("Frame")
    filterFrame.Size = UDim2.new(1, -20, 0, 35)
    filterFrame.Position = UDim2.new(0, 10, 0, 55)
    filterFrame.BackgroundTransparency = 1
    filterFrame.Parent = mainFrame
    
    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 8)
    filterLayout.Parent = filterFrame
    
    local rarities = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godlike", "Secret"}
    for _, rarity in ipairs(rarities) do
        local btn = Instance.new("TextButton")
        btn.Name = rarity .. "Filter"
        btn.Size = UDim2.new(0, 60, 0, 30)
        btn.BackgroundColor3 = rarity == "All" and C.primary or C.darker
        btn.Text = rarity
        btn.TextColor3 = rarity == "All" and C.dark or C.light
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.Parent = filterFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:FilterByRarity(rarity)
            -- Update button colors
            for _, child in ipairs(filterFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = C.darker
                    child.TextColor3 = C.light
                end
            end
            btn.BackgroundColor3 = C.primary
            btn.TextColor3 = C.dark
        end)
    end
    
    -- Scrolling Grid
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "InventoryGrid"
    scrollFrame.Size = UDim2.new(1, -20, 1, -100)
    scrollFrame.Position = UDim2.new(0, 10, 0, 95)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = C.primary
    scrollFrame.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim.new(0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    uiElements.scrollFrame = scrollFrame
    uiElements.gridLayout = gridLayout
    
    -- Equip Button (bottom)
    local equipBtn = Instance.new("TextButton")
    equipBtn.Name = "EquipButton"
    equipBtn.Size = UDim2.new(0, 200, 0, 40)
    equipBtn.Position = UDim2.new(0.5, -100, 1, -50)
    equipBtn.BackgroundColor3 = C.success
    equipBtn.Text = "EQUIP SELECTED"
    equipBtn.TextColor3 = C.light
    equipBtn.TextSize = 16
    equipBtn.Font = Enum.Font.GothamBold
    equipBtn.Visible = false
    equipBtn.Parent = mainFrame
    
    local equipCorner = Instance.new("UICorner")
    equipCorner.CornerRadius = UDim.new(0, 8)
    equipCorner.Parent = equipBtn
    
    uiElements.equipBtn = equipBtn
    
    -- Hotkey (I for Inventory)
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.I then
            self:Toggle()
        end
    end)
end

function InventoryUI:CreateAuraCard(aura, index)
    local card = Instance.new("Frame")
    card.Name = aura.id .. "_" .. index
    card.Size = UDim2.new(0, 100, 0, 120)
    card.BackgroundColor3 = C.darker
    card.BorderSizePixel = 0
    card.LayoutOrder = self:GetRarityOrder(aura.rarity)
    
    local rarityConfig = Config.RARITIES[aura.rarity]
    
    -- Rarity border
    local border = Instance.new("UIStroke")
    border.Color = rarityConfig and rarityConfig.color or C.gray
    border.Thickness = 2
    border.Parent = card
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Aura color preview
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 60, 0, 60)
    preview.Position = UDim2.new(0.5, -30, 0, 10)
    preview.BackgroundColor3 = aura.particleColor or C.gray
    preview.BorderSizePixel = 0
    preview.Parent = card
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(1, 0)
    previewCorner.Parent = preview
    
    -- Glow effect for rare auras
    if aura.rarity == "Legendary" or aura.rarity == "Mythic" or aura.rarity == "Godlike" or aura.rarity == "Secret" then
        local glow = Instance.new("UIStroke")
        glow.Color = aura.particleColor
        glow.Thickness = 3
        glow.Transparency = 0.5
        glow.Parent = preview
    end
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 75)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = aura.name
    nameLabel.TextColor3 = rarityConfig and rarityConfig.color or C.light
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextWrapped = true
    nameLabel.Parent = card
    
    -- Rarity
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, -10, 0, 15)
    rarityLabel.Position = UDim2.new(0, 5, 0, 100)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = aura.rarity
    rarityLabel.TextColor3 = rarityConfig and rarityConfig.color or C.gray
    rarityLabel.TextSize = 10
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = card
    
    -- Click to select
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        self:SelectAura(aura, card)
    end)
    
    return card
end

function InventoryUI:GetRarityOrder(rarity)
    local orders = {
        Secret = 1,
        Godlike = 2,
        Mythic = 3,
        Legendary = 4,
        Epic = 5,
        Rare = 6,
        Uncommon = 7,
        Common = 8
    }
    return orders[rarity] or 9
end

function InventoryUI:UpdateInventory(auras)
    inventoryData = auras or {}
    
    -- Clear existing
    for _, child in ipairs(uiElements.scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create cards
    for i, auraData in ipairs(inventoryData) do
        for _, aura in ipairs(Config.AURAS) do
            if aura.id == auraData.auraId then
                local card = self:CreateAuraCard(aura, i)
                card.Parent = uiElements.scrollFrame
                break
            end
        end
    end
    
    -- Update count
    uiElements.countLabel.Text = string.format("%d/99", #inventoryData)
    
    -- Update canvas size
    local gridLayout = uiElements.gridLayout
    local rows = math.ceil(#inventoryData / 5)
    uiElements.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 130)
end

function InventoryUI:SelectAura(aura, card)
    -- Deselect all
    for _, child in ipairs(uiElements.scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local border = child:FindFirstChildOfClass("UIStroke")
            if border then
                border.Thickness = 2
            end
        end
    end
    
    -- Select this one
    local border = card:FindFirstChildOfClass("UIStroke")
    if border then
        border.Thickness = 4
    end
    
    uiElements.selectedAura = aura
    uiElements.equipBtn.Visible = true
end

function InventoryUI:FilterByRarity(rarity)
    for _, child in ipairs(uiElements.scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local rarityLabel = child:FindFirstChild("Rarity")
            if rarityLabel then
                if rarity == "All" or rarityLabel.Text == rarity then
                    child.Visible = true
                else
                    child.Visible = false
                end
            end
        end
    end
end

function InventoryUI:Toggle()
    isOpen = not isOpen
    uiElements.mainFrame.Visible = isOpen
    
    if isOpen then
        -- Request inventory data
        InventoryEvent:FireServer("GET_INVENTORY")
    end
end

function InventoryUI:ConnectEvents()
    InventoryEvent.OnClientEvent:Connect(function(action, data)
        if action == "INVENTORY_DATA" then
            self:UpdateInventory(data)
        end
    end)
    
    uiElements.equipBtn.MouseButton1Click:Connect(function()
        if uiElements.selectedAura then
            InventoryEvent:FireServer("EQUIP_AURA", uiElements.selectedAura.id)
            self:Toggle()
        end
    end)
end

InventoryUI:Init()
return InventoryUI
