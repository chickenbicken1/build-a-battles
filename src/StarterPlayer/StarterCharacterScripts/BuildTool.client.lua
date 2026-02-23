-- Build a Battles - Polished Build Tool
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local BuildTool = {}
local uiElements = {}
local currentBlockType = "WOOD"
local canBuild = false
local ghostBlock = nil
local ghostRotation = 0

local COLORS = {
    primary = Color3.fromRGB(59, 130, 246),
    success = Color3.fromRGB(34, 197, 94),
    dark = Color3.fromRGB(17, 24, 39),
    darker = Color3.fromRGB(11, 15, 25),
    light = Color3.fromRGB(243, 244, 246),
    gray = Color3.fromRGB(75, 85, 99),
}

local BLOCK_DATA = {
    WOOD = { 
        color = Color3.fromRGB(161, 111, 67), 
        health = 100, 
        name = "Wood",
        icon = "W"
    },
    STONE = { 
        color = Color3.fromRGB(125, 125, 125), 
        health = 300, 
        name = "Stone",
        icon = "S"
    },
    METAL = { 
        color = Color3.fromRGB(80, 80, 90), 
        health = 500, 
        name = "Metal",
        icon = "M"
    }
}

function BuildTool:Init()
    task.wait(1)
    self:CreateModernUI()
    self:SetupInputs()
    self:CreateGhostBlock()
    self:ConnectEvents()
    print("Build Tool Initialized")
end

function BuildTool:CreateModernUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernBuildUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    uiElements.gui = screenGui
    
    -- Block Selector Panel (Bottom Center)
    local selectorPanel = Instance.new("Frame")
    selectorPanel.Name = "SelectorPanel"
    selectorPanel.Size = UDim2.new(0, 400, 0, 100)
    selectorPanel.Position = UDim2.new(0.5, -200, 1, -120)
    selectorPanel.BackgroundColor3 = COLORS.darker
    selectorPanel.BackgroundTransparency = 0.1
    selectorPanel.BorderSizePixel = 0
    selectorPanel.Parent = screenGui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 16)
    panelCorner.Parent = selectorPanel
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "BLOCK SELECTOR"
    title.TextColor3 = COLORS.gray
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.Parent = selectorPanel
    
    -- Block buttons container
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Size = UDim2.new(1, -20, 0, 60)
    buttonsContainer.Position = UDim2.new(0, 10, 0, 32)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = selectorPanel
    
    local buttonsLayout = Instance.new("UIListLayout")
    buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonsLayout.Padding = UDim.new(0, 10)
    buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonsLayout.Parent = buttonsContainer
    
    uiElements.blockButtons = {}
    
    for blockType, data in pairs(BLOCK_DATA) do
        local btn = self:CreateBlockButton(buttonsContainer, blockType, data)
        uiElements.blockButtons[blockType] = btn
    end
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 500, 0, 25)
    instructions.Position = UDim2.new(0.5, -250, 1, -155)
    instructions.BackgroundTransparency = 1
    instructions.Text = "[LMB] Place  |  [LMB + Shift] Remove  |  [R] Rotate"
    instructions.TextColor3 = COLORS.light
    instructions.TextSize = 14
    instructions.Font = Enum.Font.Gotham
    instructions.Parent = screenGui
    
    -- Rotation indicator
    local rotIndicator = Instance.new("Frame")
    rotIndicator.Name = "RotationIndicator"
    rotIndicator.Size = UDim2.new(0, 60, 0, 60)
    rotIndicator.Position = UDim2.new(1, -80, 1, -140)
    rotIndicator.BackgroundColor3 = COLORS.dark
    rotIndicator.BorderSizePixel = 0
    rotIndicator.Parent = screenGui
    
    local rotCorner = Instance.new("UICorner")
    rotCorner.CornerRadius = UDim.new(0, 12)
    rotCorner.Parent = rotIndicator
    
    local rotLabel = Instance.new("TextLabel")
    rotLabel.Size = UDim2.new(1, 0, 0, 20)
    rotLabel.Position = UDim2.new(0, 0, 0, 5)
    rotLabel.BackgroundTransparency = 1
    rotLabel.Text = "ROT"
    rotLabel.TextColor3 = COLORS.gray
    rotLabel.TextSize = 10
    rotLabel.Font = Enum.Font.GothamBold
    rotLabel.Parent = rotIndicator
    
    local rotValue = Instance.new("TextLabel")
    rotValue.Name = "Value"
    rotValue.Size = UDim2.new(1, 0, 0, 30)
    rotValue.Position = UDim2.new(0, 0, 0, 22)
    rotValue.BackgroundTransparency = 1
    rotValue.Text = "0"
    rotValue.TextColor3 = COLORS.primary
    rotValue.TextSize = 24
    rotValue.Font = Enum.Font.GothamBold
    rotValue.Parent = rotIndicator
    
    uiElements.rotValue = rotValue
    
    -- Block info tooltip (follows mouse)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 150, 0, 80)
    tooltip.BackgroundColor3 = COLORS.darker
    tooltip.BackgroundTransparency = 0.05
    tooltip.BorderSizePixel = 0
    tooltip.Visible = false
    tooltip.Parent = screenGui
    
    local tipCorner = Instance.new("UICorner")
    tipCorner.CornerRadius = UDim.new(0, 10)
    tipCorner.Parent = tooltip
    
    local tipTitle = Instance.new("TextLabel")
    tipTitle.Size = UDim2.new(1, -10, 0, 25)
    tipTitle.Position = UDim2.new(0, 5, 0, 5)
    tipTitle.BackgroundTransparency = 1
    tipTitle.Text = "Block Info"
    tipTitle.TextColor3 = COLORS.light
    tipTitle.TextSize = 16
    tipTitle.Font = Enum.Font.GothamBold
    tipTitle.Parent = tooltip
    
    local tipHealth = Instance.new("TextLabel")
    tipHealth.Size = UDim2.new(1, -10, 0, 20)
    tipHealth.Position = UDim2.new(0, 5, 0, 30)
    tipHealth.BackgroundTransparency = 1
    tipHealth.Text = "Health: 100"
    tipHealth.TextColor3 = COLORS.success
    tipHealth.TextSize = 14
    tipHealth.Font = Enum.Font.Gotham
    tipHealth.Parent = tooltip
    
    local tipDesc = Instance.new("TextLabel")
    tipDesc.Size = UDim2.new(1, -10, 0, 20)
    tipDesc.Position = UDim2.new(0, 5, 0, 52)
    tipDesc.BackgroundTransparency = 1
    tipDesc.Text = "Basic building block"
    tipDesc.TextColor3 = COLORS.gray
    tipDesc.TextSize = 12
    tipDesc.Font = Enum.Font.Gotham
    tipDesc.Parent = tooltip
    
    uiElements.tooltip = tooltip
    uiElements.tooltipTitle = tipTitle
    uiElements.tooltipHealth = tipHealth
