-- RollService - Server-side RNG, player data, and DataStore persistence
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- DataStore
local PlayerDataStore = DataStoreService:GetDataStore("AuraRollerV1")

-- Player data storage (in-memory)
local playerData = {}

-- Roll cooldowns (anti-exploit)
local rollCooldowns = {}
local ROLL_COOLDOWN = 0.5 -- seconds

-- Setup Remotes
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local RollEvent = Instance.new("RemoteEvent")
RollEvent.Name = "RollEvent"
RollEvent.Parent = Remotes

local EquipAuraEvent = Instance.new("RemoteEvent")
EquipAuraEvent.Name = "EquipAuraEvent"
EquipAuraEvent.Parent = Remotes

local EquipPetEvent = Instance.new("RemoteEvent")
EquipPetEvent.Name = "EquipPetEvent"
EquipPetEvent.Parent = Remotes

local DataUpdateEvent = Instance.new("RemoteEvent")
DataUpdateEvent.Name = "DataUpdateEvent"
DataUpdateEvent.Parent = Remotes

local InventoryEvent = Instance.new("RemoteEvent")
InventoryEvent.Name = "InventoryEvent"
InventoryEvent.Parent = Remotes

local AuraEquipEvent = Instance.new("RemoteEvent")
AuraEquipEvent.Name = "AuraEquipEvent"
AuraEquipEvent.Parent = Remotes

local EggEvent = Instance.new("RemoteEvent")
EggEvent.Name = "EggEvent"
EggEvent.Parent = Remotes

-- RollService
local RollService = {}
RollService.playerData = playerData -- Expose for EggShop

-- Default player data template
local function GetDefaultData()
    return {
        inventory = {},
        equippedAura = nil,
        equippedPets = {},
        pets = {},
        totalLuck = 1,
        rollCount = 0,
        gems = 100
    }
end

-- Load data from DataStore with retry
local function LoadData(userId)
    local data = nil
    local success, err

    for attempt = 1, 3 do
        success, err = pcall(function()
            data = PlayerDataStore:GetAsync(tostring(userId))
        end)
        if success then break end
        task.wait(1)
    end

    if not success then
        warn("Failed to load data for " .. tostring(userId) .. ": " .. tostring(err))
    end

    return data
end

-- Save data to DataStore with retry
local function SaveData(userId, data)
    local success, err

    -- Strip non-serializable fields before saving
    local saveData = {
        inventory = data.inventory,
        equippedAura = data.equippedAura,
        equippedPets = data.equippedPets,
        pets = data.pets,
        totalLuck = data.totalLuck,
        rollCount = data.rollCount,
        gems = data.gems
    }

    for attempt = 1, 3 do
        success, err = pcall(function()
            PlayerDataStore:SetAsync(tostring(userId), saveData)
        end)
        if success then break end
        task.wait(1)
    end

    if not success then
        warn("Failed to save data for " .. tostring(userId) .. ": " .. tostring(err))
    else
        print(string.format("💾 Saved data for %s", tostring(userId)))
    end
end

