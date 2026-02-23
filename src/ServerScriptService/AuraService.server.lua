-- AuraService - Handles aura visual effects
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

-- Setup Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AuraEquipEvent = Instance.new("RemoteEvent")
AuraEquipEvent.Name = "AuraEquipEvent"
AuraEquipEvent.Parent = Remotes

local AuraService = {}
local activeAuras = {} -- player -> aura model

-- Create aura template
function AuraService:CreateAuraTemplate(auraConfig)
    local model = Instance.new("Model")
    model.Name = "Aura_" .. auraConfig.id
    
    -- Create particle emitter
    local attachment = Instance.new("Attachment")
    attachment.Name = "AuraAttachment"
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = workspace.Terrain -- Will be reparented
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "AuraParticles"
    particles.Color = ColorSequence.new(auraConfig.particleColor)
    particles.Size = NumberSequence.new(auraConfig.particleSize)
    particles.Transparency = NumberSequence.new(0.3, 1)
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = auraConfig.particleCount
    particles.Speed = NumberRange.new(2, 5)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Acceleration = Vector3.new(0, 2, 0)
    particles.RotSpeed = NumberRange.new(-90, 90)
    particles.LightEmission = 0.5
    particles.LightInfluence = 0
    particles.LockedToPart = false
    particles.Parent = attachment
    
    -- Store reference
    model:SetAttribute("ParticleAttachment", attachment)
    
    return model
end

-- Equip aura on player
function AuraService:EquipAura(player, auraId)
    -- Remove old aura
    self:UnequipAura(player)
    
    -- Find aura config
    local auraConfig = nil
    for _, aura in ipairs(Config.AURAS) do
        if aura.id == auraConfig.id then
            auraConfig = aura
            break
        end
    end
    
    if not auraConfig then return false end
    
    -- Wait for character
    local char = player.Character
    if not char then return false end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return false end
    
    -- Create aura effect
    local auraModel = self:CreateAuraTemplate(auraConfig)
    auraModel.Parent = char
    
    -- Position attachment on player
    local attachment = auraModel:GetAttribute("ParticleAttachment")
    if attachment then
        attachment.Parent = hrp
        attachment.Position = Vector3.new(0, 0, 0)
    end
    
    -- Store reference
    activeAuras[player.UserId] = auraModel
    
    -- Tell all clients to render this aura
    AuraEquipEvent:FireAllClients(player.UserId, auraId)
    
    return true
end

-- Unequip aura
function AuraService:UnequipAura(player)
    local auraModel = activeAuras[player.UserId]
    if auraModel then
        -- Clean up attachment
        local attachment = auraModel:GetAttribute("ParticleAttachment")
        if attachment then
            attachment:Destroy()
        end
        
        auraModel:Destroy()
        activeAuras[player.UserId] = nil
    end
    
    -- Tell clients to remove
    AuraEquipEvent:FireAllClients(player.UserId, nil)
end

-- Handle character respawn
function AuraService:OnCharacterAdded(player, character)
    -- Re-equip aura if they had one
    task.wait(1) -- Wait for character to load
    
    -- Get their equipped aura from RollService (we'll store it there)
    -- For now, just leave it empty
end

-- Listen for equip events
AuraEquipEvent.OnServerEvent:Connect(function(player, auraId)
    AuraService:EquipAura(player, auraId)
end)

-- Handle character respawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        AuraService:OnCharacterAdded(player, char)
    end)
end)

print("✅ Aura Service Initialized")
return AuraService
