-- HUD.client.lua  ·  Unified Responsive Aura Roller Interface
print("🖥️ [HUD] ACTIVATED - Syncing version: "..tick())
-- Replaces: RollController, InventoryUI, PetUI
-- Layout: Scale-based UDim2 throughout for full screen-size independence

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config    = require(ReplicatedStorage.Shared.Config)
local Utils     = require(ReplicatedStorage.Shared.Utils)

-- ── Remotes ────────────────────────────────────────────────────────────────
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local RollEvent       = Remotes:WaitForChild("RollEvent")
local DataUpdateEvent = Remotes:WaitForChild("DataUpdateEvent")
local InventoryEvent  = Remotes:WaitForChild("InventoryEvent")
local EquipPetEvent   = Remotes:WaitForChild("EquipPetEvent")
local ShopEvent       = Remotes:WaitForChild("ShopEvent")

-- ── Theme ──────────────────────────────────────────────────────────────────
local T = {
    bg      = Color3.fromRGB(10, 13, 22),
    panel   = Color3.fromRGB(16, 21, 34),
    card    = Color3.fromRGB(22, 29, 46),
    sidebar = Color3.fromRGB(8, 11, 20),
    border  = Color3.fromRGB(40, 48, 70),
    gold    = Color3.fromRGB(255, 200, 50),
    green   = Color3.fromRGB(55, 210, 100),
    red     = Color3.fromRGB(255, 65, 65),
    blue    = Color3.fromRGB(80, 145, 255),
    gray    = Color3.fromRGB(95, 108, 135),
    white   = Color3.fromRGB(225, 232, 248),
    purple  = Color3.fromRGB(175, 75, 255),
}

-- ── State ──────────────────────────────────────────────────────────────────
local St = {
    rolling      = false,
    autoRoll     = false,
    autoConn     = nil,
    luck         = 1,
    gems         = 100,
    rolls        = 0,
    equippedAura = nil,
    equippedPets = {},
    allPets      = {},
    inventory    = {},
    activePanel  = nil,   -- "inv"|"pets"|"shop"|"settings"|nil
    sidebarOpen  = true,
    filter       = "All",
    selAura      = nil,
    autoEquip    = false,
    sfx          = true,
    boostExpiry  = {},    -- itemId -> expiry tick()
    power        = 0,
    pendingAura  = nil,
}

local RARITY_ORDER = {Secret=1,Godlike=2,Mythic=3,Legendary=4,Epic=5,Rare=6,Uncommon=7,Common=8}
local PET_ICONS    = {skibidi="🚽",sigma="💪",ohio="👹",grimace="🥤",fanum="💰",quandale="🐢",gronk="👶",rizzler="✨"}

-- ── Builder helpers ────────────────────────────────────────────────────────
local function RC(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p
end
local function STK(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or T.border; s.Thickness = th or 1.5; s.Parent = p
end
local function Pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 8)
    u.PaddingRight  = UDim.new(0, r or 8)
    u.PaddingBottom = UDim.new(0, b or 8)
    u.PaddingLeft   = UDim.new(0, l or 8)
    u.Parent        = p
end

local function MkFrame(props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k]=v end
    return f
end

local function MkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font      = Enum.Font.GothamBold
    l.TextColor3 = T.white
    l.TextScaled = true
    for k,v in pairs(props) do l[k]=v end
    return l
end

local function MkBtn(props, onClick)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font      = Enum.Font.GothamBold
    b.TextColor3 = T.white
    b.TextScaled = true
    local origColor = props.BackgroundColor3 or T.card
    for k,v in pairs(props) do b[k]=v end
    if onClick then b.MouseButton1Click:Connect(onClick) end
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = origColor:Lerp(Color3.new(1,1,1), 0.15)
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = origColor }):Play()
    end)
    return b
end

-- ── Toast queue ─────────────────────────────────────────────────────────────
local toasts = {}
local TOAST_H = 52
local TOAST_G = 6

local function Toast(text, color)
    color = color or T.white
    local gui = playerGui:FindFirstChild("HUDGUI")
    if not gui then return end

    local n = MkFrame({
        Size = UDim2.new(0.28, 0, 0, TOAST_H),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -70),
        BackgroundColor3 = T.panel,
        BackgroundTransparency = 0.05,
        ZIndex = 40,
        Parent = gui,
    })
    RC(n, 10) ; STK(n, color, 2)

    local l = MkLabel({
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = text, TextColor3 = color,
        TextScaled = true,
        ZIndex = 41,
        Parent = n,
    })
    Instance.new("UITextSizeConstraint", l).MaxTextSize = 16

    table.insert(toasts, n)
    local idx = #toasts
    TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0, 16 + (idx-1)*(TOAST_H+TOAST_G))
    }):Play()

    task.delay(3.5, function()
        TweenService:Create(n, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, 0, 0, -70)
        }):Play()
        task.wait(0.22)
        if n.Parent then n:Destroy() end
        for i, t in ipairs(toasts) do
            if t == n then table.remove(toasts, i) break end
        end
        for i, t in ipairs(toasts) do
            if t and t.Parent then
                TweenService:Create(t, TweenInfo.new(0.15), {
                    Position = UDim2.new(0.5, 0, 0, 16 + (i-1)*(TOAST_H+TOAST_G))
                }):Play()
            end
        end
    end)
end

-- ── Screen-flash + shockwave helpers ──────────────────────────────────────
local function Flash(color, dur)
    local gui = playerGui:FindFirstChild("HUDGUI")
    if not gui then return end
    local f = MkFrame({
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.25,
        ZIndex = 50, Parent = gui,
    })
    TweenService:Create(f, TweenInfo.new(dur or 0.5), {BackgroundTransparency=1}):Play()
    task.delay(dur or 0.5, function() if f.Parent then f:Destroy() end end)