-- Initialize player data
function RollService:InitPlayer(player)
    -- Try to load saved data
    local saved = LoadData(player.UserId)

    if saved then
        playerData[player.UserId] = saved
        -- Ensure all fields exist (for old saves missing new fields)
        local data = playerData[player.UserId]
        if not data.gems then data.gems = 100 end
        if not data.pets then data.pets = {} end
        if not data.equippedPets then data.equippedPets = {} end
        if not data.inventory then data.inventory = {} end
        if not data.rollCount then data.rollCount = 0 end
        if not data.totalLuck then data.totalLuck = 1 end
        print(string.format("📂 Loaded saved data for %s (%d auras, %d rolls)", 
            player.Name, #data.inventory, data.rollCount))
    else
        -- Fresh player
        playerData[player.UserId] = GetDefaultData()
        -- Give starter common aura
        self:GiveAura(player, "glowing")
        self:EquipAuraInternal(player, "glowing")
        -- Give starter pet
        self:GivePet(player, "skibidi")
        self:EquipPetInternal(player, "skibidi")
        print(string.format("🆕 New player initialized: %s", player.Name))
    end

    print(string.format("🎲 Initialized player %s", player.Name))
    self:CalculateLuck(player)
    self:SyncData(player)

    -- Re-equip their aura visually
    local data = playerData[player.UserId]
    if data.equippedAura then
        AuraEquipEvent:FireAllClients(player.UserId, data.equippedAura)
    end
end

-- Give pet to player
function RollService:GivePet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end
    if not data.pets then data.pets = {} end
    table.insert(data.pets, petId)
    return true
end

-- Get inventory data for client
function RollService:GetInventory(player)
    local data = playerData[player.UserId]
    if not data then return {} end
    return data.inventory or {}
end

-- Get pets data for client
function RollService:GetPets(player)
    local data = playerData[player.UserId]
    if not data then return {} end
    return data.pets or {}
end

-- Calculate total luck from equipped pets
function RollService:CalculateLuck(player)
    local data = playerData[player.UserId]
    if not data then return 1 end

    local totalLuck = 1

    for _, petId in ipairs(data.equippedPets) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then
                totalLuck = totalLuck + (pet.luckBoost - 1)
                break
            end
        end
    end

    data.totalLuck = totalLuck
    return totalLuck
end

-- Roll for an aura
function RollService:Roll(player)
    local data = playerData[player.UserId]
    if not data then
        warn("Roll failed: No player data for " .. player.Name)
        return nil
    end

    -- Server-side rate limit
    local now = tick()
    local lastRoll = rollCooldowns[player.UserId] or 0
    if now - lastRoll < ROLL_COOLDOWN then
        warn("Roll rate limited for " .. player.Name)
        return nil
    end
    rollCooldowns[player.UserId] = now

    -- Calculate luck
    local luck = self:CalculateLuck(player)

    -- Build weighted table from auras with rarity chances
    local weightedAuras = {}
    for _, aura in ipairs(Config.AURAS) do
        local rarityConfig = Config.RARITIES[aura.rarity]
        if rarityConfig then
            table.insert(weightedAuras, {
                aura = aura,
                chance = rarityConfig.chance
            })
        end
    end

    -- Roll using weighted random
    local success, result = pcall(function()
        return Utils.WeightedRandom(weightedAuras, luck)
    end)

    if not success or not result then
        warn("Roll error: " .. tostring(result))
        -- Fallback: give first common aura
        result = {aura = Config.AURAS[1]}
    end

    local rolledAura = result.aura or Config.AURAS[1]

    -- Give the aura
    self:GiveAura(player, rolledAura.id)

    -- Update stats
    data.rollCount = data.rollCount + 1
    data.gems = data.gems + 1 -- 1 gem per roll

    -- Broadcast if extremely rare
    if rolledAura.rarity == "Secret" or rolledAura.rarity == "Godlike" then
        self:BroadcastRoll(player, rolledAura)
    end

    self:SyncData(player)

    print(string.format("🎲 %s rolled %s (%s) with %.1fx luck!",
        player.Name, rolledAura.name, rolledAura.rarity, luck))

    return rolledAura
end

-- Give aura to player inventory
function RollService:GiveAura(player, auraId)
    local data = playerData[player.UserId]
    if not data then return false end

    table.insert(data.inventory, {
        auraId = auraId,
        rollDate = os.time()
    })

    return true
end

-- Equip aura (internal, no sync)
function RollService:EquipAuraInternal(player, auraId)
    local data = playerData[player.UserId]
    if not data then return false end

    local hasAura = false
    for _, item in ipairs(data.inventory) do
        if item.auraId == auraId then
            hasAura = true
            break
        end
    end

    if not hasAura then return false end

    data.equippedAura = auraId
    return true
end

-- Equip aura (public, with sync and client notify)
function RollService:EquipAura(player, auraId)
    local success = self:EquipAuraInternal(player, auraId)
    if success then
        self:SyncData(player)
        -- Tell all clients to show aura on this player
        AuraEquipEvent:FireAllClients(player.UserId, auraId)
    end
    return success
end

-- Equip pet (internal)
function RollService:EquipPetInternal(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end

    if #data.equippedPets >= 3 then return false end

    for _, eId in ipairs(data.equippedPets) do
        if eId == petId then return false end
    end

    table.insert(data.equippedPets, petId)
    self:CalculateLuck(player)
    return true
end

-- Equip pet (public)
function RollService:EquipPet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false, "No data" end

    -- Verify they own the pet
    local hasPet = false
    for _, ownedId in ipairs(data.pets) do
        if ownedId == petId then hasPet = true break end
    end
    if not hasPet then return false, "Don't own this pet" end

    if #data.equippedPets >= 3 then
        return false, "Max 3 pets equipped"
    end

    for _, equippedId in ipairs(data.equippedPets) do
        if equippedId == petId then
            return false, "Already equipped"
        end
    end

    table.insert(data.equippedPets, petId)
    self:CalculateLuck(player)
    self:SyncData(player)
    return true
end

-- Unequip pet
function RollService:UnequipPet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end

    for i, equippedId in ipairs(data.equippedPets) do
        if equippedId == petId then
            table.remove(data.equippedPets, i)
            self:CalculateLuck(player)
            self:SyncData(player)
            return true
        end
    end

    return false
end

-- Broadcast rare roll to all players
function RollService:BroadcastRoll(player, aura)
    local rarityConfig = Config.RARITIES[aura.rarity]

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        DataUpdateEvent:FireClient(otherPlayer, "RARE_ROLL", {
            playerName = player.Name,
            auraName = aura.name,
            rarity = aura.rarity,
            color = rarityConfig.color
        })
    end
end

-- Sync player data to client
function RollService:SyncData(player)
    local data = playerData[player.UserId]
    if not data then return end

    -- Get equipped aura info
    local equippedAuraInfo = nil
    if data.equippedAura then
        for _, aura in ipairs(Config.AURAS) do
            if aura.id == data.equippedAura then
                equippedAuraInfo = aura
                break
            end
        end
    end

    -- Get equipped pets info
    local equippedPetsInfo = {}
    for _, petId in ipairs(data.equippedPets) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then
                table.insert(equippedPetsInfo, pet)
                break
            end
        end
    end

    -- Get all pets info
    local allPetsInfo = {}
    for _, petId in ipairs(data.pets or {}) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then
                table.insert(allPetsInfo, pet)
                break
            end
        end
    end

    DataUpdateEvent:FireClient(player, "SYNC", {
        equippedAura = equippedAuraInfo,
        equippedPets = equippedPetsInfo,
        allPets = allPetsInfo,
        totalLuck = data.totalLuck,
        rollCount = data.rollCount,
        gems = data.gems,
        inventoryCount = #data.inventory
    })
end

-- Get player data (for other services)
function RollService:GetPlayerData(player)
    return playerData[player.UserId]
end

-- Remote Handlers --

RollEvent.OnServerEvent:Connect(function(player)
    local aura = RollService:Roll(player)
    if aura then
        RollEvent:FireClient(player, "SUCCESS", aura)
    else
        RollEvent:FireClient(player, "FAILED", "Roll failed")
    end
end)

EquipAuraEvent.OnServerEvent:Connect(function(player, auraId)
    if type(auraId) ~= "string" then return end
    local success = RollService:EquipAura(player, auraId)
    EquipAuraEvent:FireClient(player, success and "SUCCESS" or "FAILED")
end)

EquipPetEvent.OnServerEvent:Connect(function(player, petId, action)
    if type(petId) ~= "string" then return end
    if action == "EQUIP" then
        local success, msg = RollService:EquipPet(player, petId)
        EquipPetEvent:FireClient(player, success and "SUCCESS" or "FAILED", msg)
    elseif action == "UNEQUIP" then
        local success = RollService:UnequipPet(player, petId)
        EquipPetEvent:FireClient(player, success and "SUCCESS" or "FAILED")
    end
end)

InventoryEvent.OnServerEvent:Connect(function(player, action, data)
    if action == "GET_INVENTORY" then
        local inventory = RollService:GetInventory(player)
        InventoryEvent:FireClient(player, "INVENTORY_DATA", inventory)
    elseif action == "EQUIP_AURA" then
        if type(data) ~= "string" then return end
        local success = RollService:EquipAura(player, data)
        InventoryEvent:FireClient(player, success and "EQUIP_SUCCESS" or "EQUIP_FAILED")
    elseif action == "GET_PETS" then
        local pets = RollService:GetPets(player)
        InventoryEvent:FireClient(player, "PETS_DATA", pets)
    end
end)

-- Player lifecycle --

Players.PlayerAdded:Connect(function(player)
    task.wait(1) -- Wait for character/scripts to load
    RollService:InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    local data = playerData[player.UserId]
    if data then
        SaveData(player.UserId, data)
    end
    playerData[player.UserId] = nil
    rollCooldowns[player.UserId] = nil
    luckBoosts[player.UserId]   = nil
    gemBoosts[player.UserId]    = nil
end)

-- Save all on server shutdown
game:BindToClose(function()
    for userId, data in pairs(playerData) do
        SaveData(userId, data)
    end
end)

-- ── Shop System ──────────────────────────────────────────────────────────

-- Active boosts (userId -> expiry tick())
local luckBoosts = {}  -- 3x luck boost
local gemBoosts  = {}  -- 2x gem boost

-- Patch CalculateLuck to include active boosts
local _origCalcLuck = RollService.CalculateLuck
function RollService:CalculateLuck(player)
    local luck = _origCalcLuck(self, player)
    if luckBoosts[player.UserId] and tick() < luckBoosts[player.UserId] then
        luck = luck * 3
    end
    local data = playerData[player.UserId]
    if data then data.totalLuck = luck end
    return luck
end

-- Patch gem earn in Roll to respect gem boost
local _origRoll = RollService.Roll
function RollService:Roll(player)
    local result = _origRoll(self, player)
    if result then
        local data = playerData[player.UserId]
        if data and gemBoosts[player.UserId] and tick() < gemBoosts[player.UserId] then
            data.gems = data.gems + 1  -- adds 1 more (total 2 per roll)
        end
    end
    return result
end

local ShopEvent = Instance.new("RemoteEvent")
ShopEvent.Name = "ShopEvent"
ShopEvent.Parent = Remotes

local SHOP_ITEMS = {
    lucky_boost = { cost = 50,  desc = "3x Luck for 60s",       duration = 60  },
    gem_doubler = { cost = 75,  desc = "2x Gems for 5min",      duration = 300 },
}

ShopEvent.OnServerEvent:Connect(function(player, itemId)
    local data = playerData[player.UserId]
    if not data then return end

    local item = SHOP_ITEMS[itemId]
    if not item then
        ShopEvent:FireClient(player, "FAILED", "Unknown item")
        return
    end

    if data.gems < item.cost then
        ShopEvent:FireClient(player, "FAILED", "Not enough gems")
        return
    end

    data.gems = data.gems - item.cost

    if itemId == "lucky_boost" then
        luckBoosts[player.UserId] = tick() + item.duration
    elseif itemId == "gem_doubler" then
        gemBoosts[player.UserId] = tick() + item.duration
    end

    RollService:SyncData(player)
    ShopEvent:FireClient(player, "SUCCESS", itemId, item.duration)
    print(string.format("🛒 %s purchased %s", player.Name, itemId))
end)

print("✅ Roll Service Initialized")
return RollService

