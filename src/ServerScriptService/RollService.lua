-- RollService - Server-side RNG, player data, and DataStore persistence
-- This is a ModuleScript (mapped via Rojo from .lua extension)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- DataStore
local PlayerDataStore = DataStoreService:GetDataStore("AuraRollerV1")

-- Player data storage (in-memory)
local playerData = {}

-- Active boosts (userId -> expiry tick())
local luckBoosts = {}  -- 3x luck boost
local gemBoosts  = {}  -- 2x gem boost

-- Roll cooldowns (anti-exploit)
local rollCooldowns = {}
local ROLL_COOLDOWN = 1.0 -- Increased for animation anticipation

-- Setup Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local function GetRemote(name, class)
    local r = Remotes:FindFirstChild(name)
    if not r then
        r = Instance.new(class or "RemoteEvent")
        r.Name = name
        r.Parent = Remotes
    end
    return r
end

local RollEvent       = GetRemote("RollEvent")
local EquipAuraEvent  = GetRemote("EquipAuraEvent")
local EquipPetEvent   = GetRemote("EquipPetEvent")
local DataUpdateEvent = GetRemote("DataUpdateEvent")
local InventoryEvent  = GetRemote("InventoryEvent")
local AuraEquipEvent  = GetRemote("AuraEquipEvent")
local EggEvent        = GetRemote("EggEvent")
local ShopEvent       = GetRemote("ShopEvent")

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
        gems = 100,
        power = 0
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
    end
end

-- Initialize player data
function RollService:InitPlayer(player)
    local saved = LoadData(player.UserId)

    if saved then
        playerData[player.UserId] = saved
        local data = playerData[player.UserId]
        -- Backwards compatibility migrations
        if not data.gems then data.gems = 100 end
        if not data.pets then data.pets = {} end
        if not data.equippedPets then data.equippedPets = {} end
        if not data.inventory then data.inventory = {} end
        if not data.rollCount then data.rollCount = 0 end
        if not data.totalLuck then data.totalLuck = 1 end
    else
        playerData[player.UserId] = GetDefaultData()
        self:GiveAura(player, "glowing")
        self:EquipAuraInternal(player, "glowing")
        self:GivePet(player, "skibidi")
        self:EquipPetInternal(player, "skibidi")
    end

    self:CalculateLuck(player)
    self:CalculatePower(player)
    self:SyncData(player)

    -- Re-equip visually
    local data = playerData[player.UserId]
    if data.equippedAura then
        AuraEquipEvent:FireAllClients(player.UserId, data.equippedAura)
    end
    print(string.format("🎲 Initialized %s (Luck: %.2fx, Power: %d)", player.Name, data.totalLuck, data.power or 0))
end

-- Luck calculation (Equipped Pets + Active Shop Boosts)
function RollService:CalculateLuck(player)
    local data = playerData[player.UserId]
    if not data then return 1 end

    local petLuck = 1
    for _, petId in ipairs(data.equippedPets) do
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

-- Power calculation (Aura Power * Pet Luck Multiplier)
function RollService:CalculatePower(player)
    local data = playerData[player.UserId]
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

    local petLuck = 1
    for _, petId in ipairs(data.equippedPets) do
        for _, pet in ipairs(Config.PETS) do
            if pet.id == petId then
                petLuck = petLuck + (pet.luckBoost - 1)
                break
            end
        end
    end

    local power = math.floor(auraPower * petLuck)
    data.power = power
    return power
end

-- Sync data to client
function RollService:SyncData(player)
    local data = playerData[player.UserId]
    if not data then return end

    self:CalculateLuck(player)
    self:CalculatePower(player)

    local equippedPetsInfo = {}
    for _, petId in ipairs(data.equippedPets) do
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

-- Roll logic (Delayed result giving)
function RollService:Roll(player)
    local data = playerData[player.UserId]
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

    -- ANTICIPATION: Wait before giving the actual reward to match client roulette
    task.spawn(function()
        task.wait(1.8) -- Match HUD anim
        if not player or not player.Parent then return end
        
        -- Apply the roll result
        self:GiveAura(player, rolledAura.id)
        data.rollCount = data.rollCount + 1
        
        -- Gem gain
        local gain = 1
        if gemBoosts[player.UserId] and tick() < gemBoosts[player.UserId] then gain = 2 end
        data.gems = data.gems + gain

        if rolledAura.rarity == "Secret" or rolledAura.rarity == "Godlike" then
            self:BroadcastRoll(player, rolledAura)
        end

        self:SyncData(player)
        print(string.format("✨ Reward given to %s: %s", player.Name, rolledAura.name))
    end)

    return rolledAura
