-- Build a Battles - Building System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local BuildEvents = ReplicatedStorage.Remotes.BuildEvents

local BuildingSystem = {}
local playerBuilds = {} -- Store each player's structures
local buildZones = {} -- Building area boundaries

function BuildingSystem:Init()
    -- Remote Events
    self.PlaceBlock = Instance.new("RemoteEvent")
    self.PlaceBlock.Name = "PlaceBlock"
    self.PlaceBlock.Parent = BuildEvents
    
    self.RemoveBlock = Instance.new("RemoteEvent")
    self.RemoveBlock.Name = "RemoveBlock"
    self.RemoveBlock.Parent = BuildEvents
    
    self:SetupListeners()
    print("✅ Building System Initialized")
end

function BuildingSystem:SetupListeners()
    -- Handle block placement
    self.PlaceBlock.OnServerEvent:Connect(function(player, position, blockType)
        if not self:CanBuild(player) then return end
        
        local block = self:CreateBlock(position, blockType, player)
        if block then
            self:TrackBlock(player, block)
        end
    end)
    
    -- Handle block removal
    self.RemoveBlock.OnServerEvent:Connect(function(player, block)
        if block and block:GetAttribute("Owner") == player.UserId then
            block:Destroy()
            self:UntrackBlock(player, block)
        end
    end)
end

function BuildingSystem:CanBuild(player)
    -- Check if player is in build phase and under block limit
    local builds = playerBuilds[player.UserId]
    if not builds then
        playerBuilds[player.UserId] = {}
        builds = playerBuilds[player.UserId]
    end
    
    return #builds < Config.BUILD.MAX_BLOCKS
end

function BuildingSystem:CreateBlock(position, blockType, player)
    local blockConfig = Config.BUILD.BLOCK_TYPES[blockType]
    if not blockConfig then return nil end
    
    local block = Instance.new("Part")
    block.Name = blockType .. "Block"
    block.Size = Vector3.new(Config.BUILD.GRID_SIZE, Config.BUILD.GRID_SIZE, Config.BUILD.GRID_SIZE)
    block.Position = self:SnapToGrid(position)
    block.Color = blockConfig.color
    block.Material = Enum.Material.SmoothPlastic
    block.Anchored = true
    block.CanCollide = true
    block:SetAttribute("Owner", player.UserId)
    block:SetAttribute("Health", blockConfig.health)
    block:SetAttribute("MaxHealth", blockConfig.health)
    block.Parent = workspace.Buildings
    
    -- Add health bar UI
    self:AddHealthBar(block)
    
    return block
end

function BuildingSystem:SnapToGrid(position)
    local grid = Config.BUILD.GRID_SIZE
    return Vector3.new(
        math.floor(position.X / grid + 0.5) * grid,
        math.floor(position.Y / grid + 0.5) * grid,
        math.floor(position.Z / grid + 0.5) * grid
    )
end

function BuildingSystem:AddHealthBar(block)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBar"
    billboard.Size = UDim2.new(2, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    
    local frame = Instance.new("Frame")
    frame.Name = "Bar"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    frame.Parent = billboard
    
    billboard.Parent = block
end

function BuildingSystem:TrackBlock(player, block)
    if not playerBuilds[player.UserId] then
        playerBuilds[player.UserId] = {}
    end
    table.insert(playerBuilds[player.UserId], block)
end

function BuildingSystem:UntrackBlock(player, block)
    local builds = playerBuilds[player.UserId]
    if builds then
        for i, b in ipairs(builds) do
            if b == block then
                table.remove(builds, i)
                break
            end
        end
    end
end

function BuildingSystem:ClearPlayerBuilds(player)
    local builds = playerBuilds[player.UserId]
    if builds then
        for _, block in ipairs(builds) do
            if block then block:Destroy() end
        end
        playerBuilds[player.UserId] = {}
    end
end

function BuildingSystem:GetPlayerBuilds(player)
    return playerBuilds[player.UserId] or {}
end

BuildingSystem:Init()
return BuildingSystem