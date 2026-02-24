-- RollService - Server-side RNG, player data, and DataStore persistence
-- [PURE MODULE VERSION - SeenKid Inspired]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

-- DataStore
local PlayerDataStore = DataStoreService:GetDataStore("AuraRollerV1")

local RollService = {}
RollService.playerData = {}
local luckBoosts = {}
local gemBoosts  = {}
local rollCooldowns = {}
local ROLL_COOLDOWN = 1.0

-- Remotes Cache
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollEvent       = Remotes:WaitForChild("RollEvent")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")
local InventoryEvent  = Remotes:WaitForChild("InventoryEvent")
local AuraEquipEvent  = Remotes:WaitForChild("AuraEquipEvent")
local EggEvent        = Remotes:WaitForChild("EggEvent")
local ShopEvent       = Remotes:WaitForChild("ShopEvent")

-- SeenKid Pattern: Action Request
local PetActionRequest = Remotes:FindFirstChild("PetActionRequest")
if not PetActionRequest then
    PetActionRequest = Instance.new("RemoteFunction")
    PetActionRequest.Name = "PetActionRequest"
    PetActionRequest.Parent = Remotes
end

local function GetDefaultData()
    return {
        inventory = {},
        equippedAura = nil,
        equippedPets = {},
        pets = {},
        totalLuck = 1,
        rollCount = 0,
        gems = 9999,
        power = 0
    }
end

local function LoadData(userId)
    local data = nil
    pcall(function() data = PlayerDataStore:GetAsync(tostring(userId)) end)
    return data
end

local function SaveData(userId, data)
    local saveData = {
        inventory = data.inventory,
        equippedAura = data.equippedAura,
        equippedPets = data.equippedPets,
        pets = data.pets,
        totalLuck = data.totalLuck,
        rollCount = data.rollCount,
        gems = data.gems
    }
    pcall(function() PlayerDataStore:SetAsync(tostring(userId), saveData) end)
end

function RollService:CalculateLuck(player)
    local data = self.playerData[player.UserId]
    if not data then return 1 end

    local petLuck = 1
    for _, petId in ipairs(data.equippedPets or {}) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then
                petLuck = petLuck + (pet.luckBoost - 1)
                break
            end
        end
    end

    local finalLuck = petLuck
    if luckBoosts[player.UserId] and tick() < luckBoosts[player.UserId] then
        finalLuck = finalLuck * 3
    end

    data.totalLuck = finalLuck
    return finalLuck
end

function RollService:CalculatePower(player)
    local data = self.playerData[player.UserId]
    if not data then return 0 end

    local auraPower = 0
    if data.equippedAura then
        for _, aura in ipairs(Config.AURAS) do
            if aura.id == data.equippedAura then
                auraPower = aura.power or 10
                break
            end
        end
    end

    local luck = self:CalculateLuck(player)
    local power = math.floor(auraPower * luck)
    data.power = power
    return power
end

function RollService:SyncData(player)
    local data = self.playerData[player.UserId]
    if not data then return end

    self:CalculateLuck(player)
    self:CalculatePower(player)

    local equippedPetsInfo = {}
    for _, petId in ipairs(data.equippedPets or {}) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then table.insert(equippedPetsInfo, pet) break end
        end
    end

    local allPetsInfo = {}
    for _, petId in ipairs(data.pets or {}) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then table.insert(allPetsInfo, pet) break end
        end
    end

    DataUpdateEvent:FireClient(player, "SYNC", {
        equippedAura = data.equippedAura,
        equippedPets = equippedPetsInfo,
        allPets = allPetsInfo,
        totalLuck = data.totalLuck,
        rollCount = data.rollCount,
        gems = data.gems,
        power = data.power or 0,
        inventoryCount = #data.inventory
    })
end