end

local function Ring(color)
    local gui = playerGui:FindFirstChild("HUDGUI")
    if not gui then return end
    local r = MkFrame({
        Size = UDim2.fromOffset(8,8),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundTransparency = 1,
        ZIndex = 49, Parent = gui,
    })
    RC(r, 400)
    STK(r, color, 5)
    TweenService:Create(r, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(800, 800),
    }):Play()
    local s = r:FindFirstChildOfClass("UIStroke")
    if s then TweenService:Create(s, TweenInfo.new(0.55), {Transparency=1}):Play() end
    task.delay(0.6, function() if r.Parent then r:Destroy() end end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN GUI CREATION
-- ═══════════════════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name           = "HUDGUI"
gui.ResetOnSpawn   = false
gui.DisplayOrder   = 5
gui.IgnoreGuiInset = false
gui.Parent         = playerGui

-- ── Sidebar (right edge) ──────────────────────────────────────────────────
local SIDEBAR_W = 58

local sidebar = MkFrame({
    Name = "Sidebar",
    Size = UDim2.new(0, SIDEBAR_W, 0.65, 0),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.46, 0),
    BackgroundColor3 = T.sidebar,
    BackgroundTransparency = 0.05,
    ZIndex = 20,
    Parent = gui,
})
RC(sidebar, 14) ; STK(sidebar)

local sideLayout = Instance.new("UIListLayout")
sideLayout.FillDirection      = Enum.FillDirection.Vertical
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
sideLayout.Padding             = UDim.new(0, 6)
sideLayout.Parent              = sidebar
Pad(sidebar, 8, 6, 8, 6)

-- ── Side panel (slides in left of sidebar) ────────────────────────────────
local sidePanel = MkFrame({
    Name = "SidePanel",
    Size = UDim2.new(0.36, 0, 0.78, 0),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -(SIDEBAR_W+14), 0.46, 0),
    BackgroundColor3 = T.panel,
    BackgroundTransparency = 0.05,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 18,
    Parent = gui,
})
RC(sidePanel, 14) ; STK(sidePanel)

-- ── Top-Left Player Stats (Power & Luck) ──────────────────────────────────
local statsPanel = MkFrame({
    Name = "TopStats",
    Size = UDim2.new(0.2, 0, 0, 80),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = T.panel,
    BackgroundTransparency = 0.1,
    ZIndex = 25,
    Parent = gui,
})
RC(statsPanel, 12) ; STK(statsPanel)
Pad(statsPanel, 8, 12, 8, 12)

local statsPanelLayout = Instance.new("UIListLayout")
statsPanelLayout.Padding = UDim.new(0, 4)
statsPanelLayout.Parent = statsPanel

local nameLabel = MkLabel({
    Size = UDim2.new(1, 0, 0, 22),
    Text = player.Name,
    TextColor3 = T.white,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 26, Parent = statsPanel,
})
Instance.new("UITextSizeConstraint", nameLabel).MaxTextSize = 16

local powerLabel = MkLabel({
    Name = "PowerLabel",
    Size = UDim2.new(1, 0, 0, 24),
    Text = "POWER: 0",
    TextColor3 = T.purple,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 26, Parent = statsPanel,
})
Instance.new("UITextSizeConstraint", powerLabel).MaxTextSize = 18

local luckLabel = MkLabel({
    Name = "LuckLabel",
    Size = UDim2.new(1, 0, 0, 18),
    Text = "LUCK: 1.00x",
    TextColor3 = T.green,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 26, Parent = statsPanel,
})
Instance.new("UITextSizeConstraint", luckLabel).MaxTextSize = 14

-- ── Gems Display (Top Right) ────────────────────────────────────────────────
local gemsGui = MkFrame({
    Name = "GemsGui",
    Size = UDim2.new(0.12, 0, 0.06, 0),
    Position = UDim2.new(0.98, 0, 0.02, 0),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = T.panel,
    ZIndex = 30,
    Parent = gui,
})
RC(gemsGui, 12) ; STK(gemsGui, T.gold)
Pad(gemsGui, 0, 10, 0, 10)

local gemsLbl = MkLabel({
    Name = "GemsLabel",
    Size = UDim2.fromScale(1, 1),
    Text = "💎 9,999",
    TextColor3 = T.gold,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = gemsGui,
})
Instance.new("UITextSizeConstraint", gemsLbl).MaxTextSize = 22

-- ── Roll Panel (bottom-center, always visible) ────────────────────────────
local rollPanel = MkFrame({
    Name = "RollPanel",
    Size = UDim2.new(0.34, 0, 0.3, 0),
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -10),
    BackgroundColor3 = T.panel,
    BackgroundTransparency = 0, -- Fix transparency issue
    ZIndex = 30, -- Bring to front
    Parent = gui,
})
RC(rollPanel, 14) ; STK(rollPanel)
Pad(rollPanel, 10, 12, 10, 12)

local rollLayout = Instance.new("UIListLayout")
rollLayout.FillDirection       = Enum.FillDirection.Vertical
rollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rollLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
rollLayout.Padding             = UDim.new(0.02, 0)
rollLayout.Parent              = rollPanel

-- Title row
local titleRow = MkFrame({
    Name = "TitleRow",
    Size = UDim2.new(1, 0, 0.12, 0),
    BackgroundTransparency = 1,
    LayoutOrder = 1, Parent = rollPanel,
})
local titleRowL = Instance.new("UIListLayout")
titleRowL.FillDirection = Enum.FillDirection.Horizontal
titleRowL.VerticalAlignment = Enum.VerticalAlignment.Center
titleRowL.HorizontalAlignment = Enum.HorizontalAlignment.Center
titleRowL.Padding = UDim.new(0.04, 0)
titleRowL.Parent = titleRow

