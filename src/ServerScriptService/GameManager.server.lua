-- GameManager - Main coordinator
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create Remotes folder
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

-- Load all systems in order
local RollService = require(script.Parent.RollService)
local AuraService = require(script.Parent.AuraService)
local EggShop = require(script.Parent.EggShop)

local GameManager = {}

function GameManager:Init()
    print("🎮 Initializing Brainrot RNG...")
    
    -- Initialize RollService first (handles player data)
    -- RollService auto-initializes on load
    
    -- Set up cross-service references
    EggShop:SetRollService(RollService)
    EggShop:SetPlayerData(RollService.playerData)
    
    print("✅ Game Manager Initialized")
    print("📝 Controls:")
    print("   SPACE - Roll for aura")
    print("   B - Toggle Build Mode (if available)")
    print("   I - Open Inventory")
    print("   Click eggs at spawn to open them!")
end

GameManager:Init()
return GameManager
