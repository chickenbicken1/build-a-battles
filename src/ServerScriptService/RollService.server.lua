-- RollService - Server-side RNG and player data
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

-- Player data storage
local playerData = {}

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
EquipAuraEvent.Parent = Remotes

local DataUpdateEvent = Instance.new("RemoteEvent")
DataUpdateEvent.Name = "DataUpdateEvent"
DataUpdateEvent.Parent = Remotes

-- RollService
local RollService = {}

-- Initialize player data
function RollService:InitPlayer(player)
    playerData[player.UserId] = {
        inventory = {}, -- {auraId, rollDate}
        equippedAura = nil,
        equippedPets = {}, -- Max 3 pets
        totalLuck = 1,
        rollCount = 0,
        gems = 0
    }
    
    -- Give starter common aura
    self:GiveAura(player, "glowing")
    self:EquipAura(player, "glowing")
    
    print(string.format("🎲 Initialized player %s", player.Name))
    self:SyncData(player)
end

-- Calculate total luck from equipped pets
function RollService:CalculateLuck(player)
    local data = playerData[player.UserId]
    if not data then return 1 end
    
    local totalLuck = 1 -- Base luck
    
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
    if not data then return nil end
    
    -- Calculate luck
    local luck = self:CalculateLuck(player)
    
    -- Roll using weighted random
    local rolledAura = Utils.WeightedRandom(Config.AURAS, luck)
    
    -- Give the aura
    self:GiveAura(player, rolledAura.id)
    
    -- Update stats
    data.rollCount = data.rollCount + 1
    data.gems = data.gems + 1 -- 1 gem per roll
    
    -- Auto-equip if better rarity (optional)
    -- self:AutoEquipIfBetter(player, rolledAura)
    
    -- Notify other players if rare
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

-- Equip aura
function RollService:EquipAura(player, auraId)
    local data = playerData[player.UserId]
    if not data then return false end
    
    -- Verify player has this aura
    local hasAura = false
    for _, item in ipairs(data.inventory) do
        if item.auraId == auraId then
            hasAura = true
            break
        end
    end
    
    if not hasAura then
        return false
    end
    
    data.equippedAura = auraId
    self:SyncData(player)
    
    -- Tell client to show aura
    EquipAuraEvent:FireClient(player, auraId)
    
    return true
end

-- Equip pet
function RollService:EquipPet(player, petId)
    local data = playerData[player.UserId]
    if not data then return false end
    
    -- Max 3 pets
    if #data.equippedPets >= 3 then
        return false, "Max 3 pets equipped"
    end
    
    -- Check if already equipped
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
    
    DataUpdateEvent:FireClient(player, "SYNC", {
        equippedAura = equippedAuraInfo,
        equippedPets = equippedPetsInfo,
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

-- Handle roll request
RollEvent.OnServerEvent:Connect(function(player)
    local aura = RollService:Roll(player)
    if aura then
        RollEvent:FireClient(player, "SUCCESS", aura)
    else
        RollEvent:FireClient(player, "FAILED", "Roll failed")
    end
end)

-- Handle equip aura
EquipAuraEvent.OnServerEvent:Connect(function(player, auraId)
    local success = RollService:EquipAura(player, auraId)
    EquipAuraEvent:FireClient(player, success and "SUCCESS" or "FAILED")
end)

-- Handle equip pet
EquipPetEvent.OnServerEvent:Connect(function(player, petId, action)
    if action == "EQUIP" then
        local success, msg = RollService:EquipPet(player, petId)
        EquipPetEvent:FireClient(player, success and "SUCCESS" or "FAILED", msg)
    elseif action == "UNEQUIP" then
        local success = RollService:UnequipPet(player, petId)
        EquipPetEvent:FireClient(player, success and "SUCCESS" or "FAILED")
    end
end)

-- Player joined
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for client to load
    RollService:InitPlayer(player)
end)

-- Player left
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
end)

print("✅ Roll Service Initialized")
return RollService
