-- AuraService - Server: re-equips aura on character respawn
-- This is a standalone Script (not a ModuleScript) — it self-initializes.
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RollService to create its Remotes and return itself
-- RollService is a Script, NOT a ModuleScript — we can't require() it directly.
-- Instead, we share player data via the Config module approach using a BindableEvent
-- or simply by waiting for the Remotes event system.

-- The aura re-equip is handled by firing AuraEquipEvent to all clients.
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local AuraEquipEvent  = Remotes:WaitForChild("AuraEquipEvent")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")

-- We keep our own map of userId -> equippedAuraId, updated by listening
-- to the server's own data sync events (we intercept them on server side).
-- Actually, we just refire the stored aura from the RollService playerData.
-- Since we can't import RollService (both are Scripts), we store it here.
local equippedAuras = {}  -- userId -> auraId, mirrors RollService

-- Listen for equip events from clients (these pass through to us too)
AuraEquipEvent.OnServerEvent:Connect(function(player, auraId)
    -- Store the equipped aura so we can re-apply on respawn
    if auraId and type(auraId) == "string" then
        equippedAuras[player.UserId] = auraId
        -- Broadcast to all clients so everyone sees this player's aura
        AuraEquipEvent:FireAllClients(player.UserId, auraId)
    end
end)

-- On character respawn, re-equip their last known aura
local function OnCharacterAdded(player, _char)
    task.wait(1.5) -- wait for HumanoidRootPart

    local auraId = equippedAuras[player.UserId]
    if auraId then
        AuraEquipEvent:FireAllClients(player.UserId, auraId)
    end
end

-- Hook up character respawn for all players
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        OnCharacterAdded(player, char)
    end)

    player.CharacterRemoving:Connect(function()
        -- Don't clear equippedAuras here — we want to persist across respawn
    end)
end

Players.PlayerAdded:Connect(function(player)
    SetupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    equippedAuras[player.UserId] = nil
end)

-- Handle already-joined players (on game start in Studio)
for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

print("✅ Aura Service Initialized")
