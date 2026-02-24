-- PetFollow.client.lua
-- Replicates SeenKid circular follow pattern with smooth Lerp/BOB
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")

local activePets = {} -- Map of model instances
local CIRCLE_RADIUS = 5
local FOLLOW_SPEED = 12
local BOB_SPEED = 2
local BOB_HEIGHT = 0.5

-- SeenKid Internal State
local globalBob = 0
local sw = false

local function GetPointOnCircle(radius, degrees)
    local rad = math.rad(degrees)
    return Vector3.new(math.cos(rad) * radius, 0, math.sin(rad) * radius)
end

local function ClearPets()
    for _, pet in pairs(activePets) do pet:Destroy() end
    table.clear(activePets)
end

local function CreatePetModel(petConfig)
    local model = Instance.new("Model")
    model.Name = petConfig.name.."_Follower"
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(1.5, 1.5, 1.5)
    part.Color = petConfig.color or Color3.new(1,1,1)
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Ball
    part.Anchored = true
    part.CanCollide = false
    part.Parent = model
    
    -- Face/Eyes
    local eyeL = Instance.new("Part")
    eyeL.Size = Vector3.new(0.3, 0.3, 0.3)
    eyeL.Color = Color3.new(0,0,0) ; eyeL.Shape = Enum.PartType.Ball
    eyeL.Anchored = true ; eyeL.CanCollide = false ; eyeL.Parent = model
    
    local eyeR = eyeL:Clone() ; eyeR.Parent = model
    
    model.PrimaryPart = part
    model.Parent = workspace:WaitForChild("CurrentCamera")
    return model
end

local function Update(dt)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    
    -- Update Global Bob
    local bobInc = 0.035
    if not sw then
        globalBob = globalBob + bobInc
        if globalBob >= 0.75 then sw = true end
    else
        globalBob = globalBob - bobInc
        if globalBob <= -0.75 then sw = false end
    end
    
    local i = 0
    local equippedCount = 0
    for _ in pairs(activePets) do equippedCount = equippedCount + 1 end
    
    if equippedCount == 0 then return end
    local spacing = 360 / equippedCount
    
    for petId, model in pairs(activePets) do
        local angle = (tick() * 30) + (i * spacing)
        local offset = GetPointOnCircle(CIRCLE_RADIUS, angle)
        
        -- Target Position
        local targetPos = root.Position + offset + Vector3.new(0, 2 + globalBob, 0)
        
        -- Smooth Move
        model.PrimaryPart.CFrame = model.PrimaryPart.CFrame:Lerp(CFrame.new(targetPos, root.Position), dt * FOLLOW_SPEED)
        
        -- Update Eyes
        local pPart = model.PrimaryPart
        model:FindFirstChildAt(2).CFrame = pPart.CFrame * CFrame.new(0.4, 0.4, -0.6)
        model:FindFirstChildAt(3).CFrame = pPart.CFrame * CFrame.new(-0.4, 0.4, -0.6)
        
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
