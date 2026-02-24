-- AuraRenderer - Client-side per-rarity aura VFX system
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)

local AuraRenderer = {}
-- playerId -> { attachment, particles[], light, bobConnection }
local activeAuras = {}

-- ─────────────────────────────────────────────
-- Per-rarity VFX recipes
-- ─────────────────────────────────────────────
local VFX_RECIPES = {
    Common = function(cfg, att)
        -- Soft floating mist
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   cfg.particleColor),
            ColorSequenceKeypoint.new(1,   Color3.new(1,1,1)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   cfg.particleSize * 0.5),
            NumberSequenceKeypoint.new(0.5, cfg.particleSize),
            NumberSequenceKeypoint.new(1,   0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        })
        p.Lifetime     = NumberRange.new(0.8, 1.5)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(1, 3)
        p.SpreadAngle  = Vector2.new(60, 60)
        p.Acceleration = Vector3.new(0, 1.5, 0)
        p.LightEmission = 0.2
        p.LightInfluence = 0.8
        p.Parent = att
        return {p}
    end,

    Uncommon = function(cfg, att)
        -- Swirling upward leaves/bubbles
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new(cfg.particleColor)
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, cfg.particleSize * 0.3),
            NumberSequenceKeypoint.new(0.5, cfg.particleSize),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.9),
        })
        p.Lifetime     = NumberRange.new(1.5, 2.5)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(3, 6)
        p.SpreadAngle  = Vector2.new(40, 40)
        p.Acceleration = Vector3.new(0, 4, 0)
        p.RotSpeed     = NumberRange.new(-45, 45)
        p.LightEmission = 0.4
        p.Parent = att
        return {p}
    end,

    Rare = function(cfg, att)
        -- Fire/ice beam swirling around body
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   cfg.particleColor),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.9, 0.5)),
            ColorSequenceKeypoint.new(1,   Color3.new(1, 1, 1)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0),
            NumberSequenceKeypoint.new(0.2, cfg.particleSize),
            NumberSequenceKeypoint.new(1,   0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        p.Lifetime     = NumberRange.new(0.5, 1.2)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(4, 8)
        p.SpreadAngle  = Vector2.new(180, 180)
        p.Acceleration = Vector3.new(0, 3, 0)
        p.RotSpeed     = NumberRange.new(-180, 180)
        p.LightEmission = 0.7
        p.LightInfluence = 0
        p.Parent = att

        -- Second crackle layer
        local p2 = Instance.new("ParticleEmitter")
        p2.Color        = ColorSequence.new(Color3.new(1, 1, 1))
        p2.Size         = NumberSequence.new(cfg.particleSize * 0.2)
        p2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(0.3, 0.6)
        p2.Rate        = cfg.particleCount * 0.4
        p2.Speed       = NumberRange.new(2, 5)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.LightEmission = 1
        p2.Parent = att
        return {p, p2}
    end,

    Epic = function(cfg, att)
        -- Dark void tendrils pulsing inward
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   cfg.particleColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 0, 150)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(30, 0, 50)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, cfg.particleSize * 1.2),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.8),
        })
        p.Lifetime     = NumberRange.new(1, 2)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(2, 5)
        p.SpreadAngle  = Vector2.new(180, 180)
        p.Acceleration = Vector3.new(0, -1, 0) -- tendrils fall downward
        p.RotSpeed     = NumberRange.new(-90, 90)
        p.LightEmission = 0.8
        p.LightInfluence = 0
        p.Parent = att

        -- Inner pulse
        local p2 = Instance.new("ParticleEmitter")
        p2.Color       = ColorSequence.new(Color3.fromRGB(200, 50, 255))
        p2.Size        = NumberSequence.new(cfg.particleSize * 0.3)
        p2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(0.4, 0.8)
        p2.Rate        = cfg.particleCount * 0.6
        p2.Speed       = NumberRange.new(1, 3)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.LightEmission = 1
        p2.Parent = att
        return {p, p2}
    end,

    Legendary = function(cfg, att)
        -- Orbiting stars + golden trail
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 230, 100)),
            ColorSequenceKeypoint.new(0.5, cfg.particleColor),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.2, cfg.particleSize),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        p.Lifetime     = NumberRange.new(1.5, 3)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(5, 10)
        p.SpreadAngle  = Vector2.new(180, 180)
        p.RotSpeed     = NumberRange.new(-360, 360)
        p.LightEmission = 1
        p.LightInfluence = 0
        p.Parent = att

        -- Trailing sparkle
        local p2 = Instance.new("ParticleEmitter")
        p2.Color       = ColorSequence.new(Color3.fromRGB(255, 255, 100))
        p2.Size        = NumberSequence.new(cfg.particleSize * 0.3)
        p2.Transparency= NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(0.5, 1)
        p2.Rate        = cfg.particleCount * 0.8
        p2.Speed       = NumberRange.new(1, 3)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.Acceleration= Vector3.new(0, 3, 0)
        p2.LightEmission = 1
        p2.Parent = att
        return {p, p2}
    end,

    Mythic = function(cfg, att)
        -- Heavenly beam + halo ring
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 200, 100)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1,   cfg.particleColor),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.1, cfg.particleSize),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        p.Lifetime     = NumberRange.new(2, 4)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(3, 7)
        p.SpreadAngle  = Vector2.new(20, 20) -- mostly upward pillar
        p.Acceleration = Vector3.new(0, 5, 0)
        p.LightEmission = 1
        p.LightInfluence = 0
        p.Parent = att

        -- Wide sweep layer
        local p2 = Instance.new("ParticleEmitter")
        p2.Color       = ColorSequence.new(Color3.fromRGB(255, 220, 120))
        p2.Size        = NumberSequence.new({
            NumberSequenceKeypoint.new(0, cfg.particleSize * 0.5),
            NumberSequenceKeypoint.new(1, 0),
        })
        p2.Transparency= NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(1, 2)
        p2.Rate        = cfg.particleCount * 0.7
        p2.Speed       = NumberRange.new(6, 12)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.LightEmission = 1
        p2.Parent = att
        return {p, p2}
    end,

    Godlike = function(cfg, att)
        -- Full body red power explosion
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 0)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 200, 50)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.15, cfg.particleSize * 1.5),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.8),
        })
        p.Lifetime     = NumberRange.new(1, 2.5)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(8, 15)
        p.SpreadAngle  = Vector2.new(180, 180)
        p.RotSpeed     = NumberRange.new(-180, 180)
        p.Acceleration = Vector3.new(0, 2, 0)
        p.LightEmission = 1
        p.LightInfluence = 0
        p.Parent = att

        -- Dark corona
        local p2 = Instance.new("ParticleEmitter")
        p2.Color       = ColorSequence.new(Color3.fromRGB(80, 0, 0))
        p2.Size        = NumberSequence.new({
            NumberSequenceKeypoint.new(0, cfg.particleSize * 2),
            NumberSequenceKeypoint.new(1, 0),
        })
        p2.Transparency= NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(0.5, 1)
        p2.Rate        = cfg.particleCount * 0.5
        p2.Speed       = NumberRange.new(2, 6)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.LightEmission = 0.5
        p2.Parent = att
        return {p, p2}
    end,

    Secret = function(cfg, att)
        -- Rainbow aurora shimmering
        local p = Instance.new("ParticleEmitter")
        p.Color        = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   255)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 128, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,   255, 0)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,   128, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(128, 0,   255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 255, 255)),
        })
        p.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.1, cfg.particleSize * 2),
            NumberSequenceKeypoint.new(1, 0),
        })
        p.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        p.Lifetime     = NumberRange.new(2, 5)
        p.Rate         = cfg.particleCount
        p.Speed        = NumberRange.new(5, 12)
        p.SpreadAngle  = Vector2.new(180, 180)
        p.RotSpeed     = NumberRange.new(-360, 360)
        p.Acceleration = Vector3.new(0, 4, 0)
        p.LightEmission = 1
        p.LightInfluence = 0
        p.Parent = att

        -- Infinity sparkle
        local p2 = Instance.new("ParticleEmitter")
        p2.Color       = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        p2.Size        = NumberSequence.new(cfg.particleSize * 0.3)
        p2.Transparency= NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        p2.Lifetime    = NumberRange.new(0.3, 0.8)
        p2.Rate        = cfg.particleCount
        p2.Speed       = NumberRange.new(3, 8)
        p2.SpreadAngle = Vector2.new(180, 180)
        p2.LightEmission = 1
        p2.Parent = att
        return {p, p2}
    end,
}

