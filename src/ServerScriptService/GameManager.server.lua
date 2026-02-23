-- Build a Battles - Game Manager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local GameManager = {}
local currentPhase = Config.PHASES.LOBBY
local phaseTimer = 0
local playersInGame = {}

-- Require systems
local BuildingSystem = require(script.Parent.BuildingSystem)
local CombatSystem = require(script.Parent.CombatSystem)

function GameManager:Init()
    -- Create remote for UI updates
    self.GameStateEvent = Instance.new("RemoteEvent")
    self.GameStateEvent.Name = "GameStateEvent"
    self.GameStateEvent.Parent = ReplicatedStorage.Remotes
    
    -- Setup workspace folders
    self:SetupWorkspace()
    
    -- Start game loop
    task.spawn(function()
        self:GameLoop()
    end)
    
    print("✅ Game Manager Initialized")
end

function GameManager:SetupWorkspace()
    -- Buildings folder
    if not workspace:FindFirstChild("Buildings") then
        local buildings = Instance.new("Folder")
        buildings.Name = "Buildings"
        buildings.Parent = workspace
    end
    
    -- Spawn locations
    if not workspace:FindFirstChild("SpawnLocations") then
        local spawns = Instance.new("Folder")
        spawns.Name = "SpawnLocations"
        spawns.Parent = workspace
        
        -- Create team spawn areas
        for i = 1, 4 do
            local spawn = Instance.new("SpawnLocation")
            spawn.Name = "Team" .. i .. "Spawn"
            spawn.Position = Vector3.new((i-2.5) * 100, 10, 0)
            spawn.Parent = spawns
            
            -- Build zone
            local zone = Instance.new("Part")
            zone.Name = "BuildZone" .. i
            zone.Size = Vector3.new(80, 1, 80)
            zone.Position = Vector3.new((i-2.5) * 100, 0.5, 0)
            zone.Color = Color3.fromRGB(100, 100, 100)
            zone.Anchored = true
            zone.CanCollide = true
            zone.Transparency = 0.5
            zone.Parent = workspace
        end
    end
end

function GameManager:GameLoop()
    while true do
        -- LOBBY PHASE (30 seconds)
        self:SetPhase(Config.PHASES.LOBBY)
        self:Broadcast("Waiting for players...")
        self:WaitForPlayers(2) -- Minimum 2 players
        self:Countdown(30)
        
        -- BUILDING PHASE
        self:SetPhase(Config.PHASES.BUILDING)
        self:Broadcast("BUILD PHASE! Create your fortress!")
        self:EnableBuilding(true)
        self:Countdown(Config.BUILD.BUILD_TIME)
        self:EnableBuilding(false)
        
        -- COMBAT PHASE
        self:SetPhase(Config.PHASES.COMBAT)
        self:Broadcast("COMBAT PHASE! Destroy enemy bases!")
        CombatSystem:SetCombatState(true)
        self:TeleportToBuildZones()
        self:Countdown(Config.COMBAT.ROUND_TIME)
        CombatSystem:SetCombatState(false)
        
        -- END PHASE
        self:SetPhase(Config.PHASES.END)
        self:Broadcast("Round Over!")
        self:ClearBuildings()
        self:ResetPlayers()
        
        task.wait(10)
    end
end

function GameManager:SetPhase(phase)
    currentPhase = phase
    self.GameStateEvent:FireAllClients(phase)
    print("🎮 Phase changed to:", phase)
end

function GameManager:GetCurrentPhase()
    return currentPhase
end

function GameManager:EnableBuilding(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        local tool = require(player.PlayerScripts:WaitForChild("BuildTool"))
        if tool then
            tool:SetBuildingEnabled(enabled)
        end
    end
end

function GameManager:TeleportToBuildZones()
    local players = Players:GetPlayers()
    for i, player in ipairs(players) do
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local zoneNum = ((i - 1) % 4) + 1
                local spawnPos = Vector3.new((zoneNum - 2.5) * 100, 20, 0)
                root.CFrame = CFrame.new(spawnPos)
            end
        end
    end
end

function GameManager:ClearBuildings()
    for _, block in ipairs(workspace.Buildings:GetChildren()) do
        block:Destroy()
    end
end

function GameManager:ResetPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
        
        -- Clear build tracking
        if BuildingSystem.ClearPlayerBuilds then
            BuildingSystem:ClearPlayerBuilds(player)
        end
    end
end

function GameManager:Broadcast(message)
    print("📢", message)
    self.GameStateEvent:FireAllClients("MESSAGE", message)
end

function GameManager:Countdown(seconds)
    for i = seconds, 1, -1 do
        if i % 10 == 0 or i <= 5 then
            self.GameStateEvent:FireAllClients("TIMER", i)
        end
        task.wait(1)
    end
end

function GameManager:WaitForPlayers(minPlayers)
    while #Players:GetPlayers() < minPlayers do
        self:Broadcast("Need " .. (minPlayers - #Players:GetPlayers()) .. " more player(s)...")
        task.wait(3)
    end
end

GameManager:Init()
return GameManager