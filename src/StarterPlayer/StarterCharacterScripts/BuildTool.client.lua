-- Build a Battles - Client Build Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for Config
local Config
task.spawn(function()
    local success = pcall(function()
        Config = require(ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Config", 10))
    end)
    if not success then
        Config = {
            BUILD = { MAX_BLOCKS = 200, GRID_SIZE = 4, BLOCK_TYPES = { WOOD = { color = Color3.fromRGB(161, 111, 67) } } }
        }
    end
end)

-- Wait for Remotes
local BuildEvents
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        BuildEvents = remotes
    end
end)

local BuildTool = {}
local currentBlockType = "WOOD"
local canBuild = false
local ghostBlock = nil

function BuildTool:Init()
    task.wait(2) -- Wait for everything to load
    
    self:CreateUI()
    self:SetupInputs()
    self:CreateGhostBlock()
    
    print("✅ Build Tool Initialized")
end

function BuildTool:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildUI"
    screenGui.ResetOnSpawn = false
    
    local selector = Instance.new("Frame")
    selector.Name = "BlockSelector"
    selector.Size = UDim2.new(0, 300, 0, 60)
    selector.Position = UDim2.new(0.5, -150, 0.9, 0)
    selector.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    selector.BackgroundTransparency = 0.3
    selector.BorderSizePixel = 0
    selector.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = selector
    
    local types = {"WOOD", "STONE", "METAL"}
    for i, blockType in ipairs(types) do
        local btn = Instance.new("TextButton")
        btn.Name = blockType
        btn.Size = UDim2.new(0.3, -5, 0.8, 0)
        btn.Position = UDim2.new((i-1) * 0.33, 5, 0.1, 0)
        btn.BackgroundColor3 = self:GetBlockColor(blockType)
        btn.Text = blockType
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Parent = selector
        
        btn.MouseButton1Click:Connect(function()
            currentBlockType = blockType
            self:UpdateGhostBlock()
        end)
    end
    
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 400, 0, 30)
    instructions.Position = UDim2.new(0.5, -200, 0.85, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Click to place | Click block to remove"
    instructions.TextColor3 = Color3.new(1, 1, 1)
    instructions.TextScaled = true
    instructions.Parent = screenGui
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

function BuildTool:GetBlockColor(blockType)
    local colors = {
        WOOD = Color3.fromRGB(161, 111, 67),
        STONE = Color3.fromRGB(125, 125, 125),
        METAL = Color3.fromRGB(80, 80, 90)
    }
    return colors[blockType] or Color3.fromRGB(100, 100, 100)
end

function BuildTool:CreateGhostBlock()
    ghostBlock = Instance.new("Part")
    ghostBlock.Name = "GhostBlock"
    ghostBlock.Size = Vector3.new(4, 4, 4)
    ghostBlock.Transparency = 0.7
    ghostBlock.Anchored = true
    ghostBlock.CanCollide = false
    ghostBlock.Color = self:GetBlockColor("WOOD")
    ghostBlock.Parent = workspace
end

function BuildTool:UpdateGhostBlock()
    if ghostBlock then
        ghostBlock.Color = self:GetBlockColor(currentBlockType)
    end
end

function BuildTool:SetupInputs()
    RunService.RenderStepped:Connect(function()
        if not canBuild or not ghostBlock then
            if ghostBlock then ghostBlock.Transparency = 1 end
            return
        end
        
        ghostBlock.Transparency = 0.7
        
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
        
        if result then
            local gridSize = (Config and Config.BUILD and Config.BUILD.GRID_SIZE) or 4
            local gridPos = self:SnapToGrid(result.Position + result.Normal * (gridSize / 2), gridSize)
            ghostBlock.Position = gridPos
        end
    end)
    
    mouse.Button1Down:Connect(function()
        if not canBuild or not BuildEvents then return end
        
        local target = mouse.Target
        
        if target and target:IsA("BasePart") and target.Parent and target.Parent.Name == "Buildings" then
            local removeEvent = BuildEvents:FindFirstChild("RemoveBlock")
            if removeEvent and target:GetAttribute("Owner") == player.UserId then
                removeEvent:FireServer(target)
            end
        else
            local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
            
            if result then
                local gridSize = (Config and Config.BUILD and Config.BUILD.GRID_SIZE) or 4
                local placePos = result.Position + result.Normal * (gridSize / 2)
                local placeEvent = BuildEvents:FindFirstChild("PlaceBlock")
                if placeEvent then
                    placeEvent:FireServer(placePos, currentBlockType)
                end
            end
        end
    end)
end

function BuildTool:SnapToGrid(position, grid)
    grid = grid or 4
    return Vector3.new(
        math.floor(position.X / grid + 0.5) * grid,
        math.floor(position.Y / grid + 0.5) * grid,
        math.floor(position.Z / grid + 0.5) * grid
    )
end

function BuildTool:SetBuildingEnabled(enabled)
    canBuild = enabled
    if not enabled and ghostBlock then
        ghostBlock.Transparency = 1
    end
end

-- Initialize
BuildTool:Init()

return BuildTool