-- EggShop - Server-side egg opening system
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local EggShop = {}

-- Setup Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggEvent = Instance.new("RemoteEvent")
EggEvent.Name = "EggEvent"
EggEvent.Parent = Remotes

-- Egg types with costs and drop rates
local EGG_TYPES = {
    Basic = {
        name = "Basic Egg",
        cost = 100,
        color = Color3.fromRGB(169, 169, 169),
        drops = {
            {petId = "skibidi", chance = 0.5},
            {petId = "sigma", chance = 0.35},
            {petId = "ohio", chance = 0.15}
        }
    },
    Rare = {
        name = "Rare Egg",
        cost = 500,
        color = Color3.fromRGB(50, 100, 255),
        drops = {
            {petId = "ohio", chance = 0.4},
            {petId = "grimace", chance = 0.35},
            {petId = "fanum", chance = 0.2},
            {petId = "quandale", chance = 0.05}
        }
    },
    Legendary = {
        name = "Legendary Egg",
        cost = 2000,
        color = Color3.fromRGB(255, 200, 50),
        drops = {
            {petId = "fanum", chance = 0.4},
            {petId = "quandale", chance = 0.35},
            {petId = "gronk", chance = 0.2},
            {petId = "rizzler", chance = 0.05}
        }
    }
}

-- Player data reference (set by RollService)
local playerData = {}
local rollService = nil

function EggShop:SetRollService(service)
    rollService = service
end

function EggShop:SetPlayerData(data)
    playerData = data
end

-- Create egg shop model in workspace
function EggShop:CreateShopModel()
    local shopModel = Instance.new("Model")
    shopModel.Name = "EggShop"
    shopModel.Parent = workspace
    
    -- Base platform
    local base = Instance.new("Part")
    base.Name = "ShopBase"
    base.Size = Vector3.new(20, 1, 20)
    base.Position = Vector3.new(50, 0.5, 0)
    base.Anchored = true
    base.Color = Color3.fromRGB(60, 60, 70)
    base.Material = Enum.Material.SmoothPlastic
    base.Parent = shopModel
    
    -- Create egg displays
    local eggPositions = {
        {type = "Basic", pos = Vector3.new(42, 3, 0), color = EGG_TYPES.Basic.color},
        {type = "Rare", pos = Vector3.new(50, 3, 0), color = EGG_TYPES.Rare.color},
        {type = "Legendary", pos = Vector3.new(58, 3, 0), color = EGG_TYPES.Legendary.color}
    }
    
    for _, eggData in ipairs(eggPositions) do
        self:CreateEggDisplay(eggData.type, eggData.pos, eggData.color, shopModel)
    end
    
    -- Sign
    local sign = Instance.new("Part")
    sign.Name = "ShopSign"
    sign.Size = Vector3.new(16, 4, 1)
    sign.Position = Vector3.new(50, 6, -8)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(40, 40, 50)
    sign.Material = Enum.Material.SmoothPlastic
    sign.Parent = shopModel
    
    -- Sign text (using surface gui would be better, but using part color for now)
    print("✅ Egg Shop Model Created")
end

