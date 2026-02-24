-- EggOpening.client.lua
-- Enhanced premium hatching animation with blur, shake, and reveal
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HUDGUI")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggEvent = Remotes:WaitForChild("EggEvent")

-- ── UI Colors ──────────────────────────────────────────────────────────────
local C = {
    bg = Color3.fromRGB(25, 25, 35),
    primary = Color3.fromRGB(255, 200, 50),
    accent = Color3.fromRGB(255, 255, 255),
    error = Color3.fromRGB(255, 80, 80)
}

-- ── Animation Effects ──────────────────────────────────────────────────────
local function CreateBlur()
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting
    TweenService:Create(blur, TweenInfo.new(0.5), {Size = 24}):Play()
    return blur
end

local function RemoveBlur(blur)
    local t = TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0})
    t:Play()
    t.Completed:Connect(function() blur:Destroy() end)
end

-- ── Core UI Screens ────────────────────────────────────────────────────────
local function CreateEggReveal(petData)
    local revealFrame = Instance.new("Frame")
    revealFrame.Size = UDim2.fromScale(1, 1)
    revealFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    revealFrame.BackgroundTransparency = 1
    revealFrame.ZIndex = 2000
    revealFrame.Parent = gui
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 1
    flash.ZIndex = 2005
    flash.Parent = revealFrame

    -- Egg Model Wrapper
    local eggModel = Instance.new("Part")
    eggModel.Size = Vector3.new(4, 5, 4)
    eggModel.Shape = Enum.PartType.Ball
    eggModel.Color = Color3.fromRGB(255, 255, 255)
    eggModel.Material = Enum.Material.Neon
    eggModel.Transparency = 1
    
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromOffset(400, 400)
    viewport.Position = UDim2.fromScale(0.5, 0.5)
    viewport.AnchorPoint = Vector2.new(0.5, 0.5)
    viewport.BackgroundTransparency = 1
    viewport.ZIndex = 2010
    viewport.Parent = revealFrame
    
    local cam = Instance.new("Camera")
    cam.CFrame = CFrame.new(Vector3.new(0, 0, 10), Vector3.new(0, 0, 0))
    viewport.CurrentCamera = cam
    eggModel.Parent = viewport
    eggModel.CFrame = CFrame.new(0, 0, 0)
    
    -- Animation Logic
    task.spawn(function()
        -- Fade in black overlay
        TweenService:Create(revealFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
        task.wait(0.5)
        
        -- Show Egg and Shake
        eggModel.Transparency = 0
        for i = 1, 20 do
            local offset = Vector3.new(math.random(-5, 5)/10, math.random(-5, 5)/10, 0)
            eggModel.CFrame = CFrame.new(offset)
            task.wait(0.05)
        end
        
        -- FLASH Reveal
        TweenService:Create(flash, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
        task.wait(0.1)
        
        -- Swap Egg for Pet
        eggModel.Color = petData.pet.color or Color3.new(1,1,1)
        eggModel.Size = Vector3.new(5, 5, 5) -- Bigger reveal
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 100)
        label.Position = UDim2.new(0, 0, 0.8, 0)
        label.BackgroundTransparency = 1
        label.Text = "YOU GOT: " .. petData.pet.name:upper()
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBlack
        label.TextSize = 42
        label.ZIndex = 2020
        label.Parent = revealFrame
        
        TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        task.wait(3)
        
        -- Cleanup
        TweenService:Create(revealFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        task.wait(0.5)
        revealFrame:Destroy()
    end)
end

-- ── Listener ───────────────────────────────────────────────────────────────
EggEvent.OnClientEvent:Connect(function(action, data)
    if action == "EGG_OPENED" then
        local blur = CreateBlur()
        CreateEggReveal(data)
        task.delay(4, function() RemoveBlur(blur) end)
    elseif action == "ERROR" then
        warn("🥚 Egg Error: "..tostring(data))
    end
end)

print("✅ Enhanced EggOpening System Active")
