-- BuildController - Fortnite Style Building Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local BuildController = {}
local uiElements = {}
local ghostBuild = nil
local currentPiece = "WALL"
local currentMaterial = "WOOD"
local canBuild = false
local isBuildingMode = false
local rotation = 0
local materials = {
    WOOD = 0,
    BRICK = 0,
    METAL = 0
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceBuildEvent = Remotes:WaitForChild("PlaceBuild")
local MaterialUpdateEvent = Remotes:WaitForChild("MaterialUpdate")

-- Color shortcuts
local C = Config.COLORS

function BuildController:Init()
    self:CreateUI()
    self:CreateGhostBuild()
    self:SetupInputs()
    self:ConnectEvents()
    print("✅ Build Controller Initialized")
end

-- Create building UI (Fortnite style)
function BuildController:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BuildUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Material display (top right)
    local matFrame = Instance.new("Frame")
    matFrame.Name = "Materials"
    matFrame.Size = UDim2.new(0, 200, 0, 80)
    matFrame.Position = UDim2.new(1, -210, 0, 10)
    matFrame.BackgroundColor3 = C.dark
    matFrame.BackgroundTransparency = 0.3
    matFrame.BorderSizePixel = 0
    matFrame.Parent = screenGui
    
    local matCorner = Instance.new("UICorner")
    matCorner.CornerRadius = UDim.new(0, 8)
    matCorner.Parent = matFrame
    
    -- Material labels
    local matTypes = {"WOOD", "BRICK", "METAL"}
    local matColors = {C.wood, C.brick, C.metal}
    
    for i, matType in ipairs(matTypes) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 22)
        row.Position = UDim2.new(0, 5, 0, 5 + (i-1) * 24)
        row.BackgroundTransparency = 1
        row.Parent = matFrame
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.BackgroundColor3 = matColors[i]
        icon.Text = Config.MATERIALS[matType].icon
        icon.TextSize = 14
        icon.Parent = row
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = icon
        
        local amount = Instance.new("TextLabel")
        amount.Name = matType .. "Amount"
        amount.Size = UDim2.new(1, -30, 1, 0)
        amount.Position = UDim2.new(0, 28, 0, 0)
        amount.BackgroundTransparency = 1
        amount.Text = "0"
        amount.TextColor3 = C.light
        amount.TextSize = 16
        amount.Font = Enum.Font.GothamBold
        amount.TextXAlignment = Enum.TextXAlignment.Left
        amount.Parent = row
        
        uiElements[matType .. "Text"] = amount
    end
    
    -- Build piece selector (bottom center)
    local selector = Instance.new("Frame")
    selector.Name = "PieceSelector"
    selector.Size = UDim2.new(0, 320, 0, 70)
    selector.Position = UDim2.new(0.5, -160, 1, -90)
    selector.BackgroundColor3 = C.dark
    selector.BackgroundTransparency = 0.2
    selector.BorderSizePixel = 0
    selector.Visible = false
    selector.Parent = screenGui
    uiElements.selector = selector
    
    local selCorner = Instance.new("UICorner")
    selCorner.CornerRadius = UDim.new(0, 12)
    selCorner.Parent = selector
    
    -- Piece buttons
    local pieces = {{"WALL", "Q"}, {"FLOOR", "C"}, {"STAIR", "V"}, {"ROOF", "B"}}
    
    for i, pieceData in ipairs(pieces) do
        local pieceType, key = pieceData[1], pieceData[2]
        local btn = Instance.new("TextButton")
        btn.Name = pieceType
        btn.Size = UDim2.new(0, 70, 0, 50)
        btn.Position = UDim2.new(0, 10 + (i-1) * 78, 0, 10)
        btn.BackgroundColor3 = i == 1 and C.primary or C.gray
        btn.Text = Config.BUILD_PIECES[pieceType].icon
        btn.TextColor3 = C.light
        btn.TextSize = 24
        btn.Font = Enum.Font.GothamBold
        btn.Parent = selector
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        -- Key label
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(1, 0, 0, 15)
        keyLabel.Position = UDim2.new(0, 0, 1, -15)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = "[" .. key .. "]"
        keyLabel.TextColor3 = C.gray
        keyLabel.TextSize = 10
        keyLabel.Font = Enum.Font.Gotham
        keyLabel.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SelectPiece(pieceType)
        end)
        
        uiElements[pieceType .. "Btn"] = btn
    end
    
    -- Material selector (right of pieces)
    local matSelector = Instance.new("Frame")
    matSelector.Name = "MaterialSelector"
    matSelector.Size = UDim2.new(0, 50, 0, 50)
    matSelector.Position = UDim2.new(0, 320, 0, 10)
    matSelector.BackgroundColor3 = C.wood
    matSelector.Parent = selector
    
    local matSelCorner = Instance.new("UICorner")
    matSelCorner.CornerRadius = UDim.new(0, 8)
    matSelCorner.Parent = matSelector
    
    uiElements.matSelector = matSelector
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(0, 400, 0, 20)
    instructions.Position = UDim2.new(0.5, -200, 1, -115)
    instructions.BackgroundTransparency = 1
    instructions.Text = "LMB: Build | R: Rotate | Shift+LMB: Edit"
    instructions.TextColor3 = C.light
    instructions.TextSize = 14
    instructions.Font = Enum.Font.Gotham
    instructions.Parent = screenGui
    uiElements.instructions = instructions
    
    -- Build mode indicator
    local modeIndicator = Instance.new("TextLabel")
    modeIndicator.Name = "ModeIndicator"
    modeIndicator.Size = UDim2.new(0, 150, 0, 30)
    modeIndicator.Position = UDim2.new(0.5, -75, 0.85, 0)
    modeIndicator.BackgroundColor3 = C.primary
    modeIndicator.Text = "BUILD MODE"
    modeIndicator.TextColor3 = C.dark
    modeIndicator.TextSize = 16
    modeIndicator.Font = Enum.Font.GothamBold
    modeIndicator.Visible = false
    modeIndicator.Parent = screenGui
    
    local modeCorner = Instance.new("UICorner")
    modeCorner.CornerRadius = UDim.new(0, 6)
    modeCorner.Parent = modeIndicator
    
    uiElements.modeIndicator = modeIndicator
