-- Build a Battles - Combat System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for Config to exist (with timeout)
local Config
local success = pcall(function()
    Config = require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Config", 5))
end)

if not success or not Config then
    warn("CombatSystem: Could not load Config, using defaults")
    Config = {
        COMBAT = {
            ROUND_TIME = 180,
            WEAPONS = { SWORD = { damage = 25 }, BOW = { damage = 15 }, ROCKET = { damage = 75 } },
            MAX_HEALTH = 100
        }
    }
end

-- Create Remotes folder if missing
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local CombatSystem = {}
local playerHealth = {}
local combatStarted = false

function CombatSystem:Init()
    -- Remote Events
    self.CombatEvent = Instance.new("RemoteEvent")
    self.CombatEvent.Name = "CombatEvent"
    self.CombatEvent.Parent = Remotes
    
    self:SetupListeners()
    print("✅ Combat System Initialized")
end

function CombatSystem:SetupListeners()
    -- Handle weapon attacks
    self.CombatEvent.OnServerEvent:Connect(function(player, action, target, weaponType)
        if action == "ATTACK" then
            self:HandleAttack(player, target, weaponType)
        elseif action == "DAMAGE_BLOCK" then
            self:DamageBlock(player, target, weaponType)
        end
    end)
    
    -- Setup player health on join
    Players.PlayerAdded:Connect(function(player)
        playerHealth[player.UserId] = (Config.COMBAT and Config.COMBAT.MAX_HEALTH) or 100
        
        player.CharacterAdded:Connect(function(char)
            playerHealth[player.UserId] = (Config.COMBAT and Config.COMBAT.MAX_HEALTH) or 100
            self:SetupCharacter(char, player)
        end)
    end)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        playerHealth[player.UserId] = (Config.COMBAT and Config.COMBAT.MAX_HEALTH) or 100
        if player.Character then
            self:SetupCharacter(player.Character, player)
        end
    end
end

function CombatSystem:SetupCharacter(character, player)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    humanoid.Health = playerHealth[player.UserId] or 100
    
    humanoid.HealthChanged:Connect(function(newHealth)
        playerHealth[player.UserId] = newHealth
        if newHealth <= 0 then
            self:HandleDeath(player)
        end
    end)
end

function CombatSystem:HandleAttack(attacker, target, weaponType)
    if not combatStarted then return end
    
    local weapons = Config.COMBAT and Config.COMBAT.WEAPONS or {}
    local weapon = weapons[weaponType]
    if not weapon then return end
    
    -- Validate target
    if target and target:IsA("Player") then
        local char = target.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:TakeDamage(weapon.damage or 25)
                self:CreateDamageIndicator(target, weapon.damage or 25)
            end
        end
    end
end

function CombatSystem:DamageBlock(player, block, weaponType)
    if not combatStarted then return end
    if not block then return end
    if block:GetAttribute("Owner") == player.UserId then return end
    
    local weapons = Config.COMBAT and Config.COMBAT.WEAPONS or {}
    local weapon = weapons[weaponType]
    if not weapon then return end
    
    local currentHealth = block:GetAttribute("Health") or 100
    local maxHealth = block:GetAttribute("MaxHealth") or 100
    local newHealth = currentHealth - (weapon.damage or 25)
    
    block:SetAttribute("Health", newHealth)
    
    -- Update health bar
    local healthBar = block:FindFirstChild("HealthBar")
    if healthBar then
        local bar = healthBar:FindFirstChild("Bar")
        if bar and bar:IsA("GuiObject") then
            local percent = math.max(0, newHealth / maxHealth)
            bar.Size = UDim2.new(percent, 0, 1, 0)
            
            if percent > 0.5 then
                bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif percent > 0.25 then
                bar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
    
    if newHealth <= 0 then
        self:DestroyBlock(block)
    end
end

function CombatSystem:DestroyBlock(block)
    local explosion = Instance.new("Explosion")
    explosion.Position = block.Position
    explosion.BlastRadius = 2
    explosion.BlastPressure = 0
    explosion.Parent = workspace
    
    for i = 1, 5 do
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(1, 1, 1)
        debris.Position = block.Position
        debris.Color = block.Color
        debris.Material = block.Material
        debris.Velocity = Vector3.new(
            math.random(-20, 20),
            math.random(10, 30),
            math.random(-20, 20)
        )
        debris.Parent = workspace
        
        game:GetService("Debris"):AddItem(debris, 2)
    end
    
    block:Destroy()
end

function CombatSystem:CreateDamageIndicator(target, damage)
    local char = target.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(damage)
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    billboard.Parent = head
    
    task.spawn(function()
        for i = 1, 20 do
            billboard.StudsOffset = billboard.StudsOffset + Vector3.new(0, 0.1, 0)
            label.TextTransparency = i / 20
            task.wait(0.05)
        end
        billboard:Destroy()
    end)
end

function CombatSystem:HandleDeath(player)
    task.delay(3, function()
        if player then
            player:LoadCharacter()
        end
    end)
end

function CombatSystem:SetCombatState(active)
    combatStarted = active
end

function CombatSystem:GetPlayerHealth(player)
    return playerHealth[player.UserId] or 100
end

-- Initialize with delay to let Rojo finish
task.delay(3, function()
    CombatSystem:Init()
end)

return CombatSystem