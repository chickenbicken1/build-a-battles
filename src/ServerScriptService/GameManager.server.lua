-- GameManager - Main coordinator (loads services in the correct order)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- IMPORTANT: RollService MUST be required first — it creates the Remotes folder
-- and all RemoteEvents that other services and clients depend on.
local RollService = require(script.Parent.RollService)
local AuraService = require(script.Parent.AuraService)
local EggShop     = require(script.Parent.EggShop)

local GameManager = {}

function GameManager:Init()
    print("🎮 Initializing Aura Roller...")

    -- Wire AuraService to RollService so it can read player data for respawn
    AuraService:Init(RollService)

    -- Wire EggShop to RollService for gem/pet operations
    EggShop:SetRollService(RollService)

    print("✅ Game Manager Initialized")
    print("📝 Controls:")
    print("   SPACE or Click — Roll for aura")
    print("   I             — Open Inventory")
    print("   P             — Open Pet Manager")
    print("   Click Eggs    — Open Egg at spawn")
end

GameManager:Init()
return GameManager
