-- Build a Battles - Procedural Weapon Models
local WeaponModels = {}

-- Color palettes
local COLORS = {
    steel = Color3.fromRGB(140, 140, 150),
    darkSteel = Color3.fromRGB(80, 80, 90),
    gold = Color3.fromRGB(255, 215, 0),
    wood = Color3.fromRGB(139, 90, 43),
    energy = Color3.fromRGB(0, 255, 255),
    plasma = Color3.fromRGB(255, 50, 150),
    void = Color3.fromRGB(75, 0, 130),
}

-- Create a basic part with properties
local function createPart(name, size, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color or COLORS.steel
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = false
    part.CanCollide = false
    return part
end

-- Sword Model Generator
function WeaponModels:CreateSword(variant)
    variant = variant or "default"
    local model = Instance.new("Model")
    model.Name = "Sword"
    
    if variant == "default" then
        -- Blade
        local blade = createPart("Blade", Vector3.new(0.3, 3, 0.1), COLORS.steel, Enum.Material.Metal)
        blade.Position = Vector3.new(0, 1.5, 0)
        blade.Parent = model
        
        -- Crossguard
        local guard = createPart("Guard", Vector3.new(1.2, 0.2, 0.3), COLORS.darkSteel)
        guard.Position = Vector3.new(0, 0, 0)
        guard.Parent = model
        
        -- Handle
        local handle = createPart("Handle", Vector3.new(0.25, 1, 0.25), COLORS.wood)
        handle.Position = Vector3.new(0, -0.6, 0)
        handle.Parent = model
        
        -- Pommel
        local pommel = createPart("Pommel", Vector3.new(0.4, 0.3, 0.4), COLORS.gold, Enum.Material.Metal)
        pommel.Position = Vector3.new(0, -1.2, 0)
        pommel.Parent = model
        
    elseif variant == "cyber" then
        -- Cyber blade
        local blade = createPart("Blade", Vector3.new(0.25, 3.2, 0.08), COLORS.darkSteel)
        blade.Position = Vector3.new(0, 1.6, 0)
        blade.Parent = model
        
        -- Energy edge
        local edge = createPart("Edge", Vector3.new(0.05, 3, 0.12), COLORS.energy, Enum.Material.Neon)
        edge.Position = Vector3.new(0, 1.5, 0)
        edge.Parent = model
        
        -- Tech guard
        local guard = createPart("Guard", Vector3.new(1.3, 0.25, 0.35), COLORS.darkSteel)
        guard.Position = Vector3.new(0, 0, 0)
        guard.Parent = model
        
        -- Tech handle
        local handle = createPart("Handle", Vector3.new(0.3, 1.1, 0.3), COLORS.darkSteel)
        handle.Position = Vector3.new(0, -0.65, 0)
        handle.Parent = model
        
        -- Energy core
        local core = createPart("Core", Vector3.new(0.15, 0.8, 0.15), COLORS.energy, Enum.Material.Neon)
        core.Position = Vector3.new(0, -0.65, 0)
        core.Parent = model
        
    elseif variant == "golden" then
        -- Golden blade
        local blade = createPart("Blade", Vector3.new(0.35, 3, 0.12), COLORS.gold, Enum.Material.Metal)
        blade.Position = Vector3.new(0, 1.5, 0)
        blade.Parent = model
        
        -- Ornate guard
        local guard = createPart("Guard", Vector3.new(1.4, 0.3, 0.4), COLORS.gold, Enum.Material.Metal)
        guard.Position = Vector3.new(0, 0, 0)
        guard.Parent = model
        
        -- Jewel
        local jewel = createPart("Jewel", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 0, 100), Enum.Material.Neon)
        jewel.Position = Vector3.new(0, 0, 0)
        jewel.Shape = Enum.PartType.Ball
        jewel.Parent = model
        
        -- Golden handle
        local handle = createPart("Handle", Vector3.new(0.28, 1, 0.28), COLORS.gold, Enum.Material.Metal)
        handle.Position = Vector3.new(0, -0.6, 0)
        handle.Parent = model
    end
    
    -- Primary part for welding
    model.PrimaryPart = model:FindFirstChild("Handle") or model:FindFirstChild("Blade")
    
    return model
end

-- Bow Model Generator
function WeaponModels:CreateBow(variant)
    variant = variant or "default"
    local model = Instance.new("Model")
    model.Name = "Bow"
    
    if variant == "default" then
        -- Bow limbs (curved using parts)
        for i = 1, 8 do
            local angle = (i - 4.5) * 0.3
            local limb = createPart("Limb" .. i, Vector3.new(0.15, 0.6, 0.15), COLORS.wood)
            limb.CFrame = CFrame.new(math.sin(angle) * 1.5, math.cos(angle) * 2, 0) * 
                          CFrame.Angles(0, 0, -angle)
            limb.Parent = model
        end
        
        -- String
        local string = createPart("String", Vector3.new(0.02, 4, 0.02), Color3.fromRGB(240, 240, 240))
        string.Position = Vector3.new(0, 0, -0.2)
        string.Parent = model
        
        -- Handle
        local handle = createPart("Handle", Vector3.new(0.3, 0.8, 0.25), COLORS.wood)
        handle.Position = Vector3.new(0, 0, 0.1)
        handle.Parent = model
        
    elseif variant == "plasma" then
        -- Plasma bow frame
        for i = 1, 8 do
            local angle = (i - 4.5) * 0.3
            local limb = createPart("Limb" .. i, Vector3.new(0.2, 0.7, 0.2), COLORS.darkSteel)
            limb.CFrame = CFrame.new(math.sin(angle) * 1.5, math.cos(angle) * 2, 0) * 
                          CFrame.Angles(0, 0, -angle)
            limb.Parent = model
        end
        
        -- Plasma string
        local string = createPart("PlasmaString", Vector3.new(0.08, 4, 0.08), COLORS.plasma, Enum.Material.Neon)
        string.Position = Vector3.new(0, 0, -0.2)
        string.Parent = model
        
        -- Energy nodes
        for _, pos in ipairs({Vector3.new(-1.2, 2, 0), Vector3.new(1.2, 2, 0)}) do
            local node = createPart("Node", Vector3.new(0.3, 0.3, 0.3), COLORS.plasma, Enum.Material.Neon)
            node.Shape = Enum.PartType.Ball
            node.Position = pos
            node.Parent = model
        end
        
        -- Tech handle
        local handle = createPart("Handle", Vector3.new(0.35, 0.9, 0.3), COLORS.darkSteel)
        handle.Position = Vector3.new(0, 0, 0.1)
        handle.Parent = model
    end
    
    model.PrimaryPart = model:FindFirstChild("Handle") or model:FindFirstChild("Limb4")
    return model
