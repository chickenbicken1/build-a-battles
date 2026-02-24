-- PetUI - Shows equipped pets and luck multiplier
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config    = require(ReplicatedStorage.Shared.Config)
local C         = Config.COLORS

-- Wait for Remotes folder (RollService creates it)
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")
local EquipPetEvent   = Remotes:WaitForChild("EquipPetEvent")
local InventoryEvent  = Remotes:WaitForChild("InventoryEvent")

local PetUI = {}
local uiElements  = {}
local allPets     = {}   -- full pet inventory
local equippedPets= {}   -- currently equipped
local isOpen      = false

-- Pet emoji icons
local PET_ICONS = {
    skibidi  = "🚽",
    sigma    = "💪",
    ohio     = "👹",
    grimace  = "🥤",
    fanum    = "💰",
    quandale = "🐢",
    gronk    = "👶",
    rizzler  = "✨",
}

function PetUI:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Pet UI Initialized")
end

function PetUI:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name         = "PetUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent       = playerGui
    uiElements.screenGui   = screenGui

    -- ── Equipped pets HUD (top-right corner) ──
    local hudFrame = Instance.new("Frame")
    hudFrame.Name               = "PetHUD"
    hudFrame.Size               = UDim2.new(0, 160, 0, 60)
    hudFrame.Position           = UDim2.new(1, -170, 0, 10)
    hudFrame.BackgroundColor3   = C.darker
    hudFrame.BackgroundTransparency = 0.2
    hudFrame.BorderSizePixel    = 0
    hudFrame.Parent             = screenGui
    Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 10)

    local hudTitle = Instance.new("TextLabel")
    hudTitle.Size               = UDim2.new(1, 0, 0, 18)
    hudTitle.BackgroundTransparency = 1
    hudTitle.Text               = "PETS"
    hudTitle.TextColor3         = C.gray
    hudTitle.TextSize           = 11
    hudTitle.Font               = Enum.Font.GothamBold
    hudTitle.Parent             = hudFrame

    -- Three pet slots
    local slotContainer = Instance.new("Frame")
    slotContainer.Size               = UDim2.new(1, -10, 0, 36)
    slotContainer.Position           = UDim2.new(0, 5, 0, 20)
    slotContainer.BackgroundTransparency = 1
    slotContainer.Parent             = hudFrame

    local slotLayout = Instance.new("UIListLayout")
    slotLayout.FillDirection         = Enum.FillDirection.Horizontal
    slotLayout.Padding               = UDim.new(0, 6)
    slotLayout.HorizontalAlignment   = Enum.HorizontalAlignment.Center
    slotLayout.VerticalAlignment     = Enum.VerticalAlignment.Center
    slotLayout.Parent                = slotContainer

    local slots = {}
    for i = 1, 3 do
        local slot = Instance.new("Frame")
        slot.Size               = UDim2.new(0, 36, 0, 36)
        slot.BackgroundColor3   = C.dark
        slot.BorderSizePixel    = 0
        slot.Parent             = slotContainer
        Instance.new("UICorner", slot).CornerRadius = UDim.new(1, 0)

        local slotStroke = Instance.new("UIStroke")
        slotStroke.Color     = Color3.fromRGB(60, 65, 80)
        slotStroke.Thickness = 1.5
        slotStroke.Parent    = slot

        local ico = Instance.new("TextLabel")
        ico.Name               = "Icon"
        ico.Size               = UDim2.new(1, 0, 1, 0)
        ico.BackgroundTransparency = 1
        ico.Text               = "—"
        ico.TextColor3         = C.gray
        ico.TextSize           = 18
        ico.Font               = Enum.Font.GothamBold
        ico.Parent             = slot

        slots[i] = { frame = slot, icon = ico, stroke = slotStroke }
    end
    uiElements.slots = slots

    -- Open pet manager button
    local openBtn = Instance.new("TextButton")
    openBtn.Size               = UDim2.new(0, 160, 0, 26)
    openBtn.Position           = UDim2.new(1, -170, 0, 76)
    openBtn.BackgroundColor3   = C.darker
    openBtn.Text               = "🐾 MANAGE PETS [P]"
    openBtn.TextColor3         = C.light
    openBtn.TextSize           = 11
    openBtn.Font               = Enum.Font.GothamBold
    openBtn.Parent             = screenGui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 6)
    openBtn.MouseButton1Click:Connect(function() self:ToggleManager() end)

    -- ── Pet Manager Panel ──
    local managerFrame = Instance.new("Frame")
    managerFrame.Name               = "PetManager"
    managerFrame.Size               = UDim2.new(0, 480, 0, 380)
    managerFrame.Position           = UDim2.new(0.5, -240, 0.5, -190)
    managerFrame.BackgroundColor3   = C.dark
    managerFrame.BackgroundTransparency = 0.08
    managerFrame.BorderSizePixel    = 0
    managerFrame.Visible            = false
    managerFrame.Parent             = screenGui
    Instance.new("UICorner", managerFrame).CornerRadius = UDim.new(0, 14)
    uiElements.managerFrame = managerFrame

    local mStroke = Instance.new("UIStroke")
    mStroke.Color     = Color3.fromRGB(60, 65, 80)
    mStroke.Thickness = 1.5
    mStroke.Parent    = managerFrame

    -- Header
    local mHeader = Instance.new("Frame")
    mHeader.Size             = UDim2.new(1, 0, 0, 48)
    mHeader.BackgroundColor3 = C.darker
    mHeader.BorderSizePixel  = 0
    mHeader.Parent           = managerFrame
    Instance.new("UICorner", mHeader).CornerRadius = UDim.new(0, 14)

    local mTitle = Instance.new("TextLabel")
    mTitle.Size               = UDim2.new(1, -60, 1, 0)
    mTitle.Position           = UDim2.new(0, 16, 0, 0)
    mTitle.BackgroundTransparency = 1
    mTitle.Text               = "🐾 PET MANAGER"
    mTitle.TextColor3         = C.primary
    mTitle.TextSize           = 20
    mTitle.Font               = Enum.Font.GothamBlack
    mTitle.TextXAlignment     = Enum.TextXAlignment.Left
    mTitle.Parent             = mHeader

    local mClose = Instance.new("TextButton")
    mClose.Size               = UDim2.new(0, 34, 0, 34)
    mClose.Position           = UDim2.new(1, -44, 0, 7)
    mClose.BackgroundColor3   = C.danger
    mClose.Text               = "✕"
    mClose.TextColor3         = C.light
    mClose.TextSize           = 16
    mClose.Font               = Enum.Font.GothamBlack
    mClose.Parent             = mHeader
    Instance.new("UICorner", mClose).CornerRadius = UDim.new(0, 8)
    mClose.MouseButton1Click:Connect(function() self:ToggleManager() end)

    -- Grid of owned pets
    local petScroll = Instance.new("ScrollingFrame")
    petScroll.Name                  = "PetGrid"
    petScroll.Size                  = UDim2.new(1, -20, 1, -60)
    petScroll.Position              = UDim2.new(0, 10, 0, 54)
    petScroll.BackgroundTransparency = 1
    petScroll.ScrollBarThickness    = 5
    petScroll.ScrollBarImageColor3  = C.primary
    petScroll.Parent                = managerFrame
    uiElements.petScroll            = petScroll

    local petGrid = Instance.new("UIGridLayout")
    petGrid.CellSize                = UDim2.new(0, 110, 0, 130)
    petGrid.CellPadding             = UDim2.new(0, 10, 0, 10)
    petGrid.SortOrder               = Enum.SortOrder.LayoutOrder
    petGrid.Parent                  = petScroll

    -- P hotkey
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.P then self:ToggleManager() end
    end)