end

function BuildTool:CreateBlockButton(parent, blockType, data)
    local btn = Instance.new("TextButton")
    btn.Name = blockType
    btn.Size = UDim2.new(0, 80, 0, 60)
    btn.BackgroundColor3 = data.color
    btn.Text = ""
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    -- Selection indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(1, 4, 1, 4)
    indicator.Position = UDim2.new(0, -2, 0, -2)
    indicator.BackgroundColor3 = COLORS.primary
    indicator.BorderSizePixel = 0
    indicator.Visible = blockType == currentBlockType
    indicator.Parent = btn
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 12)
    indCorner.Parent = indicator
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0.5, -15, 0, 5)
    icon.BackgroundTransparency = 1
    icon.Text = data.icon
    icon.TextColor3 = COLORS.light
    icon.TextSize = 24
    icon.Font = Enum.Font.GothamBold
    icon.Parent = btn
    
    -- Name label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 1, -22)
    label.BackgroundTransparency = 1
    label.Text = data.name:upper()
    label.TextColor3 = COLORS.light
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.Parent = btn
    
    -- Click handler
    btn.MouseButton1Click:Connect(function()
        self:SelectBlockType(blockType)
    end)
    
    -- Hover effects
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 85, 0, 65)}):Play()
        self:ShowTooltip(blockType)
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 80, 0, 60)}):Play()
        uiElements.tooltip.Visible = false
    end)
    
    return btn
end

function BuildTool:SelectBlockType(blockType)
    currentBlockType = blockType
    
    -- Update indicators
    for typeName, btn in pairs(uiElements.blockButtons) do
        local indicator = btn:FindFirstChild("Indicator")
        if indicator then
            indicator.Visible = typeName == blockType
        end
    end
    
    -- Update ghost block
    if ghostBlock then
        local data = BLOCK_DATA[blockType]
        ghostBlock.Color = data.color
    end
    
    -- Sound effect (visual feedback)
    TweenService:Create(uiElements.blockButtons[blockType], TweenInfo.new(0.1), 
        {BackgroundColor3 = BLOCK_DATA[blockType].color:Lerp(Color3.new(1,1,1), 0.3)}):Play()
    task.delay(0.1, function()
        TweenService:Create(uiElements.blockButtons[blockType], TweenInfo.new(0.1), 
            {BackgroundColor3 = BLOCK_DATA[blockType].color}):Play()
    end)
end

function BuildTool:ShowTooltip(blockType)
    local data = BLOCK_DATA[blockType]
    uiElements.tooltipTitle.Text = data.name
    uiElements.tooltipHealth.Text = "Health: " .. data.health
    uiElements.tooltip.Visible = true
end

function BuildTool:CreateGhostBlock()
    ghostBlock = Instance.new("Part")
    ghostBlock.Name = "GhostBlock"
    ghostBlock.Size = Vector3.new(4, 4, 4)
    ghostBlock.Transparency = 0.6
    ghostBlock.Anchored = true
    ghostBlock.CanCollide = false
    ghostBlock.Color = BLOCK_DATA.WOOD.color
    ghostBlock.Material = Enum.Material.SmoothPlastic
    ghostBlock.Parent = workspace
    
    -- Selection outline effect
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = ghostBlock
    selectionBox.Color3 = COLORS.primary
    selectionBox.LineThickness = 0.05
    selectionBox.Parent = ghostBlock
    
    -- Make transparent initially
    ghostBlock.Transparency = 1
    selectionBox.Visible = false