local rollTitle = MkLabel({
    Name="RollTitle", Size = UDim2.new(0.55, 0, 1, 0),
    Text = "🎲  AURA ROLLER", TextColor3 = T.gold,
    Font = Enum.Font.GothamBlack, LayoutOrder=1, Parent = titleRow,
})
Instance.new("UITextSizeConstraint", rollTitle).MaxTextSize = 22

-- Auto toggle btn
local autoBtn = MkBtn({
    Name="AutoBtn", Size = UDim2.new(0.22, 0, 1, 0),
    BackgroundColor3 = T.card,
    Text = "AUTO: OFF", TextColor3 = T.gray,
    LayoutOrder = 2, Parent = titleRow,
}, nil)
Instance.new("UITextSizeConstraint", autoBtn).MaxTextSize = 13
RC(autoBtn, 6)

-- Slot display
local slotFrame = MkFrame({
    Name = "SlotFrame",
    Size = UDim2.new(1, 0, 0.32, 0),
    BackgroundColor3 = T.bg,
    ClipsDescendants = true,
    LayoutOrder = 2, Parent = rollPanel,
})
RC(slotFrame, 10) ; STK(slotFrame, T.border)

local slotLabel = MkLabel({
    Name = "SlotLabel",
    Size = UDim2.fromScale(1, 1),
    Text = "Press R to roll!",
    TextColor3 = T.white,
    Font = Enum.Font.GothamBlack,
    ZIndex = 32,
    Parent = slotFrame,
})
Instance.new("UITextSizeConstraint", slotLabel).MaxTextSize = 28

-- Equipped / stats row
local statsRow = MkFrame({
    Name="StatsRow", Size=UDim2.new(1,0,0.14,0),
    BackgroundTransparency=1, LayoutOrder=3, Parent=rollPanel,
})
local statsL = Instance.new("UIListLayout")
statsL.FillDirection = Enum.FillDirection.Horizontal
statsL.VerticalAlignment = Enum.VerticalAlignment.Center
statsL.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsL.Padding = UDim.new(0.04,0)
statsL.Parent = statsRow

local function StatLbl(name, text, color, order)
    local l = MkLabel({
        Name=name, Size=UDim2.new(0.3,0,1,0),
        Text=text, TextColor3=color or T.gray,
        LayoutOrder=order, Parent=statsRow,
    })
    Instance.new("UITextSizeConstraint", l).MaxTextSize = 15
    return l
end
local lblRolls    = StatLbl("RollsLbl","🎲 0",     T.gray,  1)
local lblLuck     = StatLbl("LuckLbl", "🍀 1.00x", T.green, 2)
local lblGems     = StatLbl("GemsLbl", "💎 100",   T.gold,  3)

-- Equipped row
local eqRow = MkFrame({
    Name="EqRow", Size=UDim2.new(1,0,0.1,0),
    BackgroundTransparency=1, LayoutOrder=4, Parent=rollPanel,
})
local eqL = Instance.new("UIListLayout")
eqL.FillDirection=Enum.FillDirection.Horizontal
eqL.VerticalAlignment=Enum.VerticalAlignment.Center
eqL.Padding=UDim.new(0.02,0)
eqL.Parent=eqRow

local eqTitleLbl = MkLabel({
    Size=UDim2.new(0.3,0,1,0), Text="EQUIPPED",
    TextColor3=T.gray, LayoutOrder=1, Parent=eqRow,
})
Instance.new("UITextSizeConstraint", eqTitleLbl).MaxTextSize = 12

local eqNameLbl = MkLabel({
    Name="EqName", Size=UDim2.new(0.68,0,1,0),
    Text="Glowing", TextColor3=T.white,
    Font=Enum.Font.GothamBlack, LayoutOrder=2, Parent=eqRow,
})
Instance.new("UITextSizeConstraint", eqNameLbl).MaxTextSize = 15

-- Roll button
local rollBtn = MkBtn({
    Name="RollBtn",
    Size=UDim2.new(1,0,0.27,0),
    BackgroundColor3=T.gold,
    Text="🎲  ROLL AURA  [ R ]",
    TextColor3=T.bg,
    Font=Enum.Font.GothamBlack,
    LayoutOrder=5, Parent=rollPanel,
}, nil)
RC(rollBtn, 10)
Instance.new("UITextSizeConstraint", rollBtn).MaxTextSize = 22

-- ════════════════════════════════════════════════════════════════════════════
-- SIDEBAR BUTTONS
-- ════════════════════════════════════════════════════════════════════════════
local panels = {} -- panelId -> Frame content (filled below)
local tabBtns = {}

local TABS = {
    {id="inv",      icon="🎒", tip="Inventory",  key=Enum.KeyCode.I},
    {id="pets",     icon="🐾", tip="Pets",       key=Enum.KeyCode.P},
    {id="shop",     icon="🛒", tip="Shop",       key=Enum.KeyCode.F},
    {id="settings", icon="⚙️", tip="Settings",   key=Enum.KeyCode.Escape},
}

