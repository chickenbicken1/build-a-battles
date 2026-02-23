-- CombatSystem - Damage, Health, Weapons
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)

local CombatSystem = {}
local playerHealth = {}
local combatActive = false

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatEvent = Instance.new("RemoteEvent")
CombatEvent.Name = "CombatEvent"
CombatEvent.Parent = Remotes

function CombatSystem:Init()
    -- Setup player health
    Players.PlayerAdded:Connect(function(player)
        playerHealth[player.UserId] = Config.COMBAT.PLAYER_HEALTH
        
        player.CharacterAdded:Connect(function(char)
            self:SetupCharacter(char, player)
        end)
    end)
    
    -- Handle combat requests
    CombatEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "DAMAGE_BUILD" then
            self:HandleBuildDamage(player, ...)
        elseif action == "DAMAGE_PLAYER" then
            self:HandlePlayerDamage(player, ...)
        end
    end)
    
    print("✅ Combat System Initialized")
end

-- Setup character
function CombatSystem:SetupCharacter(char, player)
    local hum = char:WaitForChild("Humanoid")
    hum.MaxHealth = Config.COMBAT.PLAYER_HEALTH
    hum.Health = playerHealth[player.UserId] or Config.COMBAT.PLAYER_HEALTH
    
    hum.HealthChanged:Connect(function(newHealth)
        playerHealth[player.UserId] = newHealth
        
        -- Sync to client
        CombatEvent:FireClient(player, "HEALTH_UPDATE", newHealth, hum.MaxHealth)
        
        if newHealth <= 0 then
            self:HandleDeath(player)
        end
    end)
    
    -- Give pickaxe
    self:GivePickaxe(player)
end

-- Give pickaxe tool
function CombatSystem:GivePickaxe(player)
    local pickaxe = Instance.new("Tool")
    pickaxe.Name = "Pickaxe"
    pickaxe.CanBeDropped = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 3, 0.3)
    handle.Color = Color3.fromRGB(139, 90, 43)
    handle.Material = Enum.Material.Wood
    handle.Parent = pickaxe
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(0.8, 1, 0.2)
    head.Position = Vector3.new(0, 2, 0)
    head.Color = Color3.fromRGB(160, 160, 170)
    head.Material = Enum.Material.Metal
    head.Parent = pickaxe
    
    pickaxe.GripPos = Vector3.new(0, -1, 0)
    pickaxe.Parent = player.Backpack
end

-- Handle build damage
function CombatSystem:HandleBuildDamage(player, build, damage)
    if not build or not build:IsA("BasePart") then return end
    
    local ownerId = build:GetAttribute("Owner")
    if ownerId == player.UserId then return end -- Can't damage own builds
    
    local health = build:GetAttribute("Health") or 0
    local newHealth = math.max(0, health - (damage or 25))
    build:SetAttribute("Health", newHealth)
    
    -- Update health bar
    self:UpdateBuildHealthBar(build)
    
    if newHealth <= 0 then
        self:DestroyBuild(build, player)
    end
end

-- Update build health bar
function CombatSystem:UpdateBuildHealthBar(build)
    local healthBar = build:FindFirstChild("HealthBar")
    if not healthBar then return end
    
    local health = build:GetAttribute("Health") or 0
    local maxHealth = build:GetAttribute("MaxHealth") or 1
    local percent = health / maxHealth
    
    local fill = healthBar:FindFirstChild("Background") and healthBar.Background:FindFirstChild("Fill")
    if fill then
        fill.Size = UDim2.new(percent, 0, 1, 0)
        
        if percent > 0.5 then
            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        elseif percent > 0.25 then
            fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end

-- Destroy build
function CombatSystem:DestroyBuild(build, destroyer)
    -- Effect
    local explosion = Instance.new("Explosion")
    explosion.Position = build.Position
    explosion.BlastRadius = 4
    explosion.BlastPressure = 0
    explosion.Parent = workspace
    
    -- Debris
    for i = 1, 5 do
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(0.5, 0.5, 0.5)
        debris.Position = build.Position
        debris.Color = build.Color
        debris.Velocity = Vector3.new(
            math.random(-15, 15),
            math.random(10, 20),
            math.random(-15, 15)
        )
        debris.Parent = workspace
        game:GetService("Debris"):AddItem(debris, 1)
    end
    
    build:Destroy()
end

-- Handle player damage
function CombatSystem:HandlePlayerDamage(player, targetPlayer, damage)
    if not targetPlayer then return end
    
    local char = targetPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    hum:TakeDamage(damage or 20)
end

-- Handle death
function CombatSystem:HandleDeath(player)
    print(string.format("💀 %s died", player.Name))
    
    -- Respawn after delay
    task.delay(3, function()
        player:LoadCharacter()
    end)
end

-- Init is called by GameManager
return CombatSystem