-- ─────────────────────────────────────────────
-- PointLight brightness per rarity
-- ─────────────────────────────────────────────
local LIGHT_CONFIG = {
    Common    = nil,
    Uncommon  = nil,
    Rare      = { brightness = 1,   range = 12,  color = Color3.fromRGB(255, 160, 80)  },
    Epic      = { brightness = 2,   range = 16,  color = Color3.fromRGB(150, 50, 255)  },
    Legendary = { brightness = 4,   range = 20,  color = Color3.fromRGB(255, 220, 60)  },
    Mythic    = { brightness = 6,   range = 24,  color = Color3.fromRGB(255, 240, 160) },
    Godlike   = { brightness = 8,   range = 28,  color = Color3.fromRGB(255, 60,  60)  },
    Secret    = { brightness = 10,  range = 32,  color = Color3.fromRGB(255, 255, 255) },
}

-- ─────────────────────────────────────────────
-- Create aura effect for a given aura config
-- ─────────────────────────────────────────────
function AuraRenderer:CreateAuraEffect(auraId)
    local auraConfig = nil
    for _, aura in ipairs(Config.AURAS) do
        if aura.id == auraId then
            auraConfig = aura
            break
        end
    end

    if not auraConfig then return nil end

    -- Main attachment (positioned at feet)
    local att = Instance.new("Attachment")
    att.Name = "AuraAttachment_" .. auraId
    att.Position = Vector3.new(0, 0, 0)

    -- Build per-rarity particles
    local recipe = VFX_RECIPES[auraConfig.rarity] or VFX_RECIPES.Common
    local particles = recipe(auraConfig, att)

    -- PointLight for glow tiers
    local light = nil
    local lightCfg = LIGHT_CONFIG[auraConfig.rarity]
    if lightCfg then
        light = Instance.new("PointLight")
        light.Brightness = lightCfg.brightness
        light.Range      = lightCfg.range
        light.Color      = lightCfg.color
        light.Shadows    = true
        light.Parent     = att
    end

    return {
        attachment = att,
        particles  = particles,
        light      = light,
        auraConfig = auraConfig,
    }
