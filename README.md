# 🏰 Build a Battles

**Build. Battle. Destroy.**

A Roblox game where players build fortresses during the Build Phase, then battle to destroy enemy bases during the Combat Phase.

## 🎮 Game Loop

1. **Lobby Phase** (30s) - Players join and wait
2. **Build Phase** (2 min) - Build your fortress with blocks
3. **Combat Phase** (3 min) - Fight and destroy enemy structures
4. **End Phase** - Winner announced, map resets

## 🛠️ Setup Instructions

### Prerequisites
- [Roblox Studio](https://create.roblox.com/)
- [Rojo](https://rojo.space/) (`npm install -g rojo`)
- Git

### Step 1: Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/build-a-battles.git
cd build-a-battles
```

### Step 2: Initialize Rojo
```bash
# In the project folder
rojo init
```

### Step 3: Connect to Roblox Studio

**Option A: Rojo Plugin (Recommended)**
1. Install [Rojo Plugin](https://create.roblox.com/store/asset/6410907122/Rojo) in Roblox Studio
2. Open Roblox Studio → Create new place
3. Click Rojo plugin button → "Connect"
4. In terminal, run:
```bash
rojo serve
```
5. Click "Connect" in Studio plugin

**Option B: Command Line Build**
```bash
# Build to .rbxmx file
rojo build -o BuildABattles.rbxmx

# Then import into Studio via Toolbox
```

### Step 4: Start Developing

Once connected:
- Edit files in `src/` folder
- Changes sync live to Roblox Studio
- Test in Play mode

## 📁 Project Structure

```
build-a-battles/
├── src/
│   ├── ServerScriptService/      # Server-side logic
│   │   ├── GameManager.server.lua    # Game loop & phases
│   │   ├── BuildingSystem.server.lua # Block placement/management
│   │   └── CombatSystem.server.lua   # Combat & damage
│   ├── StarterPlayer/
│   │   └── StarterCharacterScripts/
│   │       └── BuildTool.client.lua  # Client building tool
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Config.lua           # Game settings
│   │   │   └── Utils.lua            # Helper functions
│   │   └── Remotes/                  # RemoteEvents
│   └── Workspace/
│       └── SpawnLocations.model.json # Team spawn points
├── default.project.json           # Rojo configuration
└── README.md
```

## 🎯 Core Features

### Building System
- **3 Block Types**: Wood (100 HP), Stone (300 HP), Metal (500 HP)
- **Grid Snapping**: Perfect alignment
- **Block Limit**: 200 blocks per player
- **Health Bars**: Visual damage feedback

### Combat System
- **3 Weapons**: Sword, Bow, Rocket Launcher
- **Block Destruction**: Attack enemy structures
- **Damage Indicators**: Floating damage numbers
- **Respawn System**: 3-second respawn delay

### Game Phases
- Automated phase transitions
- Countdown timers
- Broadcast messages
- Automatic cleanup between rounds

## 🚀 Deployment

### GitHub → Roblox Workflow

1. **Push to GitHub:**
```bash
git add .
git commit -m "Add feature X"
git push origin main
```

2. **Sync to Roblox:**
```bash
rojo build -o BuildABattles.rbxmx
```

3. **Publish:**
- Open in Studio
- File → Publish to Roblox
- Update place

### Automated Deployment (Optional)

Use GitHub Actions for auto-deployment:

```yaml
# .github/workflows/deploy.yml
name: Deploy to Roblox
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Rojo
        run: npm install -g rojo
      - name: Build
        run: rojo build -o game.rbxlx
      # Add Roblox upload step here
```

## 🎨 Customization

### Add New Block Types
Edit `src/ReplicatedStorage/Shared/Config.lua`:
```lua
BLOCK_TYPES = {
    WOOD = { health = 100, color = Color3.fromRGB(161, 111, 67) },
    STONE = { health = 300, color = Color3.fromRGB(125, 125, 125) },
    METAL = { health = 500, color = Color3.fromRGB(80, 80, 90) },
    CRYSTAL = { health = 1000, color = Color3.fromRGB(0, 255, 255) } -- New!
}
```

### Adjust Timings
In `Config.lua`:
```lua
BUILD = {
    MAX_BLOCKS = 200,
    BUILD_TIME = 120, -- Change build time
    GRID_SIZE = 4
}
```

## 🐛 Debugging

### Rojo Not Syncing?
1. Check `rojo serve` is running
2. Verify Studio plugin is connected
3. Check `default.project.json` paths

### Scripts Not Loading?
1. Check Output window in Studio
2. Verify `.server.lua` and `.client.lua` extensions
3. Check for Lua syntax errors

## 📚 Resources

- [Rojo Documentation](https://rojo.space/docs/)
- [Roblox API Reference](https://create.roblox.com/docs/reference/engine)
- [Luau Language](https://luau-lang.org/)

## 📝 License

MIT License - Feel free to use and modify!

---

**Created with ❤️ for the Roblox community**