function EggShop:CreateEggDisplay(eggType, position, color, parent)
    local eggConfig = EGG_TYPES[eggType]
    
    -- Egg pedestal
    local pedestal = Instance.new("Part")
    pedestal.Name = eggType .. "Pedestal"
    pedestal.Size = Vector3.new(4, 2, 4)
    pedestal.Position = position - Vector3.new(0, 2, 0)
    pedestal.Anchored = true
    pedestal.Color = Color3.fromRGB(40, 40, 50)
    pedestal.Material = Enum.Material.SmoothPlastic
    pedestal.Parent = parent
    
    -- The egg
    local egg = Instance.new("Part")
    egg.Name = eggType .. "Egg"
    egg.Size = Vector3.new(3, 4, 3)
    egg.Shape = Enum.PartType.Ball
    egg.Position = position
    egg.Anchored = true
    egg.Color = color
    egg.Material = Enum.Material.Neon
    egg.Parent = parent
    
    -- Click detector for interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = egg
    
    clickDetector.MouseClick:Connect(function(player)
        self:PromptOpenEgg(player, eggType)
    end)
    
    -- Floating animation
    task.spawn(function()
        while egg.Parent do
            local startY = position.Y
            for i = 0, 360, 5 do
                if not egg.Parent then break end
                egg.Position = Vector3.new(position.X, startY + math.sin(math.rad(i)) * 0.5, position.Z)
                egg.Rotation = Vector3.new(0, i, 0)
                task.wait(0.05)
            end
        end
    end)
    
    -- Price label part
    local labelPart = Instance.new("Part")
    labelPart.Name = eggType .. "Label"
    labelPart.Size = Vector3.new(3, 1, 0.5)
    labelPart.Position = position - Vector3.new(0, 4, 0)
    labelPart.Anchored = true
    labelPart.Color = Color3.fromRGB(30, 30, 40)
    labelPart.Material = Enum.Material.SmoothPlastic
    labelPart.Parent = parent
end

-- Prompt player to open egg
function EggShop:PromptOpenEgg(player, eggType)
    local eggConfig = EGG_TYPES[eggType]
    if not eggConfig then return end
    
    -- Check if player has enough gems
    local data = playerData[player.UserId]
    if not data then return end
    
    if data.gems < eggConfig.cost then
        EggEvent:FireClient(player, "ERROR", string.format("Need %d gems!", eggConfig.cost))
        return
    end
    
    -- Confirm opening
    EggEvent:FireClient(player, "CONFIRM_OPEN", {
        eggType = eggType,
        cost = eggConfig.cost,
        eggName = eggConfig.name
    })
end

-- Open egg and give pet
function EggShop:OpenEgg(player, eggType)
    local eggConfig = EGG_TYPES[eggType]
    if not eggConfig then return nil end
    
    -- Check gems again
    local data = playerData[player.UserId]
    if not data then return nil end
    
    if data.gems < eggConfig.cost then
        return nil
    end
    
    -- Deduct gems
    data.gems = data.gems - eggConfig.cost
    
    -- Roll for pet
    local roll = math.random()
    local cumulative = 0
    local wonPet = nil
    
    for _, drop in ipairs(eggConfig.drops) do
        cumulative = cumulative + drop.chance
        if roll <= cumulative then
            wonPet = drop.petId
            break
        end
    end
    
    -- Fallback to first drop
    if not wonPet then
        wonPet = eggConfig.drops[1].petId
    end
    
    -- Find pet config
    local petConfig = nil
    for _, pet in ipairs(Config.PETS) do
        if pet.id == wonPet then
            petConfig = pet
            break
        end
    end
    
    if petConfig then
        -- Add pet to inventory (stored in RollService)
        if not data.pets then data.pets = {} end
        table.insert(data.pets, wonPet)
        
        -- Notify client
        EggEvent:FireClient(player, "EGG_OPENED", {
            pet = petConfig,
            eggType = eggType
        })
        
        -- Sync data
        if rollService then
            rollService:SyncData(player)
        end
        
        print(string.format("🥚 %s opened %s and got %s!", player.Name, eggConfig.name, petConfig.name))
        
        return petConfig
    end
    
    return nil
end

-- Handle client events
EggEvent.OnServerEvent:Connect(function(player, action, data)
    if action == "OPEN_EGG" then
        EggShop:OpenEgg(player, data)
    elseif action == "GET_EGG_TYPES" then
        EggEvent:FireClient(player, "EGG_TYPES", EGG_TYPES)
    end
end)

-- Initialize
function EggShop:Init()
    self:CreateShopModel()
    print("✅ Egg Shop Initialized")
end

EggShop:Init()
return EggShop
