-- Utility Functions
local Utils = {}

-- Snap position to grid
function Utils.SnapToGrid(position, gridSize)
    gridSize = gridSize or 4
    return Vector3.new(
        math.floor(position.X / gridSize + 0.5) * gridSize,
        math.floor(position.Y / gridSize + 0.5) * gridSize,
        math.floor(position.Z / gridSize + 0.5) * gridSize
    )
end

-- Get rotation based on normal
function Utils.GetRotationFromNormal(normal)
    if math.abs(normal.X) > 0.5 then
        return CFrame.Angles(0, normal.X > 0 and math.pi/2 or -math.pi/2, 0)
    elseif math.abs(normal.Z) > 0.5 then
        return CFrame.Angles(0, normal.Z > 0 and 0 or math.pi, 0)
    else
        return CFrame.identity
    end
end

-- Format time
function Utils.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- Format number with commas
function Utils.FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- Check if position is in build zone
function Utils.IsInBuildZone(position, center, radius, height)
    local dx = position.X - center.X
    local dz = position.Z - center.Z
    local dy = position.Y - center.Y
    
    local horizontalDist = math.sqrt(dx*dx + dz*dz)
    return horizontalDist <= radius and math.abs(dy) <= height/2
end

-- Deep copy table
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

-- Create tween info
function Utils.TweenInfo(duration, style, direction)
    return TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
end

return Utils