end

-- Create ghost build preview
function BuildController:CreateGhostBuild()
    ghostBuild = Instance.new("Part")
    ghostBuild.Name = "GhostBuild"
    ghostBuild.Transparency = 0.5
    ghostBuild.Anchored = true
    ghostBuild.CanCollide = false
    ghostBuild.CastShadow = false
    ghostBuild.Parent = workspace
    
    -- Selection box
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = ghostBuild
    selectionBox.Color3 = C.primary
    selectionBox.LineThickness = 0.05
    selectionBox.Parent = ghostBuild
    
    ghostBuild.Transparency = 1
end

-- Select build piece
function BuildController:SelectPiece(pieceType)
    currentPiece = pieceType
    
    -- Update button colors
    for _, p in ipairs({"WALL", "FLOOR", "STAIR", "ROOF"}) do
        local btn = uiElements[p .. "Btn"]
        if btn then
            btn.BackgroundColor3 = (p == pieceType) and C.primary or C.gray
        end
    end
    
    self:UpdateGhostBuild()
end

-- Select material (cycles through)
function BuildController:CycleMaterial()
    local mats = {"WOOD", "BRICK", "METAL"}
    local currentIndex = table.find(mats, currentMaterial) or 1
    local nextIndex = (currentIndex % #mats) + 1
    currentMaterial = mats[nextIndex]
    
    local colors = {WOOD = C.wood, BRICK = C.brick, METAL = C.metal}
    uiElements.matSelector.BackgroundColor3 = colors[currentMaterial]
    
    self:UpdateGhostBuild()
end

-- Update ghost build preview
function BuildController:UpdateGhostBuild()
    if not ghostBuild then return end
    
    local pieceConfig = Config.BUILD_PIECES[currentPiece]
    local materialConfig = Config.MATERIALS[currentMaterial]
    
    ghostBuild.Size = pieceConfig.size
    ghostBuild.Color = materialConfig.color
    ghostBuild.Material = materialConfig.material
end

-- Setup inputs
function BuildController:SetupInputs()
    -- Toggle build mode with B
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.B then
            self:ToggleBuildMode()
        elseif input.KeyCode == Enum.KeyCode.R then
            rotation = (rotation + 90) % 360
        elseif input.KeyCode == Enum.KeyCode.Q then
            if isBuildingMode then self:SelectPiece("WALL") end
        elseif input.KeyCode == Enum.KeyCode.C then
            if isBuildingMode then self:SelectPiece("FLOOR") end
        elseif input.KeyCode == Enum.KeyCode.V then
            if isBuildingMode then self:SelectPiece("STAIR") end
        elseif input.KeyCode == Enum.KeyCode.N then
            if isBuildingMode then self:SelectPiece("ROOF") end
        elseif input.KeyCode == Enum.KeyCode.G then
            self:CycleMaterial()
        end
    end)
    
    -- Mouse tracking for ghost build
    RunService.RenderStepped:Connect(function()
        if not isBuildingMode or not ghostBuild then
            if ghostBuild then ghostBuild.Transparency = 1 end
            return
        end
        
        -- Check if we have materials
        if materials[currentMaterial] < 10 then
            ghostBuild.Transparency = 1
            return
        end
        
        ghostBuild.Transparency = 0.5
        
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * Config.BUILD.BUILD_RANGE)
        
        if result then
            local pieceConfig = Config.BUILD_PIECES[currentPiece]
            local pos = result.Position + (result.Normal * pieceConfig.offset)
            pos = Utils.SnapToGrid(pos, Config.BUILD.GRID_SIZE)
            
            local rot = Utils.GetRotationFromNormal(result.Normal) * CFrame.Angles(0, math.rad(rotation), 0)
            ghostBuild.CFrame = CFrame.new(pos) * rot
        end
    end)
    
    -- Click to build
    mouse.Button1Down:Connect(function()
        if not isBuildingMode then return end
        if materials[currentMaterial] < 10 then
            print("Not enough materials!")
            return
        end
        
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * Config.BUILD.BUILD_RANGE)
        
        if result then
            PlaceBuildEvent:FireServer(currentPiece, result.Position, result.Normal, currentMaterial)
        end
    end)
