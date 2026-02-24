-- EggShop - Server-side egg opening system
-- [PURE MODULE VERSION]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Utils = require(Shared:WaitForChild("Utils"))

local EggShop = {}
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

local rollService = nil
local EggEvent = nil

function EggShop:SetRollService(service)
    rollService = service
end

function EggShop:CreateShopModel()
    local shopModel = workspace:FindFirstChild("EggShop") or Instance.new("Model")
    shopModel.Name = "EggShop"
    shopModel.Parent = workspace
    
    local base = shopModel:FindFirstChild("ShopBase") or Instance.new("Part")
    base.Name = "ShopBase"
    base.Size = Vector3.new(24, 1, 10)
    base.Position = Vector3.new(30, 0.5, 30)
    base.Anchored = true
    base.Color = Color3.fromRGB(45, 45, 55)
    base.Parent = shopModel
    
    local eggPositions = {
        {type = "Basic", pos = Vector3.new(22, 3, 30)},
        {type = "Rare", pos = Vector3.new(30, 3, 30)},
        {type = "Legendary", pos = Vector3.new(38, 3, 30)}
    }
    
    for _, eData in ipairs(eggPositions) do
        local config = EGG_TYPES[eData.type]
        local pedestal = shopModel:FindFirstChild(eData.type.."Ped") or Instance.new("Part")
        pedestal.Name = eData.type.."Ped"
        pedestal.Size = Vector3.new(4, 2, 4)
        pedestal.Position = eData.pos - Vector3.new(0, 2, 0)
        pedestal.Anchored = true ; pedestal.Parent = shopModel
        
        local egg = shopModel:FindFirstChild(eData.type.."Egg") or Instance.new("Part")
        egg.Name = eData.type.."Egg"
        egg.Size = Vector3.new(3.5, 4.5, 3.5)
        egg.Shape = Enum.PartType.Ball
        egg.Position = eData.pos
        egg.Anchored = true
        egg.Color = config.color
        egg.Material = Enum.Material.Neon
        egg.Parent = shopModel
        
        local prompt = egg:FindFirstChild("Prompt") or Instance.new("ProximityPrompt")
        prompt.Name = "Prompt"
        prompt.ObjectText = config.name
        prompt.ActionText = "Open ("..config.cost.." 💎)"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.HoldDuration = 0.5
        prompt.Parent = egg
        
        prompt.Triggered:Connect(function(player) self:OpenEgg(player, eData.type) end)
    end
end

function EggShop:OpenEgg(player, eggType)
    local config = EGG_TYPES[eggType]
    if not config or not rollService then return end
    
    local pd = rollService.playerData[player.UserId]
    if not pd or pd.gems < config.cost then
        EggEvent:FireClient(player, "ERROR", "Not enough gems!")
        return
    end
    
    pd.gems = pd.gems - config.cost
    
    local roll = math.random()
    local cumulative = 0
    local wonPetId = config.drops[1].petId
    for _, drop in ipairs(config.drops) do
        cumulative = cumulative + drop.chance
        if roll <= cumulative then
            wonPetId = drop.petId
            break
        end
    end
    
    local petConfig = nil
    for _, p in ipairs(Config.PETS) do
        if p.id == wonPetId then petConfig = p ; break end
    end
    
    table.insert(pd.pets, wonPetId)
    rollService:SyncData(player)
    EggEvent:FireClient(player, "EGG_OPENED", { pet = petConfig, eggType = eggType })
end

function EggShop:Init()
    print("🚀 [EggShop] Pure Module Initialization")
    
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    EggEvent = Remotes:WaitForChild("EggEvent")
    
    self:CreateShopModel()
    
    EggEvent.OnServerEvent:Connect(function(p, action, data)
        if action == "OPEN_EGG" then self:OpenEgg(p, data)
        elseif action == "GET_EGG_TYPES" then EggEvent:FireClient(p, "EGG_TYPES", EGG_TYPES) end
    end)
    print("✅ EggShop Ready")
end

return EggShop
