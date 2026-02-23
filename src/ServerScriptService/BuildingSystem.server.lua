-- BuildingSystem - Fortnite Style Building
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BuildingSystem = {}
local buildsFolder = nil
local buildZoneCenter = Vector3.new(0, 0, 0)

-- Setup remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local PlaceBuildEvent = Instance.new("RemoteEvent")
PlaceBuildEvent.Name = "PlaceBuild"
PlaceBuildEvent.Parent = Remotes

local MaterialUpdateEvent = Instance.new("RemoteEvent")
MaterialUpdateEvent.Name = "MaterialUpdate"
MaterialUpdateEvent.Parent = Remotes

-- Get DataService reference
local DataService = require(script.Parent.DataService)

function BuildingSystem:Init()
    -- Create builds folder
    buildsFolder = Instance.new("Folder")
    buildsFolder.Name = "Builds"
    buildsFolder.Parent = workspace
    
    -- Create build zone visual
    self:CreateBuildZone()
    
    -- Setup event listeners
    PlaceBuildEvent.OnServerEvent:Connect(function(player, pieceType, position, normal, materialType)
        return self:HandleBuildRequest(player, pieceType, position, normal, materialType)
    end)
    
    -- Give materials periodically (like harvesting)
    task.spawn(function()
        while true do
            task.wait(5)
            for _, player in ipairs(Players:GetPlayers()) do
                DataService:AddMaterial(player, "WOOD", 5)
            end
        end
    end)
    
    print("✅ Building System Initialized")
end

-- Create build zone visual
function BuildingSystem:CreateBuildZone()
    if not Config.BUILD_ZONE.ENABLED then return end
    
    -- Visual boundary
    local zone = Instance.new("Part")
    zone.Name = "BuildZone"
    zone.Size = Vector3.new(Config.BUILD_ZONE.RADIUS * 2, 1, Config.BUILD_ZONE.RADIUS * 2)
    zone.Position = Vector3.new(0, -0.5, 0)
    zone.Anchored = true
    zone.CanCollide = false
    zone.Transparency = 0.9
    zone.Color = Color3.fromRGB(50, 150, 255)
    zone.Material = Enum.Material.Neon
    zone.Parent = workspace
    
    -- Corner markers
    for i = 1, 4 do
        local angle = (i - 1) * math.pi / 2
        local marker = Instance.new("Part")
        marker.Size = Vector3.new(2, 10, 2)
        marker.Position = Vector3.new(
            math.cos(angle) * Config.BUILD_ZONE.RADIUS,
            5,
            math.sin(angle) * Config.BUILD_ZONE.RADIUS
        )
        marker.Anchored = true
        marker.CanCollide = false
        marker.Color = Color3.fromRGB(255, 200, 50)
        marker.Material = Enum.Material.Neon
        marker.Parent = workspace
    end
end

-- Handle build request from client
function BuildingSystem:HandleBuildRequest(player, pieceType, position, normal, materialType)
    -- Validate inputs
    if not pieceType or not position or not normal then
        return false, "Invalid parameters"
    end
    
    -- Check material type
    materialType = materialType or "WOOD"
    if not Config.MATERIALS[materialType] then
        return false, "Invalid material"
    end
    
    -- Check piece type
    local pieceConfig = Config.BUILD_PIECES[pieceType]
    if not pieceConfig then
        return false, "Invalid piece type"
    end
    
    -- Check build zone
    if Config.BUILD_ZONE.ENABLED then
        if not Utils.IsInBuildZone(position, buildZoneCenter, Config.BUILD_ZONE.RADIUS, Config.BUILD_ZONE.HEIGHT) then
            return false, "Outside build zone"
        end
    end
    
    -- Check materials (cost = 10)
    local cost = 10
    if not DataService:RemoveMaterial(player, materialType, cost) then
        return false, "Not enough materials"
    end
    
    -- Create the build
    local success, result = pcall(function()
        return self:CreateBuildPiece(player, pieceType, position, normal, materialType)
    end)
    
    if success and result then
        DataService:TrackBuild(player, result)
        return true, result
    else
        -- Refund materials on failure
        DataService:AddMaterial(player, materialType, cost)
        return false, "Build failed"
    end
end

