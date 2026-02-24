-- RollController - Client-side rolling UI with slot-machine animation
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config    = require(ReplicatedStorage.Shared.Config)
local Utils     = require(ReplicatedStorage.Shared.Utils)
local C         = Config.COLORS

-- Remotes
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local RollEvent       = Remotes:WaitForChild("RollEvent")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")
local AuraEquipEvent  = Remotes:WaitForChild("AuraEquipEvent")

-- State
local currentAura  = nil
local currentLuck  = 1
local isRolling    = false
local autoRollOn   = false
local autoConn     = nil

local uiElements   = {}
local RollController = {}

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────
local RARITY_ORDER = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Godlike=7, Secret=8 }

local function GetRarityConfig(rarity)
    return Config.RARITIES[rarity] or { color = C.gray }
end

-- Quick screen flash for dramatic reveals
local function ScreenFlash(color, duration)
    local overlay = Instance.new("Frame")
    overlay.Size                  = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3      = color
    overlay.BackgroundTransparency = 0.2
    overlay.BorderSizePixel       = 0
    overlay.ZIndex                = 20
    overlay.Parent                = playerGui:WaitForChild("RollUI")

    TweenService:Create(overlay, TweenInfo.new(duration or 0.5), {
        BackgroundTransparency = 1
    }):Play()

    task.delay(duration or 0.5, function()
        if overlay.Parent then overlay:Destroy() end
    end)
end

-- Shockwave ring that expands outward
local function ShockwaveRing(color)
    local ring = Instance.new("Frame")
    ring.AnchorPoint          = Vector2.new(0.5, 0.5)
    ring.Size                 = UDim2.new(0, 10, 0, 10)
    ring.Position             = UDim2.new(0.5, 0, 0.5, 0)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel      = 0
    ring.ZIndex               = 19

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local stroke = Instance.new("UIStroke")
    stroke.Color     = color
    stroke.Thickness = 6
    stroke.Parent    = ring

    ring.Parent = playerGui:WaitForChild("RollUI")

    TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 600, 0, 600),
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.6), { Transparency = 1 }):Play()

    task.delay(0.7, function()
        if ring.Parent then ring:Destroy() end
    end)
end

-- ─────────────────────────────────────────────
-- Notification toast (stacking)
-- ─────────────────────────────────────────────
local toastQueue = {}
local TOAST_HEIGHT = 55
local TOAST_PAD    = 8

local function PushToast(text, color)
    color = color or C.light

    local gui = playerGui:WaitForChild("RollUI")
    local n = Instance.new("Frame")
    n.Name                  = "Toast"
    n.Size                  = UDim2.new(0, 320, 0, 48)
    n.Position              = UDim2.new(0.5, -160, 0, -60)
    n.BackgroundColor3      = C.darker
    n.BackgroundTransparency = 0.1
    n.BorderSizePixel       = 0
    n.ZIndex                = 15
    n.Parent                = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = n

    local stroke = Instance.new("UIStroke")
    stroke.Color     = color
    stroke.Thickness = 2
    stroke.Parent    = n

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, -16, 1, 0)
    lbl.Position            = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = text
    lbl.TextColor3          = color
    lbl.TextSize            = 15
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextWrapped         = true
    lbl.Parent              = n

    table.insert(toastQueue, n)
    local idx = #toastQueue

    -- Slide down from top-right area, stacking
    local targetY = 24 + (idx - 1) * (TOAST_HEIGHT + TOAST_PAD)
    TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -160, 0, targetY)
    }):Play()

    task.delay(3.5, function()
        TweenService:Create(n, TweenInfo.new(0.25), {
            Position = UDim2.new(0.5, -160, 0, -60)
        }):Play()
        task.wait(0.3)
        if n.Parent then n:Destroy() end

        -- Remove from queue and shift others up
        for i, t in ipairs(toastQueue) do
            if t == n then table.remove(toastQueue, i) break end
        end
        for i, t in ipairs(toastQueue) do
            if t and t.Parent then
                TweenService:Create(t, TweenInfo.new(0.2), {
                    Position = UDim2.new(0.5, -160, 0, 24 + (i-1)*(TOAST_HEIGHT+TOAST_PAD))
                }):Play()
            end
        end
    end)
end

