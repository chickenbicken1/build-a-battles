-- Aura RNG Roller Config
local Config = {}

-- Rarity Tiers
Config.RARITIES = {
    Common = {
        name = "Common",
        color = Color3.fromRGB(169, 169, 169),
        chance = 0.5, -- 50%
        luckMult = 1
    },
    Uncommon = {
        name = "Uncommon", 
        color = Color3.fromRGB(50, 200, 50),
        chance = 0.2, -- 20%
        luckMult = 2
    },
    Rare = {
        name = "Rare",
        color = Color3.fromRGB(50, 100, 255),
        chance = 0.15, -- 15%
        luckMult = 5
    },
    Epic = {
        name = "Epic",
        color = Color3.fromRGB(150, 50, 200),
        chance = 0.1, -- 10%
        luckMult = 10
    },
    Legendary = {
        name = "Legendary",
        color = Color3.fromRGB(255, 200, 50),
        chance = 0.04, -- 4%
        luckMult = 25
    },
    Mythic = {
        name = "Mythic",
        color = Color3.fromRGB(255, 50, 150),
        chance = 0.009, -- 0.9%
        luckMult = 50
    },
    Godlike = {
        name = "Godlike",
        color = Color3.fromRGB(255, 50, 50),
        chance = 0.0009, -- 0.09%
        luckMult = 100
    },
    Secret = {
        name = "Secret",
        color = Color3.fromRGB(255, 0, 255),
        chance = 0.0001, -- 0.01%
        luckMult = 500
    }
}

-- All Auras
Config.AURAS = {
    -- Common (50% total)
    {
        id = "glowing",
        name = "Glowing",
        rarity = "Common",
        power = 10,
        description = "A soft white glow surrounds you",
        particleColor = Color3.fromRGB(255, 255, 255),
        particleSize = 1,
        particleCount = 10
    },
    {
        id = "sparkle",
        name = "Sparkle",
        rarity = "Common",
        power = 15,
        description = "Tiny sparkles float around you",
        particleColor = Color3.fromRGB(200, 200, 200),
        particleSize = 0.5,
        particleCount = 15
    },
    {
        id = "smoke",
        name = "Smoke",
        rarity = "Common",
        power = 20,
        description = "Mysterious gray smoke",
        particleColor = Color3.fromRGB(100, 100, 100),
        particleSize = 2,
        particleCount = 8
    },
    
    -- Uncommon (20% total)
    {
        id = "nature",
        name = "Nature",
        rarity = "Uncommon",
        power = 50,
        description = "Green leaves swirl around you",
        particleColor = Color3.fromRGB(50, 200, 50),
        particleSize = 1.5,
        particleCount = 12
    },
    {
        id = "bubbles",
        name = "Bubbles",
        rarity = "Uncommon",
        power = 75,
        description = "Blue bubbles float upward",
        particleColor = Color3.fromRGB(100, 150, 255),
        particleSize = 1,
        particleCount = 20
    },
    
    -- Rare (15% total)
    {
        id = "fire",
        name = "Inferno",
        rarity = "Rare",
        power = 200,
        description = "Flames dance around your body",
        particleColor = Color3.fromRGB(255, 100, 50),
        particleSize = 2,
        particleCount = 25
    },
    {
        id = "ice",
        name = "Frost",
        rarity = "Rare",
        power = 250,
        description = "Ice crystals form around you",
        particleColor = Color3.fromRGB(150, 200, 255),
        particleSize = 1.5,
        particleCount = 20
    },
    {
        id = "electric",
        name = "Thunder",
        rarity = "Rare",
        power = 300,
        description = "Lightning crackles around you",
        particleColor = Color3.fromRGB(255, 255, 100),
        particleSize = 1,
        particleCount = 15
    },
    
    -- Epic (10% total)
    {
        id = "void",
        name = "Void Walker",
        rarity = "Epic",
        power = 750,
        description = "Dark energy pulses around you",
        particleColor = Color3.fromRGB(50, 0, 100),
        particleSize = 2.5,
        particleCount = 30
    },
    {
        id = "cosmic",
        name = "Cosmic",
        rarity = "Epic",
        power = 1000,
        description = "Stars orbit your body",
        particleColor = Color3.fromRGB(200, 100, 255),
        particleSize = 1.5,
        particleCount = 20
    },
    
    -- Legendary (4% total)
    {
        id = "galaxy",
        name = "Galaxy",
        rarity = "Legendary",
        power = 5000,
        description = "A swirling galaxy surrounds you",
        particleColor = Color3.fromRGB(150, 50, 200),
        particleSize = 3,
        particleCount = 40
    },
    {
        id = "dragon",
        name = "Dragon Soul",
        rarity = "Legendary",
        power = 7500,
        description = "Dragon spirits circle around you",
        particleColor = Color3.fromRGB(255, 100, 0),
        particleSize = 2.5,
        particleCount = 35
    },
    
    -- Mythic (0.9% total)
    {
        id = "celestial",
        name = "Celestial",
        rarity = "Mythic",
        power = 25000,
        description = "Heavenly light beams from above",
        particleColor = Color3.fromRGB(255, 200, 100),
        particleSize = 4,
        particleCount = 50
    },
    
    -- Godlike (0.09% total)
    {
        id = "overlord",
        name = "Overlord",
        rarity = "Godlike",
        power = 100000,
        description = "Dark crown and red aura of power",
        particleColor = Color3.fromRGB(255, 0, 0),
        particleSize = 5,
        particleCount = 60
    },
    
    -- Secret (0.01% total)
    {
        id = "infinity",
        name = "Infinity",
        rarity = "Secret",
        power = 1000000,
        description = "The power of the universe itself",
        particleColor = Color3.fromRGB(255, 255, 255),
        particleSize = 6,
        particleCount = 100
    }
}


