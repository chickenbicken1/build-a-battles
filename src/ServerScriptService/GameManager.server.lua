-- Build a Battles - Game Manager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for Config
local Config
local success = pcall(function()
    Config = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Config", 5))
end)

if not success or not Config then
    warn("GameManager: Could not load Config, using defaults")
    Config = {
        PHASES = { LOBBY = "LOBBY", BUILDING = "BUILDING", COMBAT = "COMBAT", END = "END" },
        BUILD = { BUILD_TIME = 120, MAX_BLOCKS = 200 },
        COMBAT = { ROUND_TIME = 180 }
    }
end

-- Create Remotes folder
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local GameManager = {}
local currentPhase = Config.PHASES.LOBBY
local phaseTimer = 0

function GameManager:Init()
    -- Create remote for UI updates
    self.GameStateEvent = Instance.new("RemoteEvent")
    self.GameStateEvent.Name = "GameStateEvent"
    self.GameStateEvent.Parent = Remotes
    
    -- Setup workspace
    self:SetupWorkspace()
    
    -- Start game loop
    task.spawn(function()
        self:GameLoop()
    end)
    
    print("✅ Game Manager Initialized")
end

function GameManager:SetupWorkspace()
    -- Baseplate
    if not workspace:FindFirstChild("Baseplate") then
        local baseplate = Instance.new("Part")
        baseplate.Name = "Baseplate"
        baseplate.Size = Vector3.new(512, 1, 512)
        baseplate.Position = Vector3.new(0, -0.5, 0)
        baseplate.Anchored = true
        baseplate.CanCollide = true
        baseplate.Color = Color3.fromRGB(100, 100, 100)
        baseplate.Material = Enum.Material.SmoothPlastic
        baseplate.Parent = workspace
    end
    
    -- Spawn location
    if not workspace:FindFirstChild("SpawnLocation") then
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "SpawnLocation"
        spawn.Position = Vector3.new(0, 1, 0)
        spawn.Anchored = true
        spawn.CanCollide = false
        spawn.Parent = workspace
    end
    
    -- Buildings folder
    if not workspace:FindFirstChild("Buildings") then
        local buildings = Instance.new("Folder")
        buildings.Name = "Buildings"
        buildings.Parent = workspace
    end
    
    -- Spawn locations for teams
    if not workspace:FindFirstChild("SpawnLocations") then
        local spawns = Instance.new("Folder")
        spawns.Name = "SpawnLocations"
        spawns.Parent = workspace
        
        for i = 1, 4 do
            local spawn = Instance.new("Part")
            spawn.Name = "Team" .. i .. "Spawn"
            spawn.Size = Vector3.new(10, 1, 10)
            spawn.Position = Vector3.new((i-2.5) * 100, 0.5, 0)
            spawn.Anchored = true
            spawn.CanCollide = true
            spawn.Color = Color3.fromRGB(75, 75, 75)
            spawn.Parent = spawns
            
            -- Build zone
            local zone = Instance.new("Part")
            zone.Name = "BuildZone" .. i
            zone.Size = Vector3.new(80, 1, 80)
            zone.Position = Vector3.new((i-2.5) * 100, 0.5, 0)
            zone.Color = Color3.fromRGB(100, 100, 100)
            zone.Transparency = 0.5
            zone.Anchored = true
            zone.CanCollide = true
            zone.Parent = workspace
        end
    end
end

function GameManager:GameLoop()
    while true do
        -- LOBBY PHASE
        self:SetPhase(Config.PHASES.LOBBY)
        self:Broadcast("Waiting for players...")
        self:WaitForPlayers(1)
        self:Countdown(10)
        
        -- BUILDING PHASE
        self:SetPhase(Config.PHASES.BUILDING)
        self:Broadcast("BUILD PHASE! Create your fortress!")
        self:EnableBuilding(true)
        self:GiveBuildTools()
        local buildTime = (Config.BUILD and Config.BUILD.BUILD_TIME) or 120
        self:Countdown(buildTime)
        self:EnableBuilding(false)
        
        -- COMBAT PHASE
        self:SetPhase(Config.PHASES.COMBAT)
        self:Broadcast("COMBAT PHASE! Destroy enemy bases!")
        self:GiveWeapons()
        local combatTime = (Config.COMBAT and Config.COMBAT.ROUND_TIME) or 180
        self:TeleportToBuildZones()
        self:Countdown(combatTime)
        self:RemoveWeapons()
        
        -- END PHASE
        self:SetPhase(Config.PHASES.END)
        self:Broadcast("Round Over!")
        self:ClearBuildings()
        self:ResetPlayers()
        
        task.wait(5)
    end
end

function GameManager:EnableBuilding(enabled)
    self.GameStateEvent:FireAllClients("BUILDING_ENABLED", enabled)
    print("🔨 Building enabled:", enabled)
end

function GameManager:GiveBuildTools()
    for _, player in ipairs(Players:GetPlayers()) do
        local tool = Instance.new("Tool")
        tool.Name = "BuildTool"
        tool.CanBeDropped = false
        tool.Parent = player.Backpack
        print("🔨 Gave build tool to", player.Name)
    end
end

function GameManager:GiveWeapons()
    local WeaponModels = require(ReplicatedStorage.Shared.WeaponModels)
    for _, player in ipairs(Players:GetPlayers()) do
        -- Give sword
        local sword = WeaponModels:CreateTool("Sword", "default")
        sword.Parent = player.Backpack
        print("⚔️ Gave sword to", player.Name)
    end
end

function GameManager:RemoveWeapons()
    for _, player in ipairs(Players:GetPlayers()) do
        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= "BuildTool" then
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

function GameManager:SetPhase(phase)
    currentPhase = phase
    self.GameStateEvent:FireAllClients("PHASE", {phase = phase, timeLeft = 0})
    print("🎮 Phase:", phase)
end

function GameManager:Broadcast(message)
    print("📢", message)
    self.GameStateEvent:FireAllClients("MESSAGE", message)
end

function GameManager:Countdown(seconds)
    for i = seconds, 1, -1 do
        -- Send timer update every second
        self.GameStateEvent:FireAllClients("TIMER", i)
        task.wait(1)
    end
end

function GameManager:WaitForPlayers(minPlayers)
    while #Players:GetPlayers() < minPlayers do
        task.wait(1)
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
                local spawnPos = Vector3.new((zoneNum - 2.5) * 100, 10, 0)
                root.CFrame = CFrame.new(spawnPos)
            end
        end
    end
end

function GameManager:ClearBuildings()
    local buildings = workspace:FindFirstChild("Buildings")
    if buildings then
        for _, block in ipairs(buildings:GetChildren()) do
            block:Destroy()
        end
    end
end

function GameManager:ResetPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
    end
end

-- Initialize with delay
task.delay(4, function()
    GameManager:Init()
end)

return GameManager