-- ─────────────────────────────────────────────
-- Create UI
-- ─────────────────────────────────────────────
function RollController:CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name          = "RollUI"
    screenGui.ResetOnSpawn  = false
    screenGui.DisplayOrder  = 5
    screenGui.Parent        = playerGui

    -- ── Main Panel (center bottom) ──
    local panel = Instance.new("Frame")
    panel.Name                  = "MainPanel"
    panel.Size                  = UDim2.new(0, 420, 0, 270)
    panel.Position              = UDim2.new(0.5, -210, 1, -290)
    panel.BackgroundColor3      = C.dark
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel       = 0
    panel.Parent                = screenGui

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(60, 65, 80)
    stroke.Thickness = 1.5
    stroke.Parent    = panel

    uiElements.panel = panel

    -- ── Title ──
    local title = Instance.new("TextLabel")
    title.Size               = UDim2.new(1, 0, 0, 38)
    title.BackgroundTransparency = 1
    title.Text               = "🎲  AURA  ROLLER"
    title.TextColor3         = C.primary
    title.TextSize           = 22
    title.Font               = Enum.Font.GothamBlack
    title.Parent             = panel

    -- ── Slot Machine Result Frame ──
    local slotFrame = Instance.new("Frame")
    slotFrame.Name               = "SlotFrame"
    slotFrame.Size               = UDim2.new(1, -20, 0, 80)
    slotFrame.Position           = UDim2.new(0, 10, 0, 42)
    slotFrame.BackgroundColor3   = C.darker
    slotFrame.BorderSizePixel    = 0
    slotFrame.ClipsDescendants   = true
    slotFrame.Parent             = panel

    Instance.new("UICorner", slotFrame).CornerRadius = UDim.new(0, 10)

    local slotStroke = Instance.new("UIStroke")
    slotStroke.Color     = C.gray
    slotStroke.Thickness = 1
    slotStroke.Parent    = slotFrame

    -- The label inside the slot that cycles
    local slotLabel = Instance.new("TextLabel")
    slotLabel.Name               = "SlotLabel"
    slotLabel.Size               = UDim2.new(1, 0, 1, 0)
    slotLabel.BackgroundTransparency = 1
    slotLabel.Text               = "Press SPACE or tap to roll!"
    slotLabel.TextColor3         = C.gray
    slotLabel.TextSize           = 24
    slotLabel.Font               = Enum.Font.GothamBold
    slotLabel.Parent             = slotFrame

    uiElements.slotFrame = slotFrame
    uiElements.slotLabel = slotLabel

    -- ── Equipped Aura label ──
    local equippedRow = Instance.new("Frame")
    equippedRow.Size               = UDim2.new(1, -20, 0, 24)
    equippedRow.Position           = UDim2.new(0, 10, 0, 128)
    equippedRow.BackgroundTransparency = 1
    equippedRow.Parent             = panel

    local equippedTitle = Instance.new("TextLabel")
    equippedTitle.Size               = UDim2.new(0.45, 0, 1, 0)
    equippedTitle.BackgroundTransparency = 1
    equippedTitle.Text               = "EQUIPPED"
    equippedTitle.TextColor3         = C.gray
    equippedTitle.TextSize           = 12
    equippedTitle.Font               = Enum.Font.GothamBold
    equippedTitle.TextXAlignment     = Enum.TextXAlignment.Left
    equippedTitle.Parent             = equippedRow

    local equippedName = Instance.new("TextLabel")
    equippedName.Name               = "EquippedName"
    equippedName.Size               = UDim2.new(0.55, 0, 1, 0)
    equippedName.Position           = UDim2.new(0.45, 0, 0, 0)
    equippedName.BackgroundTransparency = 1
    equippedName.Text               = "Glowing"
    equippedName.TextColor3         = C.light
    equippedName.TextSize           = 12
    equippedName.Font               = Enum.Font.GothamBold
    equippedName.TextXAlignment     = Enum.TextXAlignment.Right
    equippedName.Parent             = equippedRow

    uiElements.equippedName = equippedName

    -- ── Stats row ──
    local statsRow = Instance.new("Frame")
    statsRow.Size               = UDim2.new(1, -20, 0, 24)
    statsRow.Position           = UDim2.new(0, 10, 0, 154)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent             = panel

    local function MakeStat(parent, name, icon, pos)
        local lbl = Instance.new("TextLabel")
        lbl.Name               = name
        lbl.Size               = UDim2.new(0.33, 0, 1, 0)
        lbl.Position           = UDim2.new(pos, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text               = icon
        lbl.TextColor3         = C.gray
        lbl.TextSize           = 13
        lbl.Font               = Enum.Font.GothamBold
        lbl.Parent             = parent
        return lbl
    end

    uiElements.rollsLabel = MakeStat(statsRow, "RollsLabel", "🎲  Rolls: 0",   0)
    uiElements.luckLabel  = MakeStat(statsRow, "LuckLabel",  "🍀  1.00x",      0.33)
    uiElements.gemsLabel  = MakeStat(statsRow, "GemsLabel",  "💎  100",        0.66)
    uiElements.gemsLabel.TextXAlignment  = Enum.TextXAlignment.Right
    uiElements.luckLabel.TextColor3      = C.success
    uiElements.gemsLabel.TextColor3      = C.primary

    -- ── Roll Button ──
    local rollBtn = Instance.new("TextButton")
    rollBtn.Name               = "RollButton"
    rollBtn.Size               = UDim2.new(1, -20, 0, 58)
    rollBtn.Position           = UDim2.new(0, 10, 0, 188)
    rollBtn.BackgroundColor3   = C.primary
    rollBtn.Text               = "🎲  ROLL AURA  [ SPACE ]"
    rollBtn.TextColor3         = C.dark
    rollBtn.TextSize           = 20
    rollBtn.Font               = Enum.Font.GothamBlack
    rollBtn.AutoButtonColor    = false
    rollBtn.Parent             = panel

    Instance.new("UICorner", rollBtn).CornerRadius = UDim.new(0, 10)

    -- Hover effects
    rollBtn.MouseEnter:Connect(function()
        if not isRolling then
            TweenService:Create(rollBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(255, 215, 80)
            }):Play()
        end
    end)
    rollBtn.MouseLeave:Connect(function()
        if not isRolling then
            TweenService:Create(rollBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = C.primary
            }):Play()
        end
    end)
    rollBtn.MouseButton1Click:Connect(function()
        self:DoRoll()
    end)

    uiElements.rollBtn = rollBtn

    -- ── Auto Roll Toggle ──
    local autoBtn = Instance.new("TextButton")
    autoBtn.Name               = "AutoBtn"
    autoBtn.Size               = UDim2.new(0, 100, 0, 26)
    autoBtn.Position           = UDim2.new(1, -110, 0, 6)
    autoBtn.BackgroundColor3   = C.darker
    autoBtn.Text               = "AUTO: OFF"
    autoBtn.TextColor3         = C.gray
    autoBtn.TextSize           = 11
    autoBtn.Font               = Enum.Font.GothamBold
    autoBtn.Parent             = panel

    Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

    autoBtn.MouseButton1Click:Connect(function()
        self:ToggleAutoRoll()
    end)

    uiElements.autoBtn = autoBtn

    -- ── Inventory / Pet buttons (corner) ──
    local openInv = Instance.new("TextButton")
    openInv.Size               = UDim2.new(0, 80, 0, 26)
    openInv.Position           = UDim2.new(0, 10, 0, 6)
    openInv.BackgroundColor3   = C.darker
    openInv.Text               = "🎒 INV [I]"
    openInv.TextColor3         = C.light
    openInv.TextSize           = 11
    openInv.Font               = Enum.Font.GothamBold
    openInv.Parent             = panel
    Instance.new("UICorner", openInv).CornerRadius = UDim.new(0, 6)

    -- Keyboard
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Space then
            self:DoRoll()
        end
    end)