-- Brainrot Pets (Luck Boosters)
Config.PETS = {
    {
        id = "skibidi",
        name = "Skibidi Toilet",
        rarity = "Common",
        luckBoost = 1.5,
        description = "Yes, yes, give me the luck!",
        color = Color3.fromRGB(200, 200, 200)
    },
    {
        id = "sigma",
        name = "Sigma Grindset",
        rarity = "Uncommon",
        luckBoost = 2,
        description = "Grinding for that luck",
        color = Color3.fromRGB(100, 100, 100)
    },
    {
        id = "ohio",
        name = "Ohio Final Boss",
        rarity = "Rare",
        luckBoost = 3,
        description = "Only in Ohio...",
        color = Color3.fromRGB(200, 50, 50)
    },
    {
        id = "grimace",
        name = "Grimace Shake",
        rarity = "Epic",
        luckBoost = 5,
        description = "Happy Birthday Grimace!",
        color = Color3.fromRGB(150, 50, 150)
    },
    {
        id = "fanum",
        name = "Fanum Tax Collector",
        rarity = "Legendary",
        luckBoost = 8,
        description = "Gimme that luck!",
        color = Color3.fromRGB(255, 200, 100)
    },
    {
        id = "quandale",
        name = "Quandale Dingle",
        rarity = "Mythic",
        luckBoost = 12,
        description = "What's up guys!",
        color = Color3.fromRGB(50, 100, 200)
    },
    {
        id = "gronk",
        name = "Baby Gronk",
        rarity = "Godlike",
        luckBoost = 20,
        description = "Rizzing up that luck",
        color = Color3.fromRGB(255, 150, 200)
    },
    {
        id = "rizzler",
        name = "Rizler Prime",
        rarity = "Secret",
        luckBoost = 50,
        description = "Maximum rizz achieved",
        color = Color3.fromRGB(255, 215, 0)
    }
}

-- UI Colors
Config.COLORS = {
    primary = Color3.fromRGB(255, 200, 50),
    success = Color3.fromRGB(50, 200, 50),
    danger = Color3.fromRGB(255, 50, 50),
    dark = Color3.fromRGB(20, 25, 35),
    darker = Color3.fromRGB(15, 20, 25),
    light = Color3.fromRGB(255, 255, 255),
    gray = Color3.fromRGB(100, 100, 100)
}

-- Roll Settings
Config.ROLL = {
    cooldown = 0.5,
    animationDuration = 1.5
}

return Config