end

-- Toggle build mode
function BuildController:ToggleBuildMode()
    isBuildingMode = not isBuildingMode
    
    uiElements.selector.Visible = isBuildingMode
    uiElements.modeIndicator.Visible = isBuildingMode
    uiElements.instructions.Visible = isBuildingMode
    
    -- Unequip tools when entering build mode
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum and isBuildingMode then
            hum:UnequipTools()
        end
    end
    
    print(isBuildingMode and "🔨 Build Mode ON" or "🔨 Build Mode OFF")
end

-- Connect events
function BuildController:ConnectEvents()
    -- Update materials
    MaterialUpdateEvent.OnClientEvent:Connect(function(newMaterials)
        materials = newMaterials
        
        for matType, amount in pairs(materials) do
            local textLabel = uiElements[matType .. "Text"]
            if textLabel then
                textLabel.Text = Utils.FormatNumber(amount)
                
                -- Highlight if low
                if amount < 10 then
                    textLabel.TextColor3 = C.danger
                else
                    textLabel.TextColor3 = C.light
                end
            end
        end
    end)
end

-- Enable/disable building
function BuildController:SetBuildingEnabled(enabled)
    canBuild = enabled
    if not enabled and isBuildingMode then
        self:ToggleBuildMode()
    end
end

BuildController:Init()
_G.BuildController = BuildController
