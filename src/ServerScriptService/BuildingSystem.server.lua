-- Build a Battles - Building System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for Config
local Config
local success = pcall(function()
    Config = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Config", 5))
end)

if not success or not Config then
    warn("BuildingSystem: Could not load Config, using defaults")
    Config = {
        BUILD = {
            MAX_BLOCKS = 200,
            GRID_SIZE = 4,
            BLOCK_TYPES = {
                WOOD = { health = 100, color = Color3.fromRGB(161, 111, 67) },
                STONE = { health = 300, color = Color3.fromRGB(125, 125, 125) },
                METAL = { health = 500, color = Color3.fromRGB(80, 80, 90) }
            }
        }
    }
end

-- Create Remotes folder
local BuildEvents = ReplicatedStorage:FindFirstChild("Remotes")
if not BuildEvents then
    BuildEvents = Instance.new("Folder")
    BuildEvents.Name = "Remotes"
    BuildEvents.Parent = ReplicatedStorage
end

local BuildingSystem = {}
local playerBuilds = {}

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
    self.PlaceBlock.OnServerEvent:Connect(function(player, position, blockType)
        if not self:CanBuild(player) then return end
        
        local block = self:CreateBlock(position, blockType, player)
        if block then
            self:TrackBlock(player, block)
        end
    end)
    
    self.RemoveBlock.OnServerEvent:Connect(function(player, block)
        if block and block:GetAttribute("Owner") == player.UserId then
            block:Destroy()
            self:UntrackBlock(player, block)
        end
    end)
end

function BuildingSystem:CanBuild(player)
    local builds = playerBuilds[player.UserId]
    if not builds then
        playerBuilds[player.UserId] = {}
        builds = playerBuilds[player.UserId]
    end
    
    local maxBlocks = (Config.BUILD and Config.BUILD.MAX_BLOCKS) or 200
    return #builds < maxBlocks
end

function BuildingSystem:CreateBlock(position, blockType, player)
    local blockTypes = Config.BUILD and Config.BUILD.BLOCK_TYPES or {}
    local blockConfig = blockTypes[blockType]
    if not blockConfig then return nil end
    
    local gridSize = (Config.BUILD and Config.BUILD.GRID_SIZE) or 4
    
    local block = Instance.new("Part")
    block.Name = blockType .. "Block"
    block.Size = Vector3.new(gridSize, gridSize, gridSize)
    block.Position = self:SnapToGrid(position, gridSize)
    block.Color = blockConfig.color
    block.Material = Enum.Material.SmoothPlastic
    block.Anchored = true
    block.CanCollide = true
    block:SetAttribute("Owner", player.UserId)
    block:SetAttribute("Health", blockConfig.health)
    block:SetAttribute("MaxHealth", blockConfig.health)
    
    local buildings = workspace:FindFirstChild("Buildings")
    if not buildings then
        buildings = Instance.new("Folder")
        buildings.Name = "Buildings"
        buildings.Parent = workspace
    end
    block.Parent = buildings
    
    self:AddHealthBar(block)
    return block
end

function BuildingSystem:SnapToGrid(position, grid)
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

-- Initialize with delay
task.delay(2, function()
    BuildingSystem:Init()
end)

return BuildingSystem