-- AuraRenderer - Handles aura visual effects on players
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)

local AuraRenderer = {}
local activeAuras = {} -- playerId -> {attachment, particles}

-- Create aura effect
function AuraRenderer:CreateAuraEffect(auraId)
    -- Find aura config
    local auraConfig = nil
    for _, aura in ipairs(Config.AURAS) do
        if aura.id == auraId then
            auraConfig = aura
            break
        end
    end
    
    if not auraConfig then return nil end
    
    -- Create attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = "AuraAttachment_" .. auraId
    
    -- Create particle emitter
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "AuraParticles"
    particles.Color = ColorSequence.new(auraConfig.particleColor)
    particles.Size = NumberSequence.new(auraConfig.particleSize)
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
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
    
    -- Add glow for rare auras
    if auraConfig.rarity == "Legendary" or auraConfig.rarity == "Mythic" or 
       auraConfig.rarity == "Godlike" or auraConfig.rarity == "Secret" then
        
        -- Secondary particles for glow
        local glowParticles = Instance.new("ParticleEmitter")
        glowParticles.Name = "GlowParticles"
        glowParticles.Color = ColorSequence.new(auraConfig.particleColor)
        glowParticles.Size = NumberSequence.new(auraConfig.particleSize * 0.5)
        glowParticles.Transparency = NumberSequence.new(0.1, 0.8)
        glowParticles.Lifetime = NumberRange.new(0.5, 1)
        glowParticles.Rate = auraConfig.particleCount * 0.5
        glowParticles.Speed = NumberRange.new(0.5, 2)
        glowParticles.Parent = attachment
    end
    
    return {
        attachment = attachment,
        particles = particles,
        auraConfig = auraConfig
    }
end

-- Attach aura to player
function AuraRenderer:AttachAuraToPlayer(targetPlayer, auraId)
    -- Remove existing aura
    self:RemovePlayerAura(targetPlayer)
    
    -- Create new aura
    local effect = self:CreateAuraEffect(auraId)
    if not effect then return end
    
    -- Wait for character
    local char = targetPlayer.Character
    if not char then
        -- Store for later
        activeAuras[targetPlayer.UserId] = {pending = true, auraId = auraId}
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        activeAuras[targetPlayer.UserId] = {pending = true, auraId = auraId}
        return
    end
    
    -- Attach to character
    effect.attachment.Parent = hrp
    effect.attachment.Position = Vector3.new(0, 0, 0)
    
    -- Store reference
    activeAuras[targetPlayer.UserId] = effect
    
    print(string.format("✨ Attached %s to %s", auraId, targetPlayer.Name))
end

-- Remove aura from player
function AuraRenderer:RemovePlayerAura(targetPlayer)
    local effect = activeAuras[targetPlayer.UserId]
    if effect and effect.attachment then
        effect.attachment:Destroy()
    end
    activeAuras[targetPlayer.UserId] = nil
end

-- Handle character added (reattach pending auras)
function AuraRenderer:OnCharacterAdded(targetPlayer, character)
    task.wait(1) -- Wait for character to fully load
    
    local stored = activeAuras[targetPlayer.UserId]
    if stored and stored.pending then
        self:AttachAuraToPlayer(targetPlayer, stored.auraId)
    end
end

-- Initialize
function AuraRenderer:Init()
    -- Listen for server events
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local AuraEquipEvent = Remotes:WaitForChild("AuraEquipEvent")
    
    AuraEquipEvent.OnClientEvent:Connect(function(playerId, auraId)
        local targetPlayer = Players:GetPlayerByUserId(playerId)
        if not targetPlayer then return end
        
        if auraId then
            self:AttachAuraToPlayer(targetPlayer, auraId)
        else
            self:RemovePlayerAura(targetPlayer)
        end
    end)
    
    -- Listen for character changes on all players
    for _, p in ipairs(Players:GetPlayers()) do
        p.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(p, char)
        end)
    end
    
    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(char)
            self:OnCharacterAdded(p, char)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        self:RemovePlayerAura(p)
    end)
    
    print("✅ Aura Renderer Initialized")
end

AuraRenderer:Init()
return AuraRenderer
