-- InventoryUI - Aura collection viewer with stacking, filter, and equip
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local player            = Players.LocalPlayer
local playerGui         = player:WaitForChild("PlayerGui")

local Config  = require(ReplicatedStorage.Shared.Config)
local Utils   = require(ReplicatedStorage.Shared.Utils)
local C       = Config.COLORS

-- Remotes — wait for RollService to create them first
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local InventoryEvent = Remotes:WaitForChild("InventoryEvent")

local InventoryUI  = {}
local uiElements   = {}
local inventoryData = {}   -- raw list from server
local isOpen        = false
local selectedAura  = nil
local currentFilter = "All"

-- ─────────────────────────────────────────────
-- Rarity display order (highest first)
-- ─────────────────────────────────────────────
local RARITY_ORDER = {
    Secret=1, Godlike=2, Mythic=3, Legendary=4, Epic=5, Rare=6, Uncommon=7, Common=8
}

local function GetRarityOrder(rarity)
    return RARITY_ORDER[rarity] or 9
end

-- ─────────────────────────────────────────────
-- Build stacked inventory (group duplicate aura IDs)
-- ─────────────────────────────────────────────
local function StackInventory(rawInventory)
    local counts = {}
    local order  = {}
    for _, item in ipairs(rawInventory) do
        local id = item.auraId
        if not counts[id] then
            counts[id] = 0
            table.insert(order, id)
        end
        counts[id] = counts[id] + 1
    end
    -- Return unique items with count
    local stacked = {}
    for _, id in ipairs(order) do
        -- Find aura config
        for _, aura in ipairs(Config.AURAS) do
            if aura.id == id then
                table.insert(stacked, { aura = aura, count = counts[id] })
                break
            end
        end
    end
    -- Sort by rarity then name
    table.sort(stacked, function(a, b)
        local oa = GetRarityOrder(a.aura.rarity)
        local ob = GetRarityOrder(b.aura.rarity)
        if oa ~= ob then return oa < ob end
        return a.aura.name < b.aura.name
    end)
    return stacked
end

-- ─────────────────────────────────────────────
-- Build UI
-- ─────────────────────────────────────────────
function InventoryUI:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Inventory UI Initialized")
end

