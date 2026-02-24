-- PetFollow.client.lua
-- Enhanced Premium Pet System with Follow-Behind logic and global bobbing
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")

-- Container for visibility and organization
local PetContainer = workspace:FindFirstChild("PlayerPets")
if not PetContainer then
    PetContainer = Instance.new("Folder")
    PetContainer.Name = "PlayerPets"
    PetContainer.Parent = workspace
end

local activePets = {} -- Map of model instances
local FOLLOW_SPEED = 6 -- Slower, smoother speed
local BOB_SPEED = 1.5
local BOB_HEIGHT = 0.4
local FOLLOW_DISTANCE = 4

-- SeenKid Internal State for Bobbing
local globalBob = 0
local bobIncr = 0.02
local bobDir = 1

local function ClearPets()
    for _, pet in pairs(activePets) do pet:Destroy() end
    table.clear(activePets)
end

local function CreatePetModel(petConfig)
    local model = Instance.new("Model")
    model.Name = petConfig.name.."_Follower"
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(1.2, 1.2, 1.2)
    part.Color = petConfig.color or Color3.new(1,1,1)
    part.Material = Enum.Material.Plastic -- Plastic often looks cleaner for simulators
    part.Shape = Enum.PartType.Ball
    part.Anchored = true
    part.CanCollide = false
    part.Parent = model
    
    -- Outline
    local stroke = Instance.new("SelectionBox")
    stroke.Adornee = part
    stroke.Color3 = Color3.new(0,0,0)
    stroke.LineThickness = 0.05
    stroke.SurfaceColor3 = Color3.new(0,0,0)
    stroke.Transparency = 0.4
    stroke.Parent = part

    -- Face
    local eyeL = Instance.new("Part")
    eyeL.Size = Vector3.new(0.2, 0.4, 0.2)
    eyeL.Color = Color3.new(0,0,0)
    eyeL.Material = Enum.Material.SmoothPlastic
    eyeL.Anchored = true ; eyeL.CanCollide = false ; eyeL.Parent = model
    
    local eyeR = eyeL:Clone() ; eyeR.Parent = model
    
    model.PrimaryPart = part
    model.Parent = PetContainer
    return model
end

local function Update(dt)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    
    -- Global Bobbing Logic
    globalBob = globalBob + (bobIncr * bobDir)
    if math.abs(globalBob) > BOB_HEIGHT then bobDir = bobDir * -1 end
    
    local equippedCount = 0
    for _ in pairs(activePets) do equippedCount = equippedCount + 1 end
    if equippedCount == 0 then return end
    
    -- Calculate positions behind the player
    -- We'll arrange them in a small arc behind the player
    local i = 0
    local spacing = 2.5
    local startOffset = -(equippedCount - 1) * spacing / 2
    
    for petId, model in pairs(activePets) do
        -- Position behind player: root.CFrame * CFrame.new(horizontalOffset, 2 + globalBob, FOLLOW_DISTANCE)
        local horizontalOffset = startOffset + (i * spacing)
        local targetCFrame = root.CFrame * CFrame.new(horizontalOffset, 2 + globalBob, FOLLOW_DISTANCE)
        
        -- Smooth move and point towards player's back or forward
        local targetPos = targetCFrame.Position
        local lookAt = root.Position + root.CFrame.LookVector * 10
        
        model.PrimaryPart.CFrame = model.PrimaryPart.CFrame:Lerp(CFrame.new(targetPos, lookAt), dt * FOLLOW_SPEED)
        
        -- Update Eyes
        local pPart = model.PrimaryPart
        model:FindFirstChildAt(2).CFrame = pPart.CFrame * CFrame.new(0.3, 0.2, -0.55)
        model:FindFirstChildAt(3).CFrame = pPart.CFrame * CFrame.new(-0.3, 0.2, -0.55)
        
        i = i + 1
    end
end

DataUpdateEvent.OnClientEvent:Connect(function(action, data)
    if action == "SYNC" then
        ClearPets()
        if data.equippedPets then
            for _, pet in ipairs(data.equippedPets) do
                activePets[pet.id] = CreatePetModel(pet)
            end
        end
    end
end)

RunService.RenderStepped:Connect(Update)
player.CharacterAdded:Connect(function(char) character = char end)
