-- DataService - Manages player data (materials, stats)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local playerData = {} -- In-memory storage (use DataStore for production)

-- Initialize player data
function DataService:InitPlayer(player)
    playerData[player.UserId] = {
        materials = {
            WOOD = Config.BUILD.STARTING_MATERIALS.WOOD,
            BRICK = Config.BUILD.STARTING_MATERIALS.BRICK,
            METAL = Config.BUILD.STARTING_MATERIALS.METAL
        },
        builds = {}, -- Track player's builds
        stats = {
            wins = 0,
            kills = 0,
            buildsPlaced = 0,
            damageDealt = 0
        }
    }
    
    print(string.format("📊 Initialized data for %s", player.Name))
    self:SyncMaterials(player)
end

-- Get player data
function DataService:GetPlayerData(player)
    return playerData[player.UserId]
end

-- Get materials
function DataService:GetMaterials(player)
    local data = playerData[player.UserId]
    if data then
        return Utils.DeepCopy(data.materials)
    end
    return nil
end

-- Add materials
function DataService:AddMaterial(player, materialType, amount)
    local data = playerData[player.UserId]
    if not data then return false end
    
    local current = data.materials[materialType] or 0
    local newAmount = math.min(current + amount, Config.BUILD.MAX_MATERIALS)
    data.materials[materialType] = newAmount
    
    self:SyncMaterials(player)
    return true
end

-- Remove materials (for building)
function DataService:RemoveMaterial(player, materialType, amount)
    local data = playerData[player.UserId]
    if not data then return false end
    
    local current = data.materials[materialType] or 0
    if current < amount then return false end
    
    data.materials[materialType] = current - amount
    self:SyncMaterials(player)
    return true
end

-- Check if player has enough materials
function DataService:HasMaterial(player, materialType, amount)
    local data = playerData[player.UserId]
    if not data then return false end
    return (data.materials[materialType] or 0) >= amount
end

-- Get total materials
function DataService:GetTotalMaterials(player)
    local data = playerData[player.UserId]
    if not data then return 0 end
    
    local total = 0
    for _, amount in pairs(data.materials) do
        total = total + amount
    end
    return total
end

-- Sync materials to client
function DataService:SyncMaterials(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local event = remotes:FindFirstChild("MaterialUpdate")
    if event then
        event:FireClient(player, data.materials)
    end
end

-- Track build placement
function DataService:TrackBuild(player, buildInstance)
    local data = playerData[player.UserId]
    if not data then return end
    
    table.insert(data.builds, buildInstance)
    data.stats.buildsPlaced = data.stats.buildsPlaced + 1
end

-- Clean up player data
function DataService:CleanupPlayer(player)
    playerData[player.UserId] = nil
end

-- Initialize
Players.PlayerAdded:Connect(function(player)
    DataService:InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    DataService:CleanupPlayer(player)
end)

return DataService