end

-- Rocket Launcher Model Generator
function WeaponModels:CreateRocketLauncher(variant)
    variant = variant or "default"
    local model = Instance.new("Model")
    model.Name = "RocketLauncher"
    
    if variant == "default" then
        -- Main barrel
        local barrel = createPart("Barrel", Vector3.new(0.5, 0.5, 2.5), COLORS.darkSteel)
        barrel.Position = Vector3.new(0, 0, -1)
        barrel.Parent = model
        
        -- Barrel hole
        local hole = createPart("Hole", Vector3.new(0.3, 0.3, 0.1), Color3.fromRGB(30, 30, 30))
        hole.Position = Vector3.new(0, 0, -2.3)
        hole.Parent = model
        
        -- Body
        local body = createPart("Body", Vector3.new(0.8, 0.8, 1.2), COLORS.steel)
        body.Position = Vector3.new(0, 0, 0.8)
        body.Parent = model
        
        -- Handle
        local handle = createPart("Handle", Vector3.new(0.25, 0.8, 0.25), COLORS.wood)
        handle.Position = Vector3.new(0, -0.7, 1)
        handle.Parent = model
        
        -- Sight
        local sight = createPart("Sight", Vector3.new(0.15, 0.3, 0.4), COLORS.darkSteel)
        sight.Position = Vector3.new(0, 0.6, 0.5)
        sight.Parent = model
        
    elseif variant == "golden" then
        -- Golden barrel
        local barrel = createPart("Barrel", Vector3.new(0.55, 0.55, 2.5), COLORS.gold, Enum.Material.Metal)
        barrel.Position = Vector3.new(0, 0, -1)
        barrel.Parent = model
        
        -- Decorative rings
        for _, z in ipairs({-1.8, -1.2, -0.6}) do
            local ring = createPart("Ring", Vector3.new(0.6, 0.6, 0.15), COLORS.gold, Enum.Material.Metal)
            ring.Position = Vector3.new(0, 0, z)
            ring.Parent = model
        end
        
        -- Golden body
        local body = createPart("Body", Vector3.new(0.85, 0.85, 1.2), COLORS.gold, Enum.Material.Metal)
        body.Position = Vector3.new(0, 0, 0.8)
        body.Parent = model
        
        -- Gem decoration
        local gem = createPart("Gem", Vector3.new(0.4, 0.4, 0.2), COLORS.plasma, Enum.Material.Neon)
        gem.Position = Vector3.new(0, 0, 0.8)
        gem.Parent = model
        
        -- Golden handle
        local handle = createPart("Handle", Vector3.new(0.28, 0.85, 0.28), COLORS.gold, Enum.Material.Metal)
        handle.Position = Vector3.new(0, -0.75, 1)
        handle.Parent = model
    end
    
    model.PrimaryPart = model:FindFirstChild("Body") or model:FindFirstChild("Barrel")
    return model
end

-- Tool creator - combines model with functionality
function WeaponModels:CreateTool(weaponType, variant)
    local tool = Instance.new("Tool")
    tool.Name = weaponType
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    
    local model
    if weaponType == "Sword" then
        model = self:CreateSword(variant)
    elseif weaponType == "Bow" then
        model = self:CreateBow(variant)
    elseif weaponType == "RocketLauncher" then
        model = self:CreateRocketLauncher(variant)
    end
    
    if model then
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = false
                part.Parent = tool
            end
        end
        
        -- Set handle
        local handle = tool:FindFirstChild("Handle")
        if handle then
            tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0)
        end
    end
    
    return tool
end

-- Create visual effect for weapon
function WeaponModels:CreateWeaponEffect(weaponType, variant)
    if variant == "cyber" or variant == "plasma" or variant == "golden" then
        local effect = Instance.new("ParticleEmitter")
        effect.Color = variant == "cyber" and ColorSequence.new(COLORS.energy) or
                      variant == "plasma" and ColorSequence.new(COLORS.plasma) or
                      ColorSequence.new(COLORS.gold)
        effect.Size = NumberSequence.new(0.5, 0)
        effect.Lifetime = NumberRange.new(0.2, 0.5)
        effect.Rate = 20
        effect.Speed = NumberRange.new(1, 3)
        return effect
    end
    return nil
end

return WeaponModels
