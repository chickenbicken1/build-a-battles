-- Build a Battles - Client Build Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Config = require(ReplicatedStorage.Shared.Config)
local BuildEvents = ReplicatedStorage.Remotes.BuildEvents

local BuildTool = {}
local currentBlockType = "WOOD"
local canBuild = false
local ghostBlock = nil

function BuildTool:Init()
    self:CreateUI()
    self:SetupInputs()
    self:CreateGhostBlock()
    
    print("✅ Build Tool Initialized")
end

function BuildTool:CreateUI()
    -- Building UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildUI"
    screenGui.ResetOnSpawn = false
    
    -- Block selector
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
    
    -- Block type buttons
    local types = {"WOOD", "STONE", "METAL"}
    for i, blockType in ipairs(types) do
        local btn = Instance.new("TextButton")
        btn.Name = blockType
        btn.Size = UDim2.new(0.3, -5, 0.8, 0)
        btn.Position = UDim2.new((i-1) * 0.33, 5, 0.1, 0)
        btn.BackgroundColor3 = Config.BUILD.BLOCK_TYPES[blockType].color
        btn.Text = blockType
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Parent = selector
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            currentBlockType = blockType
            self:UpdateGhostBlock()
        end)
    end
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 400, 0, 30)
    instructions.Position = UDim2.new(0.5, -200, 0.85, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Click to place | Press R to rotate | Click block to remove"
    instructions.TextColor3 = Color3.new(1, 1, 1)
    instructions.TextScaled = true
    instructions.Parent = screenGui
    
    screenGui.Parent = player.PlayerGui
end

function BuildTool:CreateGhostBlock()
    ghostBlock = Instance.new("Part")
    ghostBlock.Name = "GhostBlock"
    ghostBlock.Size = Vector3.new(Config.BUILD.GRID_SIZE, Config.BUILD.GRID_SIZE, Config.BUILD.GRID_SIZE)
    ghostBlock.Transparency = 0.7
    ghostBlock.Anchored = true
    ghostBlock.CanCollide = false
    ghostBlock.Material = Enum.Material.SmoothPlastic
    ghostBlock.Parent = workspace
    
    self:UpdateGhostBlock()
end

function BuildTool:UpdateGhostBlock()
    if ghostBlock then
        local config = Config.BUILD.BLOCK_TYPES[currentBlockType]
        ghostBlock.Color = config.color
    end
end

function BuildTool:SetupInputs()
    -- Mouse movement for ghost block
    RunService.RenderStepped:Connect(function()
        if not canBuild then
            ghostBlock.Transparency = 1
            return
        end
        
        ghostBlock.Transparency = 0.7
        
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
        
        if result then
            local gridPos = self:SnapToGrid(result.Position + result.Normal * (Config.BUILD.GRID_SIZE / 2))
            ghostBlock.Position = gridPos
        end
    end)
    
    -- Click to place/remove
    mouse.Button1Down:Connect(function()
        if not canBuild then return end
        
        local target = mouse.Target
        
        if target and target:IsA("Part") and target.Parent == workspace.Buildings then
            -- Remove block
            if target:GetAttribute("Owner") == player.UserId then
                BuildEvents.RemoveBlock:FireServer(target)
            end
        else
            -- Place block
            local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
            
            if result then
                local placePos = result.Position + result.Normal * (Config.BUILD.GRID_SIZE / 2)
                BuildEvents.PlaceBlock:FireServer(placePos, currentBlockType)
            end
        end
    end)
    
    -- Rotate ghost block with R
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.R then
            ghostBlock.Rotation = ghostBlock.Rotation + Vector3.new(0, 90, 0)
        end
    end)
end

function BuildTool:SnapToGrid(position)
    local grid = Config.BUILD.GRID_SIZE
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

BuildTool:Init()
return BuildTool