end

-- ─────────────────────────────────────────────
-- Fade out all particles then destroy
-- ─────────────────────────────────────────────
local function FadeOutEffect(effect, onDone)
    if not effect or not effect.attachment then
        if onDone then onDone() end
        return
    end

    -- Stop emitting
    for _, p in ipairs(effect.particles or {}) do
        if p and p.Parent then
            p.Enabled = false
        end
    end

    -- Fade light
    if effect.light and effect.light.Parent then
        TweenService:Create(effect.light, TweenInfo.new(0.5), {Brightness = 0}):Play()
    end

    -- Destroy after particles die out
    task.delay(2, function()
        if effect.attachment and effect.attachment.Parent then
            effect.attachment:Destroy()
        end
        if onDone then onDone() end
    end)
end

-- ─────────────────────────────────────────────
-- Attach aura to a player
-- ─────────────────────────────────────────────
function AuraRenderer:AttachAuraToPlayer(targetPlayer, auraId)
    local existingEffect = activeAuras[targetPlayer.UserId]

    -- Fade out old effect, then attach new one
    if existingEffect and not existingEffect.pending then
        FadeOutEffect(existingEffect)
    end
    activeAuras[targetPlayer.UserId] = nil

    if not auraId then return end -- unequip only

    local char = targetPlayer.Character
    if not char then
        activeAuras[targetPlayer.UserId] = { pending = true, auraId = auraId }
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        activeAuras[targetPlayer.UserId] = { pending = true, auraId = auraId }
        return
    end

    local effect = self:CreateAuraEffect(auraId)
    if not effect then return end

    effect.attachment.Parent = hrp

    -- Burst-in: quickly emit a burst of particles for dramatic entry
    for _, p in ipairs(effect.particles) do
        if p then p:Emit(30) end
    end

    -- Fade in light
    if effect.light then
        local maxBright = effect.light.Brightness
        effect.light.Brightness = 0
        TweenService:Create(effect.light, TweenInfo.new(0.5), { Brightness = maxBright }):Play()
    end

    activeAuras[targetPlayer.UserId] = effect

    print(string.format("✨ Applied [%s] aura (%s) to %s",
        effect.auraConfig.name, effect.auraConfig.rarity, targetPlayer.Name))
end

-- ─────────────────────────────────────────────
-- Remove aura from player
-- ─────────────────────────────────────────────
function AuraRenderer:RemovePlayerAura(targetPlayer)
    local effect = activeAuras[targetPlayer.UserId]
    if effect then
        FadeOutEffect(effect)
        activeAuras[targetPlayer.UserId] = nil
    end
end

-- ─────────────────────────────────────────────
-- Re-attach pending aura after character respawn
-- ─────────────────────────────────────────────
function AuraRenderer:OnCharacterAdded(targetPlayer, character)
    task.wait(1) -- wait for HRP to exist

    local stored = activeAuras[targetPlayer.UserId]
    if stored and stored.pending then
        self:AttachAuraToPlayer(targetPlayer, stored.auraId)
    end
end

-- ─────────────────────────────────────────────
-- Initialize
-- ─────────────────────────────────────────────
function AuraRenderer:Init()
    local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
    local AuraEquipEvent = Remotes:WaitForChild("AuraEquipEvent")

    -- Server broadcasts aura equip to all clients
    AuraEquipEvent.OnClientEvent:Connect(function(playerId, auraId)
        local targetPlayer = Players:GetPlayerByUserId(playerId)
        if not targetPlayer then return end
        self:AttachAuraToPlayer(targetPlayer, auraId)
    end)

    -- Handle character respawns for all current players
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