-- Create build piece
function BuildingSystem:CreateBuildPiece(player, pieceType, position, normal, materialType)
    local pieceConfig = Config.BUILD_PIECES[pieceType]
    local materialConfig = Config.MATERIALS[materialType]
    
    -- Calculate rotation based on normal
    local rotation = Utils.GetRotationFromNormal(normal)
    
    -- Calculate final position
    local finalPosition = position + (normal * pieceConfig.offset)
    finalPosition = Utils.SnapToGrid(finalPosition, Config.BUILD.GRID_SIZE)
    
    -- Create the part
    local build = Instance.new("Part")
    build.Name = player.Name .. "_" .. pieceType
    build.Size = pieceConfig.size
    build.Position = finalPosition
    build.CFrame = CFrame.new(finalPosition) * rotation
    build.Anchored = true
    build.CanCollide = true
    build.Color = materialConfig.color
    build.Material = materialConfig.material
    build:SetAttribute("Owner", player.UserId)
    build:SetAttribute("PieceType", pieceType)
    build:SetAttribute("MaterialType", materialType)
    build:SetAttribute("Health", materialConfig.health)
    build:SetAttribute("MaxHealth", materialConfig.maxHealth)
    build.Parent = buildsFolder
    
    -- Add health bar
    self:AddHealthBar(build)
    
    -- Add build effect
    self:PlayBuildEffect(build)
    
    return build
end

-- Add health bar to build
function BuildingSystem:AddHealthBar(build)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBar"
    billboard.Size = UDim2.new(0, 60, 0, 8)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    
    billboard.Parent = build
end

-- Update health bar
function BuildingSystem:UpdateHealthBar(build)
    local healthBar = build:FindFirstChild("HealthBar")
    if not healthBar then return end
    
    local health = build:GetAttribute("Health") or 0
    local maxHealth = build:GetAttribute("MaxHealth") or 1
    local percent = math.clamp(health / maxHealth, 0, 1)
    
    local fill = healthBar:FindFirstChild("Background") and healthBar.Background:FindFirstChild("Fill")
    if fill then
        fill.Size = UDim2.new(percent, 0, 1, 0)
        
        -- Color based on health
        if percent > 0.5 then
            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        elseif percent > 0.25 then
            fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end

-- Damage build
function BuildingSystem:DamageBuild(build, damage, attacker)
    local health = build:GetAttribute("Health") or 0
    local owner = build:GetAttribute("Owner")
    
    -- Can't damage own builds (optional rule)
    if attacker and owner == attacker.UserId then
        return false
    end
    
    local newHealth = math.max(0, health - damage)
    build:SetAttribute("Health", newHealth)
    
    self:UpdateHealthBar(build)
    
    if newHealth <= 0 then
        self:DestroyBuild(build, attacker)
        return true
    end
    
    return false
end

-- Destroy build
function BuildingSystem:DestroyBuild(build, destroyer)
    -- Play destroy effect
    self:PlayDestroyEffect(build)
    
    -- Drop some materials (30% of cost)
    local materialType = build:GetAttribute("MaterialType")
    if materialType and destroyer then
        local dropAmount = math.random(1, 3)
        DataService:AddMaterial(destroyer, materialType, dropAmount)
    end
    
    build:Destroy()
end

-- Play build effect
function BuildingSystem:PlayBuildEffect(build)
    -- Particle burst
    for i = 1, 8 do
        local particle = Instance.new("Part")
        particle.Size = Vector3.new(0.2, 0.2, 0.2)
        particle.Position = build.Position
        particle.Color = build.Color
        particle.Material = Enum.Material.Neon
        particle.Anchored = false
        particle.CanCollide = false
        particle.Parent = workspace
        
        local angle = (i / 8) * math.pi * 2
        particle.Velocity = Vector3.new(
            math.cos(angle) * 10,
            math.random(5, 15),
            math.sin(angle) * 10
        )
        
        game:GetService("Debris"):AddItem(particle, 0.5)
    end
end

-- Play destroy effect
function BuildingSystem:PlayDestroyEffect(build)
    local explosion = Instance.new("Explosion")
    explosion.Position = build.Position
    explosion.BlastRadius = 3
    explosion.BlastPressure = 0
    explosion.Parent = workspace
    
    -- Debris
    for i = 1, 6 do
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(0.5, 0.5, 0.5)
        debris.Position = build.Position
        debris.Color = build.Color
        debris.Velocity = Vector3.new(
            math.random(-20, 20),
            math.random(10, 30),
            math.random(-20, 20)
        )
        debris.Parent = workspace
        game:GetService("Debris"):AddItem(debris, 2)
    end
end

-- Clear all builds
function BuildingSystem:ClearAllBuilds()
    for _, build in ipairs(buildsFolder:GetChildren()) do
        build:Destroy()
    end
end

BuildingSystem:Init()
return BuildingSystem