end

function RollService:GiveAura(player, auraId)
    local data = playerData[player.UserId]
    if not data then return false end
    table.insert(data.inventory, { auraId = auraId, rollDate = os.time() })
    return true
end

function RollService:EquipAuraInternal(player, auraId)
    local data = playerData[player.UserId]
    if not data then return false end
    data.equippedAura = auraId
    return true
end

function RollService:EquipAura(player, auraId)
    local data = playerData[player.UserId]
    if not data then return end
    
    local hasAura = false
    for _, item in ipairs(data.inventory) do
        if item.auraId == auraId then hasAura = true break end
    end
    if not hasAura then return false end

    data.equippedAura = auraId
    self:SyncData(player)
    AuraEquipEvent:FireAllClients(player.UserId, auraId)
    return true
end

function RollService:GivePet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end
    table.insert(data.pets, petId)
    return true
end

function RollService:EquipPet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end

    local hasPet = false
    for _, id in ipairs(data.pets) do if id == petId then hasPet = true break end end
    if not hasPet then return false end
    if #data.equippedPets >= 3 then return false end

    for _, id in ipairs(data.equippedPets) do if id == petId then return false end end

    table.insert(data.equippedPets, petId)
    self:SyncData(player)
    return true
end

function RollService:UnequipPet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end
    for i, id in ipairs(data.equippedPets) do
        if id == petId then
            table.remove(data.equippedPets, i)
            self:SyncData(player)
            return true
        end
    end
    return false
end

function RollService:BroadcastRoll(player, aura)
    local rc = Config.RARITIES[aura.rarity]
    for _, p in ipairs(Players:GetPlayers()) do
        DataUpdateEvent:FireClient(p, "RARE_ROLL", {
            playerName = player.Name,
            auraName = aura.name,
            rarity = aura.rarity,
            color = rc and rc.color or Color3.new(1,1,1)
        })
    end
end

-- Connections
RollEvent.OnServerEvent:Connect(function(player)
    local aura = RollService:Roll(player)
    if aura then RollEvent:FireClient(player, "SUCCESS", aura) end
end)

InventoryEvent.OnServerEvent:Connect(function(player, action, data)
    if action == "GET_INVENTORY" then
        InventoryEvent:FireClient(player, "INVENTORY_DATA", playerData[player.UserId] and playerData[player.UserId].inventory or {})
    elseif action == "EQUIP_AURA" then
        RollService:EquipAura(player, data)
    end
end)

EquipPetEvent.OnServerEvent:Connect(function(player, petId, action)
    if action == "EQUIP" then RollService:EquipPet(player, petId)
    elseif action == "UNEQUIP" then RollService:UnequipPet(player, petId) end
end)

local SHOP_ITEMS = {
    lucky_boost = { cost = 50, duration = 60 },
    gem_doubler = { cost = 75, duration = 300 },
}

ShopEvent.OnServerEvent:Connect(function(player, itemId)
    local data = playerData[player.UserId]
    local item = SHOP_ITEMS[itemId]
    if not data or not item or data.gems < item.cost then 
        ShopEvent:FireClient(player, "FAILED")
        return 
    end

    data.gems = data.gems - item.cost
    if itemId == "lucky_boost" then luckBoosts[player.UserId] = tick() + item.duration
    elseif itemId == "gem_doubler" then gemBoosts[player.UserId] = tick() + item.duration end

    RollService:SyncData(player)
    ShopEvent:FireClient(player, "SUCCESS", itemId, item.duration)
end)

Players.PlayerAdded:Connect(function(player)
    RollService:InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if playerData[player.UserId] then SaveData(player.UserId, playerData[player.UserId]) end
    playerData[player.UserId] = nil
    luckBoosts[player.UserId] = nil
    gemBoosts[player.UserId] = nil
end)

game:BindToClose(function()
    for id, data in pairs(playerData) do SaveData(id, data) end
end)

print("✅ RollService Module Initialized")
return RollService