function InventoryUI:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name          = "InventoryUI"
    screenGui.ResetOnSpawn  = false
    screenGui.DisplayOrder  = 10
    screenGui.Parent        = playerGui
    uiElements.screenGui    = screenGui

    -- ── Main Frame ──
    local main = Instance.new("Frame")
    main.Name                  = "MainFrame"
    main.Size                  = UDim2.new(0, 620, 0, 420)
    main.Position              = UDim2.new(0.5, -310, 0.5, -210)
    main.BackgroundColor3      = C.dark
    main.BackgroundTransparency = 0.08
    main.BorderSizePixel       = 0
    main.Visible               = false
    main.Parent                = screenGui
    uiElements.mainFrame       = main

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(60, 65, 80)
    stroke.Thickness = 1.5
    stroke.Parent    = main

    -- ── Header ──
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = C.darker
    header.BorderSizePixel  = 0
    header.Parent           = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size               = UDim2.new(1, -120, 1, 0)
    titleLbl.Position           = UDim2.new(0, 16, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "🎒  AURA INVENTORY"
    titleLbl.TextColor3         = C.primary
    titleLbl.TextSize           = 20
    titleLbl.Font               = Enum.Font.GothamBlack
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    titleLbl.Parent             = header

    local countLbl = Instance.new("TextLabel")
    countLbl.Name               = "CountLabel"
    countLbl.Size               = UDim2.new(0, 80, 1, 0)
    countLbl.Position           = UDim2.new(1, -130, 0, 0)
    countLbl.BackgroundTransparency = 1
    countLbl.Text               = "0 auras"
    countLbl.TextColor3         = C.gray
    countLbl.TextSize           = 13
    countLbl.Font               = Enum.Font.GothamBold
    countLbl.Parent             = header
    uiElements.countLabel       = countLbl

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size               = UDim2.new(0, 36, 0, 36)
    closeBtn.Position           = UDim2.new(1, -46, 0, 7)
    closeBtn.BackgroundColor3   = C.danger
    closeBtn.Text               = "✕"
    closeBtn.TextColor3         = C.light
    closeBtn.TextSize           = 18
    closeBtn.Font               = Enum.Font.GothamBlack
    closeBtn.Parent             = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() self:Toggle() end)

    -- ── Rarity Filter Row ──
    local filterRow = Instance.new("Frame")
    filterRow.Size               = UDim2.new(1, -20, 0, 30)
    filterRow.Position           = UDim2.new(0, 10, 0, 55)
    filterRow.BackgroundTransparency = 1
    filterRow.Parent             = main
    uiElements.filterRow         = filterRow

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection   = Enum.FillDirection.Horizontal
    filterLayout.Padding         = UDim.new(0, 6)
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Parent          = filterRow

    local rarities = {"All","Common","Uncommon","Rare","Epic","Legendary","Mythic","Godlike","Secret"}
    for _, r in ipairs(rarities) do
        local rc = Config.RARITIES[r]
        local btn = Instance.new("TextButton")
        btn.Name               = r .. "Filter"
        btn.Size               = UDim2.new(0, 56, 0, 26)
        btn.BackgroundColor3   = r == "All" and C.primary or C.darker
        btn.Text               = r == "All" and "All" or r:sub(1, 3)
        btn.TextColor3         = r == "All" and C.dark or (rc and rc.color or C.light)
        btn.TextSize           = 10
        btn.Font               = Enum.Font.GothamBold
        btn.Parent             = filterRow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            currentFilter = r
            self:RefreshGrid()
            -- Update filter button states
            for _, child in ipairs(filterRow:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = C.darker
                    local childRc = Config.RARITIES[child.Name:gsub("Filter","")]
                    child.TextColor3 = childRc and childRc.color or C.light
                end
            end
            btn.BackgroundColor3 = rc and rc.color or C.primary
            btn.TextColor3 = C.dark
        end)
    end

    -- ── Scrolling Grid ──
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                  = "InventoryGrid"
    scroll.Size                  = UDim2.new(1, -20, 1, -100)
    scroll.Position              = UDim2.new(0, 10, 0, 91)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness    = 5
    scroll.ScrollBarImageColor3  = C.primary
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.Parent                = main
    uiElements.scroll            = scroll

    local grid = Instance.new("UIGridLayout")
    grid.CellSize                = UDim2.new(0, 108, 0, 128)
    grid.CellPadding             = UDim2.new(0, 10, 0, 10)
    grid.SortOrder               = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment     = Enum.HorizontalAlignment.Left
    grid.Parent                  = scroll
    uiElements.grid              = grid

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingLeft   = UDim.new(0, 4)
    pad.Parent        = scroll

    -- ── Equip Button (bottom) ──
    local equipBtn = Instance.new("TextButton")
    equipBtn.Name               = "EquipButton"
    equipBtn.Size               = UDim2.new(0, 220, 0, 36)
    equipBtn.Position           = UDim2.new(0.5, -110, 1, -48)
    equipBtn.BackgroundColor3   = C.success
    equipBtn.Text               = "✓  EQUIP SELECTED"
    equipBtn.TextColor3         = C.light
    equipBtn.TextSize           = 15
    equipBtn.Font               = Enum.Font.GothamBold
    equipBtn.Visible            = false
    equipBtn.Parent             = main
    equipBtn.AutoButtonColor    = false
    Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 8)
    uiElements.equipBtn         = equipBtn

    equipBtn.MouseButton1Click:Connect(function()
        if selectedAura then
            InventoryEvent:FireServer("EQUIP_AURA", selectedAura.id)
            self:Toggle()
        end
    end)

    -- ── Keyboard toggle ──
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.I then
            self:Toggle()
        end
    end)
end

