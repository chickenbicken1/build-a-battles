-- GameManager - Orchestrates service initialization and dependencies
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── 1. Create Remotes Folder (Dependency for all services) ──────────────────
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local function InitRemote(name, class)
    if not Remotes:FindFirstChild(name) then
        local r = Instance.new(class or "RemoteEvent")
        r.Name = name ; r.Parent = Remotes
    end
end

-- Initialize all required remotes
InitRemote("RollEvent")
InitRemote("EquipAuraEvent")
InitRemote("EquipPetEvent")
InitRemote("DataUpdateEvent")
InitRemote("InventoryEvent")
InitRemote("AuraEquipEvent")
InitRemote("EggEvent")
InitRemote("ShopEvent")

-- ── 2. Require and Initialize Pure Modules ──────────────────────────────────
local RollService = require(ServerScriptService:WaitForChild("RollService"))
local EggShop = require(ServerScriptService:WaitForChild("EggShop"))

-- Wire dependencies
EggShop:SetRollService(RollService)

-- Kick off services
RollService:Init()
EggShop:Init()

print("✅ [GameManager] Full System Active")
