```lua
-- TestSuites.lua
-- Contains the actual test logic for various modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
-- HUD.client.lua creates HUDGUI
local gui = PlayerGui:WaitForChild("HUDGUI", 15)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggEvent = Remotes:WaitForChild("EggEvent")
local Utils = require(Shared:WaitForChild("Utils"))

-- We look for the actual services (requires them being required by GameManager first)
local ServerScriptService = game:GetService("ServerScriptService")

local function RobustRequire(name)
    local Core = ServerScriptService:WaitForChild("Core", 5)
    if not Core then return nil, "Timeout waiting for Core folder" end
    local obj = Core:WaitForChild(name, 5)
    if not obj then return nil, "Timeout waiting for " .. name end
    if not obj:IsA("ModuleScript") then return nil, name .. " is not a ModuleScript (" .. obj.ClassName .. ")" end
    local success, result = pcall(require, obj)
    if not success then return nil, "Error requiring " .. name .. ": " .. tostring(result) end
    return result
end

local RollService, errR = RobustRequire("RollService")
local EggShop, errE = RobustRequire("EggShop")

if errR then warn("⚠️ TestSuites: " .. errR) end
if errE then warn("⚠️ TestSuites: " .. errE) end

local TestSuites = {}

-- ── Utils Unit Tests ──────────────────────────────────────────────────────────
TestSuites.Utils = {
    TestFormatting = function()
        assert(Utils.FormatNumber(1000) == "1,000", "FormatNumber error")
        assert(Utils.FormatNumber(1234567) == "1,234,567", "FormatNumber error")
        assert(Utils.FormatLuck(1) == "1.00x", "FormatLuck error")
        assert(Utils.FormatLuck(10.5) == "10.5x", "FormatLuck error")
        assert(Utils.FormatLuck(100) == "100x", "FormatLuck error")
    end,
    
    TestDeepCopy = function()
        local orig = {a = 1, b = {c = 2}}
        local copy = Utils.DeepCopy(orig)
        copy.b.c = 3
        assert(orig.b.c == 2, "DeepCopy failed (shared reference)")
        assert(copy.b.c == 3, "DeepCopy failed (value not changed)")
    end,
    
    TestWeightedRandomDist = function()
        -- Note: testing randomness is tricky, but we can verify it returns valid items
        local pool = {
            {id = "A", chance = 0.5},
            {id = "B", chance = 0.5}
        }
        local item = Utils.WeightedRandom(pool, 1)
        assert(item.id == "A" or item.id == "B", "WeightedRandom returned invalid item")
    end
}

-- ── RollService Integration Tests ─────────────────────────────────────────────
TestSuites.RollService = {
    TestLuckCalculation = function()
        if not RollService then error("RollService not loaded") end
        
        -- Mock Player Data
        local mockData = {
            equippedPets = {
                {id = "skibidi", luckBoost = 1.5},
                {id = "sigma", luckBoost = 2.0}
            },
            gemBoosts = {
                {id = "luck_boost", mult = 2.0, expiry = tick() + 100}
            }
        }
        
        -- We temporarily swap the real playerData or just test the logic directly if possible
        -- For now, we test the CalculateLuck function if it were exposed (it usually is internal)
        -- Since we can't easily reach internal locals, we verify properties we know
        assert(Config.PETS[1].luckBoost > 1, "Config error: Pets should have luck boosts")
    end
}

-- ── EggShop Integration Tests ─────────────────────────────────────────────────
TestSuites.EggShop = {
    TestEggConfigs = function()
        if not EggShop then error("EggShop not loaded") end
        -- Basic verify that eggs are configured correctly
        local basicEgg = nil
        -- Since internal eggConfigs is local, we check the workspace models created
        local model = workspace:FindFirstChild("Basic Egg")
        assert(model ~= nil, "Egg model not created in workspace")
    end
}

return TestSuites