-- ─────────────────────────────────────────────
-- Create aura card
-- ─────────────────────────────────────────────
function InventoryUI:CreateAuraCard(entry, order)
    local aura = entry.aura
    local count = entry.count
    local rc = Config.RARITIES[aura.rarity]

    local card = Instance.new("Frame")
    card.Name            = aura.id
    card.Size            = UDim2.new(0, 108, 0, 128)
    card.BackgroundColor3 = C.darker
    card.BorderSizePixel = 0
    card.LayoutOrder     = order

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    -- Border
    local border = Instance.new("UIStroke")
    border.Color     = rc and rc.color or C.gray
    border.Thickness = 1.5
    border.Parent    = card

    -- Aura color orb preview
    local orb = Instance.new("Frame")
    orb.Size               = UDim2.new(0, 64, 0, 64)
    orb.Position           = UDim2.new(0.5, -32, 0, 10)
    orb.BackgroundColor3   = aura.particleColor or C.gray
    orb.BorderSizePixel    = 0
    orb.Parent             = card
    Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)

    -- Glow outline for Legendary+
    if GetRarityOrder(aura.rarity) <= 4 then
        local glow = Instance.new("UIStroke")
        glow.Color       = aura.particleColor or rc.color
        glow.Thickness   = 4
        glow.Transparency = 0.4
        glow.Parent      = orb
    end

    -- Rarity-based icon overlay
    local icons = {
        Legendary = "⭐", Mythic = "🌟", Godlike = "👑", Secret = "∞"
    }
    if icons[aura.rarity] then
        local ico = Instance.new("TextLabel")
        ico.Size               = UDim2.new(1, 0, 1, 0)
        ico.BackgroundTransparency = 1
        ico.Text               = icons[aura.rarity]
        ico.TextSize           = 22
        ico.Parent             = orb
    end

    -- Name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size               = UDim2.new(1, -8, 0, 28)
    nameLbl.Position           = UDim2.new(0, 4, 0, 78)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text               = aura.name
    nameLbl.TextColor3         = rc and rc.color or C.light
    nameLbl.TextSize           = 12
    nameLbl.Font               = Enum.Font.GothamBold
    nameLbl.TextWrapped        = true
    nameLbl.Parent             = card

    -- Rarity tag
    local rarityLbl = Instance.new("TextLabel")
    rarityLbl.Name             = "RarityLabel"  -- used by filter
    rarityLbl.Size             = UDim2.new(1, -8, 0, 14)
    rarityLbl.Position         = UDim2.new(0, 4, 0, 107)
    rarityLbl.BackgroundTransparency = 1
    rarityLbl.Text             = aura.rarity
    rarityLbl.TextColor3       = rc and rc.color or C.gray
    rarityLbl.TextSize         = 10
    rarityLbl.Font             = Enum.Font.Gotham
    rarityLbl.Parent           = card

    -- Count badge (show if > 1)
    if count > 1 then
        local badge = Instance.new("Frame")
        badge.Size               = UDim2.new(0, 26, 0, 20)
        badge.Position           = UDim2.new(1, -28, 0, 4)
        badge.BackgroundColor3   = C.primary
        badge.BorderSizePixel    = 0
        badge.ZIndex             = 2
        badge.Parent             = card
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

        local countLbl = Instance.new("TextLabel")
        countLbl.Size               = UDim2.new(1, 0, 1, 0)
        countLbl.BackgroundTransparency = 1
        countLbl.Text               = "x" .. count
        countLbl.TextColor3         = C.dark
        countLbl.TextSize           = 11
        countLbl.Font               = Enum.Font.GothamBold
        countLbl.ZIndex             = 3
        countLbl.Parent             = badge
    end

    -- Click to select
    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""
    btn.ZIndex             = 4
    btn.Parent             = card

    btn.MouseButton1Click:Connect(function()
        self:SelectCard(aura, card)
    end)

    return card
end

-- ─────────────────────────────────────────────
-- Select a card
-- ─────────────────────────────────────────────
function InventoryUI:SelectCard(aura, card)
    selectedAura = aura

    -- Deselect all
    for _, child in ipairs(uiElements.scroll:GetChildren()) do
        if child:IsA("Frame") then
            local s = child:FindFirstChildOfClass("UIStroke")
            if s then s.Thickness = 1.5 end
        end
    end

    -- Highlight selected
    local s = card:FindFirstChildOfClass("UIStroke")
    if s then s.Thickness = 4 end

    uiElements.equipBtn.Visible = true
end

-- ─────────────────────────────────────────────
-- Refresh grid with filter applied
-- ─────────────────────────────────────────────
function InventoryUI:RefreshGrid()
    -- Clear grid
    for _, child in ipairs(uiElements.scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    selectedAura = nil
    uiElements.equipBtn.Visible = false

    local stacked = StackInventory(inventoryData)
    local shown, order = 0, 0

    for _, entry in ipairs(stacked) do
        -- Filter check
        if currentFilter == "All" or entry.aura.rarity == currentFilter then
            order = order + 1
            local card = self:CreateAuraCard(entry, order)
            card.Parent = uiElements.scroll
            shown = shown + 1
        end
    end

    -- Update count label
    local total = #StackInventory(inventoryData)
    uiElements.countLabel.Text = string.format("%d aura%s", total, total ~= 1 and "s" or "")

    -- Resize canvas
    local cols = math.max(1, math.floor((620 - 20) / (108 + 10)))
    local rows = math.ceil(shown / cols)
    uiElements.scroll.CanvasSize = UDim2.new(0, 0, 0, rows * (128 + 10) + 10)
end

-- ─────────────────────────────────────────────
-- Toggle open/close
-- ─────────────────────────────────────────────
function InventoryUI:Toggle()
    isOpen = not isOpen
    local frame = uiElements.mainFrame

    if isOpen then
        frame.Visible = true
        frame.Size    = UDim2.new(0, 300, 0, 200)
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 620, 0, 420)
        }):Play()
        -- Request data
        InventoryEvent:FireServer("GET_INVENTORY")
    else
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 300, 0, 200)
        }):Play()
        task.delay(0.2, function()
            frame.Visible = false
        end)
    end
end

-- ─────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────
function InventoryUI:ConnectEvents()
    InventoryEvent.OnClientEvent:Connect(function(action, data)
        if action == "INVENTORY_DATA" then
            inventoryData = data or {}
            self:RefreshGrid()
        elseif action == "EQUIP_SUCCESS" then
            -- Inventory closes on equip, already handled
        end
    end)
end

InventoryUI:Init()
return InventoryUI