end

-- Update the 3 HUD slots
function PetUI:UpdateHUD()
    for i, slotData in ipairs(uiElements.slots) do
        local pet = equippedPets[i]
        if pet then
            local rc = Config.RARITIES[pet.rarity]
            slotData.icon.Text       = PET_ICONS[pet.id] or "🐾"
            slotData.stroke.Color    = rc and rc.color or C.gray
            slotData.frame.BackgroundColor3 = C.darker
        else
            slotData.icon.Text       = "—"
            slotData.stroke.Color    = Color3.fromRGB(60, 65, 80)
            slotData.frame.BackgroundColor3 = C.dark
        end
    end
end

-- Populate pet grid in manager
function PetUI:PopulateGrid()
    for _, child in ipairs(uiElements.petScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local order = 0
    for _, pet in ipairs(allPets) do
        order = order + 1
        local rc = Config.RARITIES[pet.rarity]

        local card = Instance.new("Frame")
        card.Size             = UDim2.new(0, 110, 0, 130)
        card.BackgroundColor3 = C.darker
        card.BorderSizePixel  = 0
        card.LayoutOrder      = order
        card.Parent           = uiElements.petScroll
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

        local cStroke = Instance.new("UIStroke")
        cStroke.Color     = rc and rc.color or C.gray
        cStroke.Thickness = 1.5
        cStroke.Parent    = card

        local ico = Instance.new("TextLabel")
        ico.Size               = UDim2.new(1, 0, 0, 60)
        ico.Position           = UDim2.new(0, 0, 0, 6)
        ico.BackgroundTransparency = 1
        ico.Text               = PET_ICONS[pet.id] or "🐾"
        ico.TextSize           = 40
        ico.Parent             = card

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size               = UDim2.new(1, -8, 0, 30)
        nameLbl.Position           = UDim2.new(0, 4, 0, 68)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = pet.name
        nameLbl.TextColor3         = rc and rc.color or C.light
        nameLbl.TextSize           = 11
        nameLbl.Font               = Enum.Font.GothamBold
        nameLbl.TextWrapped        = true
        nameLbl.Parent             = card

        local luckLbl = Instance.new("TextLabel")
        luckLbl.Size               = UDim2.new(1, -8, 0, 16)
        luckLbl.Position           = UDim2.new(0, 4, 0, 98)
        luckLbl.BackgroundTransparency = 1
        luckLbl.Text               = "🍀 " .. pet.luckBoost .. "x"
        luckLbl.TextColor3         = C.success
        luckLbl.TextSize           = 11
        luckLbl.Font               = Enum.Font.GothamBold
        luckLbl.Parent             = card

        -- Check if equipped
        local isEquipped = false
        for _, ep in ipairs(equippedPets) do
            if ep.id == pet.id then isEquipped = true break end
        end

        local equipBtn = Instance.new("TextButton")
        equipBtn.Size               = UDim2.new(1, -8, 0, 18)
        equipBtn.Position           = UDim2.new(0, 4, 0, 108)
        equipBtn.BackgroundColor3   = isEquipped and C.danger or C.success
        equipBtn.Text               = isEquipped and "UNEQUIP" or "EQUIP"
        equipBtn.TextColor3         = C.light
        equipBtn.TextSize           = 10
        equipBtn.Font               = Enum.Font.GothamBold
        equipBtn.Parent             = card
        Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 6)

        equipBtn.MouseButton1Click:Connect(function()
            if isEquipped then
                EquipPetEvent:FireServer(pet.id, "UNEQUIP")
            else
                EquipPetEvent:FireServer(pet.id, "EQUIP")
            end
        end)
    end

    -- Canvas size
    local cols = 4
    local rows = math.ceil(#allPets / cols)
    uiElements.petScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 140 + 10)
end

function PetUI:ToggleManager()
    isOpen = not isOpen
    uiElements.managerFrame.Visible = isOpen
    if isOpen then
        InventoryEvent:FireServer("GET_PETS")
        self:PopulateGrid()
    end
end

function PetUI:ConnectEvents()
    DataUpdateEvent.OnClientEvent:Connect(function(eventType, data)
        if eventType == "SYNC" then
            equippedPets = data.equippedPets or {}
            allPets      = data.allPets or {}
            self:UpdateHUD()
            if isOpen then self:PopulateGrid() end
        end
    end)

    EquipPetEvent.OnClientEvent:Connect(function(result)
        -- Refresh will come via next DataUpdateEvent SYNC
        if result == "FAILED" then
            print("Pet equip failed")
        end
    end)
end

PetUI:Init()
return PetUI