end

function BuildTool:SetupInputs()
    -- Ghost block positioning
    RunService.RenderStepped:Connect(function()
        if not canBuild or not ghostBlock then
            if ghostBlock then 
                ghostBlock.Transparency = 1 
                ghostBlock:FindFirstChildOfClass("SelectionBox").Visible = false
            end
            return
        end
        
        ghostBlock.Transparency = 0.6
        ghostBlock:FindFirstChildOfClass("SelectionBox").Visible = true
        
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
        
        if result then
            local gridPos = self:SnapToGrid(result.Position + result.Normal * 2)
            ghostBlock.Position = gridPos
            ghostBlock.Rotation = Vector3.new(0, ghostRotation, 0)
        end
    end)
    
    -- Placement input
    mouse.Button1Down:Connect(function()
        if not canBuild then return end
        
        local target = mouse.Target
        
        -- Check for shift to remove
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            if target and target:IsA("BasePart") and target.Parent and target.Parent.Name == "Buildings" then
                if target:GetAttribute("Owner") == player.UserId then
                    local remotes = ReplicatedStorage:WaitForChild("Remotes")
                    local removeEvent = remotes:FindFirstChild("RemoveBlock")
                    if removeEvent then
                        removeEvent:FireServer(target)
                        self:PlayRemoveEffect(target.Position, target.Color)
                    end
                end
            end
        else
            -- Place block
            local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
            
            if result then
                local placePos = result.Position + result.Normal * 2
                local remotes = ReplicatedStorage:WaitForChild("Remotes")
                local placeEvent = remotes:FindFirstChild("PlaceBlock")
                if placeEvent then
                    placeEvent:FireServer(placePos, currentBlockType, ghostRotation)
                    self:PlayPlaceEffect(placePos, BLOCK_DATA[currentBlockType].color)
                end
            end
        end
    end)
    
    -- Rotation input
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.R then
            ghostRotation = (ghostRotation + 90) % 360
            if uiElements.rotValue then
                uiElements.rotValue.Text = tostring(ghostRotation)
                -- Pop animation
                TweenService:Create(uiElements.rotValue, TweenInfo.new(0.1), {TextSize = 28}):Play()
                task.delay(0.1, function()
                    TweenService:Create(uiElements.rotValue, TweenInfo.new(0.1), {TextSize = 24}):Play()
                end)
            end
        end
    end)
end

function BuildTool:SnapToGrid(position)
    local grid = 4
    return Vector3.new(
        math.floor(position.X / grid + 0.5) * grid,
        math.floor(position.Y / grid + 0.5) * grid,
        math.floor(position.Z / grid + 0.5) * grid
    )
end

function BuildTool:PlayPlaceEffect(position, color)
    -- Particle burst
    for i = 1, 8 do
        local particle = Instance.new("Part")
        particle.Size = Vector3.new(0.3, 0.3, 0.3)
        particle.Position = position
        particle.Color = color
        particle.Material = Enum.Material.Neon
        particle.Anchored = false
        particle.CanCollide = false
        particle.Parent = workspace
        
        local angle = (i / 8) * math.pi * 2
        local force = Vector3.new(math.cos(angle) * 10, math.random(5, 15), math.sin(angle) * 10)
        particle.Velocity = force
        
        game:GetService("Debris"):AddItem(particle, 0.5)
    end
end

function BuildTool:PlayRemoveEffect(position, color)
    -- Break particles
    for i = 1, 12 do
        local particle = Instance.new("Part")
        particle.Size = Vector3.new(0.4, 0.4, 0.4)
        particle.Position = position
        particle.Color = color
        particle.Anchored = false
        particle.CanCollide = false
        particle.Parent = workspace
        
        local angle = math.random() * math.pi * 2
        local force = Vector3.new(math.cos(angle) * 15, math.random(10, 25), math.sin(angle) * 15)
        particle.Velocity = force
        
        game:GetService("Debris"):AddItem(particle, 0.8)
    end
end

function BuildTool:SetBuildingEnabled(enabled)
    canBuild = enabled
    if uiElements.gui then
        uiElements.gui.Enabled = enabled
    end
    if not enabled and ghostBlock then
        ghostBlock.Transparency = 1
        local selectionBox = ghostBlock:FindFirstChildOfClass("SelectionBox")
        if selectionBox then selectionBox.Visible = false end
    end
end

function BuildTool:ConnectEvents()
    -- Listen for phase changes
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameStateEvent = remotes:WaitForChild("GameStateEvent")
    
    gameStateEvent.OnClientEvent:Connect(function(type, data)
        if type == "PHASE" then
            self:SetBuildingEnabled(data.phase == "BUILDING")
        end
    end)
end

BuildTool:Init()
_G.BuildTool = BuildTool
