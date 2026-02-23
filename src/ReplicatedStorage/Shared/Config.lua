-- Build a Battles - Configuration
local Config = {}

-- Building Settings
Config.BUILD = {
    MAX_BLOCKS = 200,
    GRID_SIZE = 4,
    BUILD_TIME = 120, -- seconds
    BLOCK_TYPES = {
        WOOD = { health = 100, color = Color3.fromRGB(161, 111, 67) },
        STONE = { health = 300, color = Color3.fromRGB(125, 125, 125) },
        METAL = { health = 500, color = Color3.fromRGB(80, 80, 90) }
    }
}

-- Combat Settings
Config.COMBAT = {
    ROUND_TIME = 180,
    WEAPONS = {
        SWORD = { damage = 25, range = 8 },
        BOW = { damage = 15, range = 50 },
        ROCKET = { damage = 75, range = 100, blastRadius = 10 }
    },
    MAX_HEALTH = 100
}

-- Game Phases
Config.PHASES = {
    LOBBY = "LOBBY",
    BUILDING = "BUILDING",
    COMBAT = "COMBAT",
    END = "END"
}

return Config