function RollService:Roll(player)
    local data = self.playerData[player.UserId]
    if not data then return nil end

    local now = tick()
    local lastRoll = rollCooldowns[player.UserId] or 0
    if now - lastRoll < ROLL_COOLDOWN then return nil end
    rollCooldowns[player.UserId] = now

    local luck = self:CalculateLuck(player)
    local weightedAuras = {}
    for _, aura in ipairs(Config.AURAS) do
        local rc = Config.RARITIES[aura.rarity]
        if rc then table.insert(weightedAuras, {aura = aura, chance = rc.chance}) end
    end

    local result = Utils.WeightedRandom(weightedAuras, luck)
    local rolledAura = result.aura or Config.AURAS[1]

    task.spawn(function()
        task.wait(1.8)
        if not player or not player.Parent then return end
        
        table.insert(data.inventory, { auraId = rolledAura.id, rollDate = os.time() })
        data.rollCount = data.rollCount + 1
        data.gems = data.gems + (gemBoosts[player.UserId] and tick() < gemBoosts[player.UserId] and 2 or 1)

        if rolledAura.rarity == "Secret" or rolledAura.rarity == "Godlike" then
            for _, p in ipairs(Players:GetPlayers()) do
                DataUpdateEvent:FireClient(p, "RARE_ROLL", {
                    playerName = player.Name,
                    auraName = rolledAura.name,
                    rarity = rolledAura.rarity,
                    color = Config.RARITIES[rolledAura.rarity].color or Color3.new(1,1,1)
                })
            end
        end
        self:SyncData(player)
    end)

    return rolledAura
end

function RollService:InitPlayer(player)
    local saved = LoadData(player.UserId)
    self.playerData[player.UserId] = saved or GetDefaultData()
    self.playerData[player.UserId].gems = 9999 -- TEST FORCE
    self:SyncData(player)
end

function RollService:Init()
    print("🚀 [RollService] Pure Module Initialization")
    
    Players.PlayerAdded:Connect(function(p) self:InitPlayer(p) end)
    Players.PlayerRemoving:Connect(function(p)
        if self.playerData[p.UserId] then SaveData(p.UserId, self.playerData[p.UserId]) end
        self.playerData[p.UserId] = nil
    end)
    
    for _, p in ipairs(Players:GetPlayers()) do self:InitPlayer(p) end
    
    RollEvent.OnServerEvent:Connect(function(p)
        local aura = self:Roll(p)
        if aura then RollEvent:FireClient(p, "SUCCESS", aura) end
    end)
    
    InventoryEvent.OnServerEvent:Connect(function(p, action, data)
        local pd = self.playerData[p.UserId]
        if not pd then return end
        if action == "GET_INVENTORY" then
            InventoryEvent:FireClient(p, "INVENTORY_DATA", pd.inventory)
        elseif action == "EQUIP_AURA" then
            pd.equippedAura = data
            self:SyncData(p)
            AuraEquipEvent:FireAllClients(p.UserId, data)
        end
    end)
    
    local SHOP_ITEMS = { lucky_boost = { cost = 50, duration = 60 }, gem_doubler = { cost = 75, duration = 300 } }
    ShopEvent.OnServerEvent:Connect(function(p, itemId)
        local data = self.playerData[p.UserId]
        local item = SHOP_ITEMS[itemId]
        if not data or not item or data.gems < item.cost then return end
        data.gems = data.gems - item.cost
        if itemId == "lucky_boost" then luckBoosts[p.UserId] = tick() + item.duration
        elseif itemId == "gem_doubler" then gemBoosts[p.UserId] = tick() + item.duration end
        self:SyncData(p)
        ShopEvent:FireClient(p, "SUCCESS", itemId, item.duration)
    end)
    
    PetActionRequest.OnServerInvoke = function(p, action, data)
        local pd = self.playerData[p.UserId]
        if not pd then return "Error", "No Data" end
        
        if action == "Equip" then
            local petId = data
            if not pd.equippedPets then pd.equippedPets = {} end
            
            local found = table.find(pd.equippedPets, petId)
            if found then
                table.remove(pd.equippedPets, found)
            else
                if #pd.equippedPets < 3 then
                    table.insert(pd.equippedPets, petId)
                else
                    return "Error", "Too many pets equipped"
                end
            end
            self:SyncData(p)
            return "Success"
        end
        return "Error", "Unknown Action"
    end

    game:BindToClose(function() for id, data in pairs(self.playerData) do SaveData(id, data) end end)
    print("✅ RollService Ready")
end

return RollService
