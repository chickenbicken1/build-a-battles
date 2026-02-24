-- GameManager - Main coordinator (loads services in the correct order)
-- NOTE: Only ModuleScripts (.lua extension via Rojo) can be require()d.
-- AuraService is a standalone Script — it self-initializes and listens for events.
-- We only need to require RollService to trigger its setup, and wire EggShop.
local ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTANT: RollService MUST be required first — it creates the Remotes folder
-- and all RemoteEvents that other services and clients depend on.
local RollService = require(ServerScriptService:WaitForChild("RollService"))

-- Wire EggShop to RollService for gem/pet operations
local EggShop = require(ServerScriptService:WaitForChild("EggShop"))
EggShop:SetRollService(RollService)

-- AuraService is a standalone Script (not a ModuleScript), so it self-starts.
-- It reads RollService.playerData via the shared module reference.

print("✅ Game Manager Initialized")
print("📝 Controls:")
print("   SPACE or Click — Roll for aura")
print("   I             — Open Inventory")
print("   P             — Open Pet Manager")
print("   Click Eggs    — Open Egg at spawn")