local function SetPanel(id)
    if St.activePanel == id then
        -- Toggle off
        St.activePanel = nil
        sidePanel.Visible = false
        for _, btn in pairs(tabBtns) do
            btn.BackgroundColor3 = T.card
        end
        return
    end
    St.activePanel = id
    sidePanel.Visible = true
    for _, child in ipairs(sidePanel:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child.Visible = false
        end
    end
    if panels[id] then panels[id].Visible = true end
    for tid, btn in pairs(tabBtns) do
        btn.BackgroundColor3 = (tid == id) and T.gold or T.card
        btn.TextColor3       = (tid == id) and T.bg   or T.white
    end
    -- Request data if needed
    if id == "inv" then InventoryEvent:FireServer("GET_INVENTORY") end
end

-- Collapse/expand sidebar button at top
local collapseBtn = MkBtn({
    Size = UDim2.new(1, -8, 0, 36),
    BackgroundColor3 = T.card,
    Text = "❮❮", TextColor3 = T.gray,
    LayoutOrder = 0, Parent = sidebar,
}, function()
    St.sidebarOpen = not St.sidebarOpen
    local targetX = St.sidebarOpen and UDim2.new(1, -8, 0.46, 0) or UDim2.new(1, 22, 0.46, 0)
    TweenService:Create(sidebar, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Position = targetX }):Play()
    collapseBtn.Text = St.sidebarOpen and "❮❮" or "❯❯"
    if not St.sidebarOpen then
        sidePanel.Visible = false
        St.activePanel = nil
    end
end)
RC(collapseBtn, 8)
Instance.new("UITextSizeConstraint", collapseBtn).MaxTextSize = 14

for _, tab in ipairs(TABS) do
    local btn = MkBtn({
        Name = tab.id .. "Tab",
        Size = UDim2.new(1, -8, 0, 44),
        BackgroundColor3 = T.card,
        Text = tab.icon,
        TextScaled = true,
        ZIndex = 21,
        Parent = sidebar,
    }, function() SetPanel(tab.id) end)
    RC(btn, 10)
    Instance.new("UITextSizeConstraint", btn).MaxTextSize = 24
    tabBtns[tab.id] = btn

    -- Tooltip
    local tip = MkLabel({
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, -(100), 0.5, -14),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = T.bg,
        BackgroundTransparency = 0.1,
        Text = tab.tip,
        TextScaled = true,
        ZIndex = 30,
        Visible = false,
        Parent = btn,
    })
    RC(tip, 6) ; STK(tip, T.border)
    Instance.new("UITextSizeConstraint", tip).MaxTextSize = 13

    btn.MouseEnter:Connect(function() tip.Visible = true end)
    btn.MouseLeave:Connect(function() tip.Visible = false end)
end

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Space then
        -- roll handled below
    end
    for _, tab in ipairs(TABS) do
        if inp.KeyCode == tab.key and tab.id ~= "settings" then
            SetPanel(tab.id)
        end
    end
    if inp.KeyCode == Enum.KeyCode.Escape then
        if St.activePanel then
            SetPanel(St.activePanel) -- toggle off
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- PANEL HELPER: creates a scrollable content area with a header
-- ════════════════════════════════════════════════════════════════════════════
local function MakePanelHeader(title, color)
    local hdr = MkFrame({
        Name="Header", Size=UDim2.new(1,0,0,44),
        BackgroundColor3=T.card, ZIndex=19, Parent=sidePanel,
    })
    RC(hdr, 14)
    local lbl = MkLabel({
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,10,0,0),
        Text=title, TextColor3=color or T.gold,
        Font=Enum.Font.GothamBlack, ZIndex=20, Parent=hdr,
    })
    Instance.new("UITextSizeConstraint", lbl).MaxTextSize = 20
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return hdr
end

local function MakeScrollGrid(yOff, cellW, cellH, gapX, gapY)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                  = "Grid"
    scroll.Size                  = UDim2.new(1, 0, 1, -yOff)
    scroll.Position              = UDim2.new(0, 0, 0, yOff)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness    = 4
    scroll.ScrollBarImageColor3  = T.gold
    scroll.ZIndex                = 19
    scroll.Parent                = sidePanel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize    = UDim2.new(0, cellW, 0, cellH)
    grid.CellPadding = UDim2.new(0, gapX, 0, gapY)
    grid.SortOrder   = Enum.SortOrder.LayoutOrder
    grid.Parent      = scroll

    Pad(scroll, 8, 8, 8, 8)
    return scroll, grid
end

