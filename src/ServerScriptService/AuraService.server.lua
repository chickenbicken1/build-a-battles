-- AuraService - Server: re-equips aura on respawn using RollService data
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

-- Wait for RollService to create the Remotes folder and AuraEquipEvent
local Remotes        = ReplicatedStorage:WaitForChild("Remotes")
local AuraEquipEvent = Remotes:WaitForChild("AuraEquipEvent")

-- We import RollService lazily (it is the parent's sibling)
-- RollService exposes .playerData table directly
local RollService = nil

local AuraService  = {}

-- Re-equip the player's stored aura to all clients after respawn
function AuraService:ReequipAura(player)
    if not RollService then return end
    local data = RollService:GetPlayerData(player)
    if not data then return end
    if not data.equippedAura then return end

    -- Announce to all clients (AuraRenderer handles the actual VFX)
    AuraEquipEvent:FireAllClients(player.UserId, data.equippedAura)
end

-- Initialize per-player character tracking
function AuraService:SetupPlayer(player)
    player.CharacterAdded:Connect(function(_char)
        task.wait(1.5) -- wait for HRP to be fully loaded
        self:ReequipAura(player)
    end)
end

function AuraService:Init(rollServiceRef)
    RollService = rollServiceRef

    -- Hook existing players (in case this runs after some joined)
    for _, p in ipairs(Players:GetPlayers()) do
        self:SetupPlayer(p)
    end

    Players.PlayerAdded:Connect(function(p)
        self:SetupPlayer(p)
    end)

    print("✅ Aura Service Initialized")
end

return AuraService
