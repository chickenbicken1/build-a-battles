-- PetUI - Shows equipped pets and luck boosts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage.Shared.Config)
local C = Config.COLORS

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")

local PetUI = {}
local uiElements = {}

function PetUI:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Pet UI Initialized")
end

-- Create UI
function PetUI:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Pet Frame (top left, below potential other UIs)
    local petFrame = Instance.new("Frame")
    petFrame.Name = "PetFrame"
    petFrame.Size = UDim2.new(0, 200, 0, 120)
    petFrame.Position = UDim2.new(0, 10, 0, 10)
    petFrame.BackgroundColor3 = C.dark
    petFrame.BackgroundTransparency = 0.2
    petFrame.BorderSizePixel = 0
    petFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = petFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "🐾 EQUIPPED PETS"
    title.TextColor3 = C.primary
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.Parent = petFrame
    
    -- Pets container
    local petsContainer = Instance.new("Frame")
    petsContainer.Name = "PetsContainer"
    petsContainer.Size = UDim2.new(1, -10, 1, -30)
    petsContainer.Position = UDim2.new(0, 5, 0, 25)
    petsContainer.BackgroundTransparency = 1
    petsContainer.Parent = petFrame
    
    uiElements.petsContainer = petsContainer
    
    -- Create 3 pet slots
    uiElements.petSlots = {}
    for i = 1, 3 do
        local slot = Instance.new("Frame")
        slot.Name = "PetSlot" .. i
        slot.Size = UDim2.new(0, 55, 0, 55)
        slot.Position = UDim2.new(0, (i-1) * 62, 0, 5)
        slot.BackgroundColor3 = C.darker
        slot.BorderSizePixel = 0
        slot.Parent = petsContainer
        
        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 8)
        slotCorner.Parent = slot
        
        -- Empty state
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyLabel"
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "?"
        emptyLabel.TextColor3 = C.gray
        emptyLabel.TextSize = 24
        emptyLabel.Font = Enum.Font.GothamBold
        emptyLabel.Parent = slot
        
        -- Pet info (hidden by default)
        local petIcon = Instance.new("TextLabel")
        petIcon.Name = "PetIcon"
        petIcon.Size = UDim2.new(1, 0, 0, 35)
        petIcon.BackgroundTransparency = 1
        petIcon.Text = ""
        petIcon.TextSize = 28
        petIcon.Visible = false
        petIcon.Parent = slot
        
        local luckLabel = Instance.new("TextLabel")
        luckLabel.Name = "LuckLabel"
        luckLabel.Size = UDim2.new(1, 0, 0, 15)
        luckLabel.Position = UDim2.new(0, 0, 1, -15)
        luckLabel.BackgroundTransparency = 1
        luckLabel.Text = ""
        luckLabel.TextColor3 = C.success
        luckLabel.TextSize = 10
        luckLabel.Font = Enum.Font.GothamBold
        luckLabel.Visible = false
        luckLabel.Parent = slot
        
        uiElements.petSlots[i] = {
            frame = slot,
            emptyLabel = emptyLabel,
            petIcon = petIcon,
            luckLabel = luckLabel
        }
    end
    
    -- Total Luck Display (bottom of frame)
    local luckFrame = Instance.new("Frame")
    luckFrame.Size = UDim2.new(1, -10, 0, 25)
    luckFrame.Position = UDim2.new(0, 5, 1, -5)
    luckFrame.BackgroundColor3 = C.darker
    luckFrame.BorderSizePixel = 0
    luckFrame.Parent = petFrame
    
    local luckCorner = Instance.new("UICorner")
    luckCorner.CornerRadius = UDim.new(0, 6)
    luckCorner.Parent = luckFrame
    
    local totalLuckLabel = Instance.new("TextLabel")
    totalLuckLabel.Name = "TotalLuck"
    totalLuckLabel.Size = UDim2.new(1, 0, 1, 0)
    totalLuckLabel.BackgroundTransparency = 1
    totalLuckLabel.Text = "Total Luck: 1.00x"
    totalLuckLabel.TextColor3 = C.success
    totalLuckLabel.TextSize = 12
    totalLuckLabel.Font = Enum.Font.GothamBold
    totalLuckLabel.Parent = luckFrame
    
    uiElements.totalLuckLabel = totalLuckLabel
end

-- Update pet display
function PetUI:UpdatePets(equippedPets, totalLuck)
    -- Clear all slots
    for _, slot in ipairs(uiElements.petSlots) do
        slot.emptyLabel.Visible = true
        slot.petIcon.Visible = false
        slot.luckLabel.Visible = false
        slot.frame.BackgroundColor3 = C.darker
    end
    
    -- Fill slots with equipped pets
    for i, pet in ipairs(equippedPets) do
        if i > 3 then break end -- Max 3 pets
        
        local slot = uiElements.petSlots[i]
        
        slot.emptyLabel.Visible = false
        slot.petIcon.Visible = true
        slot.luckLabel.Visible = true
        
        -- Set pet icon based on pet
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
        
        slot.petIcon.Text = icons[pet.id] or "❓"
        slot.petIcon.TextColor3 = pet.color
        
        slot.luckLabel.Text = string.format("+%.1fx", pet.luckBoost)
        
        -- Color frame based on rarity
        local rarityColors = {
            Common = Color3.fromRGB(169, 169, 169),
            Uncommon = Color3.fromRGB(50, 200, 50),
            Rare = Color3.fromRGB(50, 100, 255),
            Epic = Color3.fromRGB(150, 50, 200),
            Legendary = Color3.fromRGB(255, 200, 50),
            Mythic = Color3.fromRGB(255, 50, 150),
            Godlike = Color3.fromRGB(255, 50, 50),
            Secret = Color3.fromRGB(255, 215, 0)
        }
        
        slot.frame.BackgroundColor3 = rarityColors[pet.rarity] or C.darker
    end
    
    -- Update total luck
    if totalLuck then
        uiElements.totalLuckLabel.Text = string.format("Total Luck: %.2fx", totalLuck)
    end
end

-- Connect events
function PetUI:ConnectEvents()
    DataUpdateEvent.OnClientEvent:Connect(function(type, data)
        if type == "SYNC" then
            self:UpdatePets(data.equippedPets or {}, data.totalLuck)
        end
    end)
end

PetUI:Init()
return PetUI