end

-- ─────────────────────────────────────────────
-- Slot machine animation then show result
-- ─────────────────────────────────────────────
function RollController:PlaySlotAnimation(duration, onDone)
    local lbl        = uiElements.slotLabel
    local frameCount = 0
    local interval   = 0.04 -- fast at first

    local function Tick()
        -- Pick a random aura to flash
        local r = Config.AURAS[math.random(1, #Config.AURAS)]
        local rc = GetRarityConfig(r.rarity)
        lbl.Text       = r.name
        lbl.TextColor3 = rc.color
        frameCount     = frameCount + 1
    end

    -- Heartbeat-driven variable speed cycling
    local start = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - start
        if elapsed >= duration then
            conn:Disconnect()
            if onDone then task.spawn(onDone) end
            return
        end

        -- Slow down as we approach the end
        local progress = elapsed / duration
        interval = 0.04 + progress * 0.25

        if (tick() % interval) < 0.02 then
            Tick()
        end
    end)
end

-- ─────────────────────────────────────────────
-- Reveal result with per-rarity impact
-- ─────────────────────────────────────────────
function RollController:RevealResult(aura)
    local lbl      = uiElements.slotLabel
    local slotFrame = uiElements.slotFrame
    local rc       = GetRarityConfig(aura.rarity)
    local rarityIdx = RARITY_ORDER[aura.rarity] or 1

    -- Show result name
    lbl.Text       = aura.name
    lbl.TextColor3 = rc.color
    lbl.TextSize   = 26

    -- Update slot border to rarity color
    local st = slotFrame:FindFirstChildOfClass("UIStroke")
    if st then
        TweenService:Create(st, TweenInfo.new(0.3), { Color = rc.color, Thickness = 2 }):Play()
    end

    -- Slam punch: scale in
    slotFrame.Size = UDim2.new(1, -20, 0, 70)
    TweenService:Create(slotFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, -20, 0, 84)
    }):Play()

    -- Per-rarity effects based on how rare
    if rarityIdx >= 7 then           -- Godlike / Secret
        ScreenFlash(rc.color, 0.6)
        for i = 1, 3 do
            task.delay(i * 0.08, function() ShockwaveRing(rc.color) end)
        end
    elseif rarityIdx >= 5 then       -- Legendary / Mythic
        ScreenFlash(rc.color, 0.35)
        ShockwaveRing(rc.color)
    elseif rarityIdx >= 3 then       -- Rare / Epic
        ShockwaveRing(rc.color)
    end

    -- Label pulse: grow then shrink
    lbl.TextSize = 18
    TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextSize = 30
    }):Play()
    task.delay(0.4, function()
        TweenService:Create(lbl, TweenInfo.new(0.15), { TextSize = 24 }):Play()
    end)

    -- Stat update
    self:UpdateAuraDisplay(aura)

    -- Notification
    local msg = string.format("✨ %s  ·  %s", aura.name, aura.rarity)
    PushToast(msg, rc.color)