-- ════════════════════════════════════════════════════════════════════════════
-- INVENTORY PANEL
-- ════════════════════════════════════════════════════════════════════════════
do
    MakePanelHeader("🎒  INVENTORY")
    local invScroll, invGrid = MakeScrollGrid(50, 90, 106, 8, 8)
    panels.inv = invScroll

    -- Filter row
    local filterRow = MkFrame({
        Name="FilterRow", Size=UDim2.new(1,0,0,40),
        Position=UDim2.new(0,0,0,44),
        BackgroundTransparency=1, ZIndex=19, Parent=sidePanel,
    })
    local fLayout = Instance.new("UIListLayout")
    fLayout.FillDirection=Enum.FillDirection.Horizontal
    fLayout.Padding=UDim.new(0,4)
    fLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    fLayout.Parent=filterRow
    Pad(filterRow, 4, 4, 4, 4)

    local rarityShort = {"All","Com","Unc","Rar","Epi","Leg","Myt","God","Sec"}
    local rarityFull  = {"All","Common","Uncommon","Rare","Epic","Legendary","Mythic","Godlike","Secret"}
    for i, r in ipairs(rarityFull) do
        local rc = Config.RARITIES[r]
        local fb = MkBtn({
            Size=UDim2.new(0,36,0,28),
            BackgroundColor3 = r=="All" and T.gold or T.card,
            Text=rarityShort[i], TextColor3 = r=="All" and T.bg or (rc and rc.color or T.white),
            ZIndex=20, Parent=filterRow,
        }, function()
            St.filter = r
            InventoryEvent:FireServer("GET_INVENTORY")
        end)
        RC(fb, 6)
        Instance.new("UITextSizeConstraint", fb).MaxTextSize = 10
    end

    -- Fill inventory grid
    local function RefreshInventory(rawInv)
        for _, c in ipairs(invScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        -- Stack duplicates
        local counts, order = {}, {}
        for _, item in ipairs(rawInv) do
            if not counts[item.auraId] then
                counts[item.auraId] = 0
                table.insert(order, item.auraId)
            end
            counts[item.auraId] = counts[item.auraId] + 1
        end
        local idx = 0
        for _, id in ipairs(order) do
            local aura
            for _, a in ipairs(Config.AURAS) do if a.id==id then aura=a break end end
            if not aura then continue end
            if St.filter ~= "All" and aura.rarity ~= St.filter then continue end
            idx = idx + 1
            local rc = Config.RARITIES[aura.rarity]

            local card = MkFrame({
                Size=UDim2.new(0,90,0,106),
                BackgroundColor3=T.card, LayoutOrder=idx, ZIndex=20, Parent=invScroll,
            })
            RC(card, 8) ; STK(card, rc and rc.color or T.border, 1.5)

            -- Orb
            local orb = MkFrame({
                Size=UDim2.new(0,54,0,54),
                AnchorPoint=Vector2.new(0.5,0),
                Position=UDim2.new(0.5,0,0,8),
                BackgroundColor3=aura.particleColor or T.gray,
                ZIndex=21, Parent=card,
            })
            RC(orb, 54)

            local icons = {Legendary="⭐",Mythic="🌟",Godlike="👑",Secret="∞"}
            if icons[aura.rarity] then
                local ico = MkLabel({Size=UDim2.fromScale(1,1),Text=icons[aura.rarity],ZIndex=22,Parent=orb})
                Instance.new("UITextSizeConstraint",ico).MaxTextSize=20
            end

            -- Name
            local nl = MkLabel({
                Size=UDim2.new(1,-6,0,22), Position=UDim2.new(0,3,0,66),
                Text=aura.name, TextColor3=rc and rc.color or T.white,
                ZIndex=21, Parent=card,
            })
            Instance.new("UITextSizeConstraint",nl).MaxTextSize=12

            -- Rarity
            local rl = MkLabel({
                Size=UDim2.new(1,-6,0,14), Position=UDim2.new(0,3,0,88),
                Text=aura.rarity, TextColor3=rc and rc.color or T.gray,
                ZIndex=21, Parent=card,
            })
            Instance.new("UITextSizeConstraint",rl).MaxTextSize=10

            -- Count badge
            if counts[id] > 1 then
                local badge = MkFrame({
                    Size=UDim2.new(0,24,0,18), Position=UDim2.new(1,-26,0,4),
                    BackgroundColor3=T.gold, ZIndex=24, Parent=card,
                })
                RC(badge,6)
                local bl = MkLabel({
                    Size=UDim2.fromScale(1,1), Text="x"..counts[id],
                    TextColor3=T.bg, ZIndex=25, Parent=badge,
                })
                Instance.new("UITextSizeConstraint",bl).MaxTextSize=11
            end

            -- Click to equip
            local overBtn = MkBtn({
                Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
                Text="", ZIndex=23, Parent=card,
            }, function()
                InventoryEvent:FireServer("EQUIP_AURA", aura.id)
                Toast("Equipping " .. aura.name .. "...", rc and rc.color)
                task.delay(0.5, function() SetPanel("inv") end)
            end)
        end
        -- Resize canvas
        local cols = math.max(1, math.floor(sidePanel.AbsoluteSize.X / 98))
        local rows = math.ceil(idx / cols)
        invScroll.CanvasSize = UDim2.new(0,0,0,rows*114+10)
    end

    St._refreshInventory = RefreshInventory

    InventoryEvent.OnClientEvent:Connect(function(action, data)
        if action == "INVENTORY_DATA" then
            St.inventory = data or {}
            RefreshInventory(St.inventory)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PETS PANEL
-- ════════════════════════════════════════════════════════════════════════════
do
    MakePanelHeader("🐾  PETS", T.green)
    local petScroll, petGrid = MakeScrollGrid(50, 110, 134, 8, 8)
    panels.pets = petScroll

    -- Equipped slots at the top (mini strip)
    local slotStrip = MkFrame({
        Name="SlotStrip", Size=UDim2.new(1,0,0,48),
        Position=UDim2.new(0,0,0,44),
        BackgroundColor3=T.card, ZIndex=19, Parent=sidePanel,
    })
    local slotStripL = Instance.new("UIListLayout")
    slotStripL.FillDirection=Enum.FillDirection.Horizontal
    slotStripL.VerticalAlignment=Enum.VerticalAlignment.Center
    slotStripL.HorizontalAlignment=Enum.HorizontalAlignment.Center
    slotStripL.Padding=UDim.new(0,8)
    slotStripL.Parent=slotStrip

    local slotIcons = {}
    for i = 1,3 do
        local slot = MkFrame({
            Size=UDim2.new(0,38,0,38), BackgroundColor3=T.bg, ZIndex=20, Parent=slotStrip,
        })
        RC(slot,38) ; STK(slot, T.border)
        local ico = MkLabel({Size=UDim2.fromScale(1,1),Text="—",TextColor3=T.gray,ZIndex=21,Parent=slot})
        Instance.new("UITextSizeConstraint",ico).MaxTextSize=20
        slotIcons[i] = {frame=slot, icon=ico, stroke=slot:FindFirstChildOfClass("UIStroke")}
    end

    petScroll.Position = UDim2.new(0,0,0,96)
    petScroll.Size     = UDim2.new(1,0,1,-96)

    local function RefreshPets()
        for _, c in ipairs(petScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        -- Update slot strip
        for i = 1,3 do
            local ep = St.equippedPets[i]
            if ep then
                local rc = Config.RARITIES[ep.rarity]
                slotIcons[i].icon.Text = PET_ICONS[ep.id] or "🐾"
                slotIcons[i].frame.BackgroundColor3 = T.card
                if slotIcons[i].stroke then slotIcons[i].stroke.Color = rc and rc.color or T.border end
            else
                slotIcons[i].icon.Text = "—"
                slotIcons[i].frame.BackgroundColor3 = T.bg
                if slotIcons[i].stroke then slotIcons[i].stroke.Color = T.border end
            end
        end

        local idx=0
        for _, pet in ipairs(St.allPets) do
            idx=idx+1
            local rc = Config.RARITIES[pet.rarity]
            local isEq = false
            for _, ep in ipairs(St.equippedPets) do if ep.id==pet.id then isEq=true break end end

            local card = MkFrame({
                Size=UDim2.new(0,110,0,134), BackgroundColor3=T.card,
                LayoutOrder=idx, ZIndex=20, Parent=petScroll,
            })
            RC(card,10) ; STK(card, rc and rc.color or T.border, 1.5)

            local ico = MkLabel({
                Size=UDim2.new(1,0,0,58), Text=PET_ICONS[pet.id] or "🐾",
                ZIndex=21, Parent=card,
            })
            Instance.new("UITextSizeConstraint",ico).MaxTextSize=38

            local nl = MkLabel({
                Size=UDim2.new(1,-8,0,28), Position=UDim2.new(0,4,0,58),
                Text=pet.name, TextColor3=rc and rc.color or T.white,
                ZIndex=21, Parent=card,
            })
            Instance.new("UITextSizeConstraint",nl).MaxTextSize=11

            local ll = MkLabel({
                Size=UDim2.new(1,-8,0,18), Position=UDim2.new(0,4,0,86),
                Text="🍀 "..pet.luckBoost.."x", TextColor3=T.green,
                ZIndex=21, Parent=card,
            })
            Instance.new("UITextSizeConstraint",ll).MaxTextSize=13

            local eb = MkBtn({
                Size=UDim2.new(1,-8,0,22), Position=UDim2.new(0,4,0,108),
                BackgroundColor3 = isEq and T.red or T.green,
                Text = isEq and "UNEQUIP" or "EQUIP",
                TextColor3=T.white, ZIndex=22, Parent=card,
            }, function()
                if isEq then
                    EquipPetEvent:FireServer(pet.id, "UNEQUIP")
                else
                    EquipPetEvent:FireServer(pet.id, "EQUIP")
                end
            end)
            RC(eb,6)
            Instance.new("UITextSizeConstraint",eb).MaxTextSize=11
        end
        local cols = math.max(1, math.floor(sidePanel.AbsoluteSize.X / 118))
        local rows = math.ceil(idx/cols)
        petScroll.CanvasSize = UDim2.new(0,0,0,rows*142+10)
    end

    St._refreshPets = RefreshPets
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHOP PANEL
-- ════════════════════════════════════════════════════════════════════════════
do
    MakePanelHeader("🛒  SHOP", T.blue)
    local shopScroll = Instance.new("ScrollingFrame")
    shopScroll.Name                 = "ShopScroll"
    shopScroll.Size                 = UDim2.new(1,0,1,-50)
    shopScroll.Position             = UDim2.new(0,0,0,50)
    shopScroll.BackgroundTransparency = 1
    shopScroll.ScrollBarThickness   = 4
    shopScroll.ScrollBarImageColor3 = T.blue
    shopScroll.ZIndex               = 19
    shopScroll.Parent               = sidePanel
    panels.shop = shopScroll
    Pad(shopScroll, 8, 8, 8, 8)

    local shopLayout = Instance.new("UIListLayout")
    shopLayout.FillDirection = Enum.FillDirection.Vertical
    shopLayout.Padding       = UDim.new(0, 8)
    shopLayout.Parent        = shopScroll

    local SHOP_ITEMS = {
        {id="lucky_boost", icon="🍀", name="Lucky Boost",   cost=50,  desc="3× Luck for 60 seconds",      color=T.green},
        {id="gem_doubler", icon="💎", name="Gem Doubler",   cost=75,  desc="2× Gems per roll for 5 min",  color=T.gold},
        {id="",            icon="👑", name="VIP Pass",       cost=0,   desc="Exclusive auras (Robux)",     color=T.purple, robux=true},
        {id="",            icon="✨", name="Starter Pack",   cost=0,   desc="1000 gems + 5 Lucky Boosts",  color=T.blue, robux=true},
    }

    for _, item in ipairs(SHOP_ITEMS) do
        local row = MkFrame({
            Name=item.id.."Row",
            Size=UDim2.new(1,-16,0,72),
            BackgroundColor3=T.card, ZIndex=20, Parent=shopScroll,
        })
        RC(row, 10) ; STK(row, item.color, 1.5)

        local icoL = MkLabel({
            Size=UDim2.new(0,54,0,54), Position=UDim2.new(0,8,0.5,-27),
            Text=item.icon, ZIndex=21, Parent=row,
        })
        Instance.new("UITextSizeConstraint",icoL).MaxTextSize=32

        local nameL = MkLabel({
            Size=UDim2.new(0.5,0,0,26), Position=UDim2.new(0,70,0,8),
            Text=item.name, TextColor3=item.color,
            Font=Enum.Font.GothamBlack, ZIndex=21, Parent=row,
        })
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UITextSizeConstraint",nameL).MaxTextSize=15

        local descL = MkLabel({
            Size=UDim2.new(0.55,0,0,20), Position=UDim2.new(0,70,0,36),
            Text=item.desc, TextColor3=T.gray,
            Font=Enum.Font.Gotham, ZIndex=21, Parent=row,
        })
        descL.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UITextSizeConstraint",descL).MaxTextSize=11

        -- Timer bar (hidden by default)
        local timerBar = MkFrame({
            Name="TimerBar", Size=UDim2.new(0.5,0,0,4),
            Position=UDim2.new(0,70,0,58),
            BackgroundColor3=item.color, ZIndex=22, Parent=row,
        })
        RC(timerBar, 2)
        timerBar.Visible = false

        local buyBtn = MkBtn({
            Size=UDim2.new(0,80,0,38),
            AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,-10,0.5,0),
            BackgroundColor3 = item.robux and T.blue or item.color,
            Text = item.robux and "💎 ROBUX" or ("💎 "..item.cost),
            TextColor3 = item.robux and T.white or T.bg,
            Font=Enum.Font.GothamBlack, ZIndex=22, Parent=row,
        }, function()
            if item.robux or item.id == "" then
                Toast("Coming soon! 🛒", T.blue)
                return
            end
            ShopEvent:FireServer(item.id)
        end)
        RC(buyBtn, 8)
        Instance.new("UITextSizeConstraint",buyBtn).MaxTextSize=13

        -- Active timer display
        if item.id ~= "" then
            St.boostExpiry[item.id] = St.boostExpiry[item.id] or 0
        end
    end

    shopScroll.CanvasSize = UDim2.new(0,0,0,#SHOP_ITEMS*80+16)

    ShopEvent.OnClientEvent:Connect(function(status, itemId, duration)
        if status == "SUCCESS" then
            St.boostExpiry[itemId] = tick() + (duration or 60)
            local names = {lucky_boost="Lucky Boost", gem_doubler="Gem Doubler"}
            Toast("✅ " .. (names[itemId] or itemId) .. " active!", T.green)
        elseif status == "FAILED" then
            Toast("❌ Purchase failed: " .. tostring(itemId), T.red)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SETTINGS PANEL
-- ════════════════════════════════════════════════════════════════════════════
do
    MakePanelHeader("⚙️  SETTINGS", T.gray)
    local settingsFrame = MkFrame({
        Name="Settings",
        Size=UDim2.new(1,0,1,-50),
        Position=UDim2.new(0,0,0,50),
        BackgroundTransparency=1, ZIndex=19, Parent=sidePanel,
    })
    panels.settings = settingsFrame
    Pad(settingsFrame, 12, 12, 12, 12)

    local setLayout = Instance.new("UIListLayout")
    setLayout.FillDirection = Enum.FillDirection.Vertical
    setLayout.Padding       = UDim.new(0, 10)
    setLayout.Parent        = settingsFrame

    local function Toggle(name, desc, default, onChange)
        local row = MkFrame({
            Size=UDim2.new(1,0,0,50),
            BackgroundColor3=T.card, ZIndex=20, Parent=settingsFrame,
        })
        RC(row, 8) ; STK(row, T.border)

        local labelL = MkLabel({
            Size=UDim2.new(0.65,0,0.5,0), Position=UDim2.new(0,12,0,4),
            Text=name, Font=Enum.Font.GothamBlack, ZIndex=21, Parent=row,
        })
        labelL.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UITextSizeConstraint",labelL).MaxTextSize=14

        local descL = MkLabel({
            Size=UDim2.new(0.65,0,0.5,0), Position=UDim2.new(0,12,0.5,0),
            Text=desc, TextColor3=T.gray, ZIndex=21, Parent=row,
        })
        descL.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UITextSizeConstraint",descL).MaxTextSize=11

        local togBtn = MkBtn({
            Size=UDim2.new(0,58,0,30),
            AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,-10,0.5,0),
            BackgroundColor3 = default and T.green or T.card,
            Text = default and "ON" or "OFF",
            TextColor3 = default and T.bg or T.gray,
            ZIndex=22, Parent=row,
        }, nil)
        RC(togBtn, 8)
        Instance.new("UITextSizeConstraint",togBtn).MaxTextSize=13

        local val = default
        togBtn.MouseButton1Click:Connect(function()
            val = not val
            togBtn.BackgroundColor3 = val and T.green or T.card
            togBtn.TextColor3       = val and T.bg    or T.gray
            togBtn.Text             = val and "ON" or "OFF"
            onChange(val)
        end)
    end

    Toggle("Auto-Equip on Roll", "Equip aura immediately when rolled", false, function(v)
        St.autoEquip = v
    end)
    Toggle("Sound Effects", "Play sounds on roll and rare reveals", true, function(v)
        St.sfx = v
    end)
    Toggle("Show Roll Stats", "Display rolls/luck/gems at all times", true, function(v)
        statsRow.Visible = v
    end)
    Toggle("Compact Roll Panel", "Shrink roll panel to save screen space", false, function(v)
        local targetH = v and 0.22 or 0.3
        TweenService:Create(rollPanel, TweenInfo.new(0.3), {
            Size = UDim2.new(0.34, 0, targetH, 0)
        }):Play()
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- ROLL LOGIC
-- ════════════════════════════════════════════════════════════════════════════
local function UpdateStats(d)
    if d.totalLuck  then 
        St.luck  = d.totalLuck  
        lblLuck.Text  = "🍀 "..Utils.FormatLuck(d.totalLuck)
        luckLabel.Text = "LUCK: "..Utils.FormatLuck(d.totalLuck)
    end
    if d.rollCount  then St.rolls = d.rollCount   ; lblRolls.Text = "🎲 "..Utils.FormatNumber(d.rollCount) end
    if d.gems       then St.gems  = d.gems        ; lblGems.Text  = "💎 "..Utils.FormatNumber(d.gems) end
    if d.power      then
        St.power = d.power
        powerLabel.Text = "POWER: "..Utils.FormatNumber(d.power)
    end
    lblRolls.Text = "🎲 " .. (d.rollCount or 0)
    lblLuck.Text  = "🍀 " .. string.format("%.2fx", d.totalLuck or 1)
    lblGems.Text  = "💎 " .. (d.gems or 0)
    
    if gemsLbl then gemsLbl.Text = "💎 " .. (d.gems or 0) end

    if d.equippedAura then
        St.equippedAura = d.equippedAura
        local rc = Config.RARITIES[d.equippedAura.rarity]
        eqNameLbl.Text       = d.equippedAura.name .. " [" .. (d.equippedAura.power or 10) .. "]"
        eqNameLbl.TextColor3 = rc and rc.color or T.white
    end
    if d.equippedPets then St.equippedPets = d.equippedPets end
    if d.allPets      then St.allPets      = d.allPets end
    if St._refreshPets and St.activePanel == "pets" then St._refreshPets() end
end

local function RevealResult(aura)
    local col = Config.RARITIES[aura.rarity].color or T.white
    slotLabel.Text = string.format("%s [%d]", aura.name, aura.power or 10)
    slotLabel.TextColor3 = col
    task.delay(0.5, function()
        TweenService:Create(slotFrame, TweenInfo.new(0.15), {Size=UDim2.new(1,0,0.32,0)}):Play()
    end)

    if rarityIdx <= 2 then         -- Godlike/Secret
        Flash(col, 0.6)
        for i=1,3 do task.delay(i*0.08, function() Ring(col) end) end
    elseif rarityIdx <= 4 then     -- Legendary/Mythic
        Flash(col, 0.35)
        Ring(col)
    elseif rarityIdx <= 6 then     -- Rare/Epic
        Ring(col)
    end

    if St.autoEquip then
        -- auto equip handled by server echo
    end

    Toast(string.format("✨ %s  ·  %s", aura.name, aura.rarity), col)
end

local function DoRoll()
    if St.rolling then return end
    St.rolling = true

    rollBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 20)
    rollBtn.Text = "ANTICIPATING..."
    
    -- Sound support
    local function PlaySfx(id, vol)
        if not St.sfx then return end
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://"..id
        s.Volume = vol or 0.5
        s.Parent = playerGui
        s:Play()
        task.delay(2, function() s:Destroy() end)
    end

    -- 1. START FAST ROULETTE
    local cycleStart = tick()
    local DURATION = 1.8
    St.pendingAura = nil
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - cycleStart
        
        -- Keep cycling for DURATION seconds
        if elapsed < DURATION then
            local t = elapsed / DURATION
            local speed = 0.05 + (t * t * 0.3) -- quadratic slowdown
            
            if (tick() % speed) < 0.016 then
                local r = Config.AURAS[math.random(1, #Config.AURAS)]
                local rc = Config.RARITIES[r.rarity]
                slotLabel.Text = string.format("%s [%d]", r.name, r.power or 10)
                slotLabel.TextColor3 = rc and rc.color or T.gray
                PlaySfx(12222124, 0.2) -- Tick sound
            end
        else
            -- FINISHED DURATION, Reveal if result arrived
            conn:Disconnect()
            St.rolling = false
            rollBtn.BackgroundColor3 = T.gold
            rollBtn.Text = "🎲  ROLL AURA  [ R ]"
            
            if St.pendingAura then
                RevealResult(St.pendingAura)
                St.pendingAura = nil
            else
                -- Server was slow, wait for event
                slotLabel.Text = "..."
            end
        end
    end)

    RollEvent:FireServer()

    -- Safety timeout
    task.delay(10, function()
        if St.rolling then
            St.rolling = false
            rollBtn.BackgroundColor3 = T.gold
            rollBtn.Text = "🎲  ROLL AURA  [ R ]"
            if conn then conn:Disconnect() end
        end
    end)
end

rollBtn.MouseButton1Click:Connect(DoRoll)

autoBtn.MouseButton1Click:Connect(function()
    St.autoRoll = not St.autoRoll
    autoBtn.BackgroundColor3 = St.autoRoll and T.green or T.card
    autoBtn.TextColor3       = St.autoRoll and T.bg    or T.gray
    autoBtn.Text             = St.autoRoll and "AUTO: ON" or "AUTO: OFF"
    if St.autoRoll then
        St.autoConn = task.spawn(function()
            while St.autoRoll do
                if not St.rolling then DoRoll() end
                task.wait(0.75)
            end
        end)
    else
        St.autoRoll = false
    end
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.R then DoRoll() end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTE CONNECTIONS
-- ════════════════════════════════════════════════════════════════════════════
RollEvent.OnClientEvent:Connect(function(result, aura)
    if result == "SUCCESS" and aura then
        if not St.rolling then
            -- If animation already finished, reveal immediately
            RevealResult(aura)
        else
            -- Otherwise store for when animation finishes
            St.pendingAura = aura
        end
    else
        St.rolling = false
        rollBtn.BackgroundColor3 = T.gold
        rollBtn.Text = "🎲  ROLL AURA  [ R ]"
        slotLabel.Text       = "Error!"
        slotLabel.TextColor3 = T.red
    end
end)

DataUpdateEvent.OnClientEvent:Connect(function(evType, data)
    if evType == "SYNC" then
        UpdateStats(data)
        if St.activePanel == "inv" then
            InventoryEvent:FireServer("GET_INVENTORY")
        end
    elseif evType == "RARE_ROLL" then
        Toast(string.format("🔥 %s rolled %s!", data.playerName, data.auraName), data.color)
    end
end)

print("✅ HUD Initialized")
