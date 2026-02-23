-- Utility Functions
local Utils = {}

-- Weighted random selection
function Utils.WeightedRandom(items, luckMultiplier)
    luckMultiplier = luckMultiplier or 1
    
    if #items == 0 then return nil end
    
    -- Calculate total weight with luck
    local totalWeight = 0
    local weightedItems = {}
    
    for _, item in ipairs(items) do
        local chance = item.chance or 0.1
        local weight = chance * luckMultiplier
        totalWeight = totalWeight + weight
        table.insert(weightedItems, {
            item = item,
            weight = weight,
            cumulative = totalWeight
        })
    end
    
    -- Roll the dice
    local roll = math.random() * totalWeight
    
    -- Find selected item
    for _, weighted in ipairs(weightedItems) do
        if roll <= weighted.cumulative then
            return weighted.item
        end
    end
    
    return items[#items].item -- Fallback to last
end

-- Simple random selection from weighted table
function Utils.RollAura(auras, luckMultiplier)
    luckMultiplier = luckMultiplier or 1
    
    local roll = math.random()
    local adjustedRoll = roll / luckMultiplier
    
    -- Sort by chance (highest to lowest rarity)
    local sortedAuras = {}
    for _, aura in ipairs(auras) do
        table.insert(sortedAuras, aura)
    end
    
    -- Check from rarest to common
    for i = #sortedAuras, 1, -1 do
        if adjustedRoll <= sortedAuras[i].chance then
            return sortedAuras[i]
        end
    end
    
    -- Return common if nothing else
    for _, aura in ipairs(auras) do
        if aura.rarity == "Common" then
            return aura
        end
    end
    
    return auras[1]
end

-- Format number with commas
function Utils.FormatNumber(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- Format luck multiplier
function Utils.FormatLuck(luck)
    if luck >= 100 then
        return string.format("%.0fx", luck)
    elseif luck >= 10 then
        return string.format("%.1fx", luck)
    else
        return string.format("%.2fx", luck)
    end
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

-- Create unique ID
function Utils.GenerateId()
    return tostring(math.random(100000, 999999)) .. tostring(tick())
end

return Utils
