-- Fortnite-Style Build Battle Config
local Config = {}

-- Materials (like Fortnite)
Config.MATERIALS = {
    WOOD = {
        name = "Wood",
        health = 100,
        maxHealth = 100,
        color = Color3.fromRGB(161, 111, 67),
        material = Enum.Material.Wood,
        icon = "🪵"
    },
    BRICK = {
        name = "Brick", 
        health = 300,
        maxHealth = 300,
        color = Color3.fromRGB(150, 140, 130),
        material = Enum.Material.Rock,
        icon = "🧱"
    },
    METAL = {
        name = "Metal",
        health = 500,
        maxHealth = 500,
        color = Color3.fromRGB(90, 95, 100),
        material = Enum.Material.Metal,
        icon = "⚙️"
    }
}

-- Build Pieces (Fortnite style)
Config.BUILD_PIECES = {
    WALL = {
        name = "Wall",
        size = Vector3.new(4, 4, 0.5),
        offset = Vector3.new(0, 2, 0),
        health = 1.0, -- Multiplier
        icon = "⬜"
    },
    FLOOR = {
        name = "Floor",
        size = Vector3.new(4, 0.5, 4),
        offset = Vector3.new(0, 0.25, 0),
        health = 1.0,
        icon = "🔲"
    },
    STAIR = {
        name = "Stair",
        size = Vector3.new(4, 4, 4),
        offset = Vector3.new(0, 2, 0),
        health = 1.0,
        icon = "📐"
    },
    ROOF = {
        name = "Roof",
        size = Vector3.new(4, 4, 4),
        offset = Vector3.new(0, 2, 0),
        health = 1.0,
        icon = "🏠"
    }
}

-- Build Settings
Config.BUILD = {
    GRID_SIZE = 4,
    MAX_MATERIALS = 999,
    STARTING_MATERIALS = {
        WOOD = 100,
        BRICK = 50,
        METAL = 25
    },
    BUILD_RANGE = 30,
    TURBO_BUILD_DELAY = 0.05
}

-- Build Zone
Config.BUILD_ZONE = {
    ENABLED = true,
    RADIUS = 150,
    HEIGHT = 50,
    WARNING_RADIUS = 180
}

-- Game Phases
Config.PHASES = {
    LOBBY = { duration = 30, name = "LOBBY" },
    BUILD = { duration = 120, name = "BUILD PHASE" },
    COMBAT = { duration = 180, name = "COMBAT PHASE" },
    END = { duration = 10, name = "VICTORY" }
}

-- Combat
Config.COMBAT = {
    PLAYER_HEALTH = 100,
    PLAYER_SHIELD = 0,
    WEAPONS = {
        PICKAXE = { damage = 20, fireRate = 0.8, range = 5 },
        PISTOL = { damage = 25, fireRate = 0.3, range = 100 },
        SHOTGUN = { damage = 80, fireRate = 1.2, range = 30 },
        RIFLE = { damage = 35, fireRate = 0.15, range = 200 }
    }
}

-- UI Colors (Fortnite style)
Config.COLORS = {
    primary = Color3.fromRGB(255, 200, 50),      -- Fortnite yellow
    secondary = Color3.fromRGB(0, 150, 255),     -- Blue
    success = Color3.fromRGB(50, 200, 50),       -- Green
    danger = Color3.fromRGB(255, 50, 50),        -- Red
    wood = Color3.fromRGB(161, 111, 67),
    brick = Color3.fromRGB(150, 140, 130),
    metal = Color3.fromRGB(90, 95, 100),
    dark = Color3.fromRGB(20, 25, 35),
    darker = Color3.fromRGB(15, 20, 25),
    light = Color3.fromRGB(255, 255, 255),
    gray = Color3.fromRGB(120, 120, 120)
}

return Config
