-- PetFollow.client.lua
-- Handles smooth, bobbing pet followers for a premium simulator experience
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")

local activePets = {} -- Map of model instances
local petAttachments = {} -- Current offsets

-- ── Configuration ──────────────────────────────────────────────────────────
local FOLLOW_SPEED = 12
local BOB_SPEED = 2
local BOB_HEIGHT = 0.5
local ROTATION_SPEED = 30
local CIRCLE_RADIUS = 5

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
    model.Parent = workspace:WaitForChild("CurrentCamera") -- Invisible to others but easy to manage
    return model
end

local function UpdatePetPositions(dt)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local t = tick()
    
    local i = 0
    local equippedCount = 0
    for _ in pairs(activePets) do equippedCount = equippedCount + 1 end
    
    for petId, model in pairs(activePets) do
        local angle = (t * ROTATION_SPEED) + (i * (360 / equippedCount))
        local rad = math.rad(angle)
        
        -- Target position in a circle around player
        local targetOffset = Vector3.new(
            math.cos(rad) * CIRCLE_RADIUS,
            math.sin(t * BOB_SPEED) * BOB_HEIGHT + 2, -- Bobbing
            math.sin(rad) * CIRCLE_RADIUS
        )
        
        local targetPos = root.Position + targetOffset
        player.CameraMinZoomDistance = 5 -- Prevent camera clipping
        
        -- Smooth interpolation
        model.PrimaryPart.CFrame = model.PrimaryPart.CFrame:Lerp(CFrame.new(targetPos, root.Position), dt * FOLLOW_SPEED)
        
        -- Update features
        local fwd = model.PrimaryPart.CFrame.LookVector
        local up = model.PrimaryPart.CFrame.UpVector
        local right = model.PrimaryPart.CFrame.RightVector
        
        local pPart = model.PrimaryPart
        model:FindFirstChildAt(2).CFrame = pPart.CFrame * CFrame.new(0.4, 0.4, -0.6) -- Eye L
        model:FindFirstChildAt(3).CFrame = pPart.CFrame * CFrame.new(-0.4, 0.4, -0.6) -- Eye R
        
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

RunService.Heartbeat:Connect(UpdatePetPositions)

player.CharacterAdded:Connect(function(char) character = char end)
