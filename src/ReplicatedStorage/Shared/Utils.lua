-- Build a Battles - Utility Functions
local Utils = {}

-- Round a number to decimal places
function Utils.Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Format time (seconds → MM:SS)
function Utils.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-- Check if player is alive
function Utils.IsPlayerAlive(player)
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Get distance between two positions
function Utils.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Random point in circle
function Utils.RandomPointInCircle(center, radius)
    local angle = math.random() * 2 * math.pi
    local dist = math.random() * radius
    return center + Vector3.new(
        math.cos(angle) * dist,
        0,
        math.sin(angle) * dist
    )
end

-- Deep copy a table
function Utils.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Create a debounced function
function Utils.Debounce(func, delay)
    local running = false
    return function(...)
        if running then return end
        running = true
        task.delay(delay, function()
            running = false
        end)
        return func(...)
    end
end

-- Particles effect for block destruction
function Utils.CreateDestructionParticles(position, color)
    local particle = Instance.new("ParticleEmitter")
    particle.Color = ColorSequence.new(color)
    particle.Size = NumberSequence.new(1, 0)
    particle.Lifetime = NumberRange.new(0.5, 1)
    particle.Rate = 0
    particle.BurstCount = 10
    particle.Speed = NumberRange.new(5, 10)
    particle.SpreadAngle = Vector2.new(180, 180)
    particle.Acceleration = Vector3.new(0, -20, 0)
    
    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = position
    attachment.Parent = workspace.Terrain
    particle.Parent = attachment
    
    particle:Emit(10)
    
    task.delay(2, function()
        attachment:Destroy()
    end)
end

return Utils