end

-- ─────────────────────────────────────────────
-- Perform roll
-- ─────────────────────────────────────────────
function RollController:DoRoll()
    if isRolling then return end
    isRolling = true

    -- Dim button
    uiElements.rollBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 30)
    uiElements.rollBtn.Text = "Rolling..."

    -- Start slot animation
    self:PlaySlotAnimation(1.4, function()
        -- Animation done, wait for server result
        -- (server response handled in ConnectEvents)
    end)

    -- Fire server
    RollEvent:FireServer()

    -- Safety timeout
    task.delay(6, function()
        if isRolling then
            isRolling = false
            self:ResetRollButton()
        end
    end)
end

function RollController:ResetRollButton()
    uiElements.rollBtn.BackgroundColor3 = C.primary
    uiElements.rollBtn.Text = "🎲  ROLL AURA  [ SPACE ]"
    uiElements.slotLabel.TextSize = 18
end

-- ─────────────────────────────────────────────
-- Auto Roll
-- ─────────────────────────────────────────────
function RollController:ToggleAutoRoll()
    autoRollOn = not autoRollOn
    local btn = uiElements.autoBtn

    if autoRollOn then
        btn.BackgroundColor3 = C.success
        btn.TextColor3       = C.dark
        btn.Text             = "AUTO: ON"

        autoConn = task.spawn(function()
            while autoRollOn do
                if not isRolling then
                    self:DoRoll()
                end
                task.wait(0.7)
            end
        end)
    else
        btn.BackgroundColor3 = C.darker
        btn.TextColor3       = C.gray
        btn.Text             = "AUTO: OFF"
        autoRollOn = false
    end
end

-- ─────────────────────────────────────────────
-- Update displays
-- ─────────────────────────────────────────────
function RollController:UpdateAuraDisplay(aura)
    currentAura = aura
    local rc = GetRarityConfig(aura.rarity)
    uiElements.equippedName.Text       = aura.name
    uiElements.equippedName.TextColor3 = rc.color
end

function RollController:UpdateStats(data)
    if data.totalLuck then
        currentLuck = data.totalLuck
        uiElements.luckLabel.Text = string.format("🍀  %s", Utils.FormatLuck(currentLuck))
    end
    if data.rollCount ~= nil then
        uiElements.rollsLabel.Text = string.format("🎲  %s", Utils.FormatNumber(data.rollCount))
    end
    if data.gems ~= nil then
        uiElements.gemsLabel.Text = string.format("💎  %s", Utils.FormatNumber(data.gems))
    end
end

-- ─────────────────────────────────────────────
-- Connect all remotes
-- ─────────────────────────────────────────────
function RollController:ConnectEvents()
    -- Roll result from server
    RollEvent.OnClientEvent:Connect(function(result, aura)
        isRolling = false
        self:ResetRollButton()

        if result == "SUCCESS" and aura then
            self:RevealResult(aura)
        else
            uiElements.slotLabel.Text       = "No result!"
            uiElements.slotLabel.TextColor3 = C.danger
        end
    end)

    -- Data sync from server
    DataUpdateEvent.OnClientEvent:Connect(function(eventType, data)
        if eventType == "SYNC" then
            self:UpdateStats(data)
            if data.equippedAura then
                self:UpdateAuraDisplay(data.equippedAura)
            end
        elseif eventType == "RARE_ROLL" then
            -- Someone else got a rare+
            PushToast(
                string.format("🔥 %s rolled %s!", data.playerName, data.auraName),
                data.color
            )
        end
    end)
end

-- ─────────────────────────────────────────────
-- Init
-- ─────────────────────────────────────────────
function RollController:Init()
    self:CreateUI()
    self:ConnectEvents()
    print("✅ Roll Controller Initialized")
end

RollController:Init()
return RollController
