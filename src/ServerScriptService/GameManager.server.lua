-- GameManager - Fortnite Style Build Battles
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)

local GameManager = {}
local currentPhase = "LOBBY"
local phaseStartTime = 0
local gameActive = false

-- Load systems
local DataService = require(script.Parent.DataService)
local BuildingSystem = require(script.Parent.BuildingSystem)
local CombatSystem = require(script.Parent.CombatSystem)

-- Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local GameStateEvent = Instance.new("RemoteEvent")
GameStateEvent.Name = "GameStateEvent"
GameStateEvent.Parent = Remotes

function GameManager:Init()
    -- Setup systems in order
    BuildingSystem:SetDataService(DataService)
    BuildingSystem:Init()
    CombatSystem:Init()
    
    self:SetupSpawnLocations()
    
    -- Start game loop
    task.spawn(function()
        self:GameLoop()
    end)
    
    print("✅ Game Manager Initialized")
end

-- Setup spawn locations
function GameManager:SetupSpawnLocations()
    local spawns = Instance.new("Folder")
    spawns.Name = "SpawnLocations"
    spawns.Parent = workspace
    
    -- Create 4 team spawns around the build zone
    for i = 1, 4 do
        local angle = (i - 1) * (math.pi / 2)
        local radius = 80
        
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "Spawn" .. i
        spawn.Position = Vector3.new(
            math.cos(angle) * radius,
            10,
            math.sin(angle) * radius
        )
        spawn.Anchored = true
        spawn.CanCollide = false
        spawn.Transparency = 1
        spawn.Parent = spawns
    end
end

-- Main game loop
function GameManager:GameLoop()
    while true do
        -- LOBBY PHASE
        self:SetPhase("LOBBY")
        self:Broadcast("Waiting for players...")
        self:WaitForPlayers(1)
        self:Countdown(Config.PHASES.LOBBY.duration)
        
        -- BUILD PHASE
        self:SetPhase("BUILD")
        self:Broadcast("BUILD PHASE! Construct your fort!")
        self:EnableBuilding(true)
        self:Countdown(Config.PHASES.BUILD.duration)
        self:EnableBuilding(false)
        
        -- COMBAT PHASE
        self:SetPhase("COMBAT")
        self:Broadcast("COMBAT PHASE! Destroy enemy forts!")
        self:GiveWeapons()
        self:Countdown(Config.PHASES.COMBAT.duration)
        self:RemoveWeapons()
        
        -- END PHASE
        self:SetPhase("END")
        self:Broadcast("Round Over!")
        self:ResetRound()
        
        task.wait(Config.PHASES.END.duration)
    end
end

-- Set current phase
function GameManager:SetPhase(phase)
    currentPhase = phase
    phaseStartTime = tick()
    
    GameStateEvent:FireAllClients("PHASE", {
        phase = phase,
        duration = Config.PHASES[phase].duration
    })
    
    print(string.format("🎮 Phase: %s", phase))
end

-- Wait for minimum players
function GameManager:WaitForPlayers(minPlayers)
    while #Players:GetPlayers() < minPlayers do
        task.wait(1)
    end
end

-- Countdown timer
function GameManager:Countdown(duration)
    for i = duration, 1, -1 do
        GameStateEvent:FireAllClients("TIMER", i)
        task.wait(1)
    end
end

-- Broadcast message
function GameManager:Broadcast(message)
    GameStateEvent:FireAllClients("MESSAGE", message)
    print(string.format("📢 %s", message))
end

-- Enable/disable building
function GameManager:EnableBuilding(enabled)
    GameStateEvent:FireAllClients("BUILDING_ENABLED", enabled)
end

-- Give weapons for combat
function GameManager:GiveWeapons()
    for _, player in ipairs(Players:GetPlayers()) do
        local tool = Instance.new("Tool")
        tool.Name = "Assault Rifle"
        tool.CanBeDropped = false
        
        -- Create weapon model
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.5, 0.5, 3)
        handle.Color = Color3.fromRGB(80, 80, 90)
        handle.Material = Enum.Material.Metal
        handle.Parent = tool
        
        tool.GripPos = Vector3.new(0, 0, -1)
        tool.Parent = player.Backpack
    end
end

-- Remove weapons
function GameManager:RemoveWeapons()
    for _, player in ipairs(Players:GetPlayers()) do
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= "Pickaxe" then
                tool:Destroy()
            end
        end
        
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:UnequipTools()
            end
        end
    end
end

-- Reset round
function GameManager:ResetRound()
    -- Clear all builds
    BuildingSystem:ClearAllBuilds()
    
    -- Reset players
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end
end

-- Get current phase
function GameManager:GetCurrentPhase()
    return currentPhase
end

GameManager:Init()
return GameManager
