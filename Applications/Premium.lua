-- ================================================
-- PREMIUM APP - Loader untuk Sub-Apps di Folder Permanent
-- ================================================

local Services       = _G.Services
local LocalPlayer    = _G.LocalPlayer
local Firebase       = _G.Firebase
local Config         = _G.Config or {}
local Helpers        = _G.Helpers or {}
local appContent     = _G.appContent

local TweenService   = game:GetService("TweenService")

-- ==================== PERSISTENT STATE ====================
_G.PremiumState = _G.PremiumState or {
    selectedTargetId = nil,
    selectedTargetName = "Pilih Player",
    currentSubApp = "Target",
}

local State = _G.PremiumState

-- ==================== PALETTE ====================
local P = {
    bg          = Color3.fromRGB(10, 10, 14),
    bgCard      = Color3.fromRGB(20, 20, 27),
    bgCard2     = Color3.fromRGB(26, 26, 34),
    bgElevated  = Color3.fromRGB(32, 32, 42),
    accent      = Color3.fromRGB(168, 110, 255),
    accentSoft  = Color3.fromRGB(120, 80, 200),
    accentGlow  = Color3.fromRGB(198, 150, 255),
    green       = Color3.fromRGB(80, 220, 150),
    red         = Color3.fromRGB(255, 90, 100),
    gold        = Color3.fromRGB(255, 195, 90),
    blue        = Color3.fromRGB(100, 170, 255),
    orange      = Color3.fromRGB(255, 150, 50),
    pink        = Color3.fromRGB(255, 120, 200),
    cyan        = Color3.fromRGB(80, 220, 255),
    textMain    = Color3.fromRGB(240, 240, 245),
    textSub     = Color3.fromRGB(150, 150, 165),
    textFaint   = Color3.fromRGB(95, 95, 110),
    border      = Color3.fromRGB(45, 45, 58),
}

-- ==================== ACCESS VALIDATION ====================
local function hasAccess()
    if LocalPlayer.UserId == (Config.DEVELOPER_USER_ID or 10164114772) then return true end
    if Firebase and Firebase.IsPermanentUser then
        return Firebase.IsPermanentUser(LocalPlayer.UserId)
    end
    return false
end
_G.hasPremiumAccess = hasAccess

-- ==================== SUB-APP REGISTRY ====================
-- Ini adalah daftar sub-app yang akan di-load dari folder Permanent
-- Setiap sub-app punya file sendiri di Applications/Permanent/
_G.PremiumSubApps = _G.PremiumSubApps or {}

local function registerSubApp(name, iconName, loadFunc)
    _G.PremiumSubApps[name] = {
        name = name,
        iconName = iconName,
        loadFunc = loadFunc,
    }
end

-- ==================== LOAD SUB-APP MODULES ====================
-- Load semua file dari folder Permanent
local PermanentApps = {
    {name = "Target", icon = "Target", file = "Applications/Permanent/Target.lua"},
    {name = "Chat", icon = "Chat", file = "Applications/Permanent/Chat.lua"},
    {name = "Jail", icon = "Jail", file = "Applications/Permanent/Jail.lua"},
    {name = "Teleport", icon = "Teleport", file = "Applications/Permanent/Teleport.lua"},
    {name = "Bling", icon = "Bling", file = "Applications/Permanent/Bling.lua"},
    {name = "Fly", icon = "Fly", file = "Applications/Permanent/Fly.lua"},
    {name = "Movement", icon = "Movement", file = "Applications/Permanent/Movement.lua"},
    {name = "Jumpscare", icon = "Jumpscare", file = "Applications/Permanent/Jumpscare.lua"},
    {name = "Aura", icon = "Aura", file = "Applications/Permanent/Aura.lua"},
    {name = "Sky", icon = "Sky", file = "Applications/Permanent/Sky.lua"},
    {name = "Dex", icon = "Dex", file = "Applications/Permanent/Dex.lua"},
}

-- ==================== OPEN PREMIUM APP ====================
function _G.openPremiumApp()
    if not hasAccess() then
        _G.showDynamicNotification("Akses Ditolak! Membutuhkan Key Permanen.", P.red)
        if _G.goHome then _G.goHome() end
        return
    end

    -- Clear content
    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    appContent.BackgroundColor3 = P.bg

    -- ==================== HEADER ====================
    local headerFrame = Instance.new("Frame", appContent)
    headerFrame.Size = UDim2.new(1, 0, 0, 44)
    headerFrame.BackgroundColor3 = P.bgCard
    headerFrame.BorderSizePixel = 0
    Helpers.corner(headerFrame, 12)

    local crownIcon = Instance.new("TextLabel", headerFrame)
    crownIcon.Size = UDim2.new(0, 30, 1, 0)
    crownIcon.Position = UDim2.new(0, 8, 0, 0)
    crownIcon.BackgroundTransparency = 1
    crownIcon.Text = "P"
    crownIcon.TextColor3 = P.accentGlow
    crownIcon.Font = Enum.Font.GothamBlack
    crownIcon.TextSize = 16

    local statusLbl = Instance.new("TextLabel", headerFrame)
    statusLbl.Size = UDim2.new(1, -46, 1, 0)
    statusLbl.Position = UDim2.new(0, 38, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "TARGET: " .. string.upper(State.selectedTargetName)
    statusLbl.TextColor3 = P.accentGlow
    statusLbl.Font = Enum.Font.GothamBlack
    statusLbl.TextSize = 11
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- ==================== SUB-APP GRID (Horizontal Scroll) ====================
    local gridContainer = Instance.new("ScrollingFrame", appContent)
    gridContainer.Size = UDim2.new(1, 0, 0, 72)
    gridContainer.Position = UDim2.new(0, 0, 0, 50)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ScrollBarThickness = 0
    gridContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.X

    local gridLayout = Instance.new("UIGridLayout", gridContainer)
    gridLayout.CellSize = UDim2.new(0, 62, 0, 62)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 0)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal

    -- ==================== CONTENT AREA ====================
    local contentArea = Instance.new("ScrollingFrame", appContent)
    contentArea.Size = UDim2.new(1, 0, 1, -128)
    contentArea.Position = UDim2.new(0, 0, 0, 128)
    contentArea.BackgroundTransparency = 1
    contentArea.ScrollBarThickness = 2
    contentArea.ScrollBarImageColor3 = P.accent
    contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local contentPadding = Instance.new("UIPadding", contentArea)
    contentPadding.PaddingLeft = UDim.new(0, 4)
    contentPadding.PaddingRight = UDim.new(0, 4)
    contentPadding.PaddingTop = UDim.new(0, 4)
    contentPadding.PaddingBottom = UDim.new(0, 20)

    local contentLayout = Instance.new("UIListLayout", contentArea)
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- ==================== CLEAR CONTENT ====================
    local function clearContent()
        for _, child in ipairs(contentArea:GetChildren()) do
            if not child:IsA("UIPadding") and not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
    end

    -- ==================== RENDER SUB-APP CONTENT ====================
    local function renderSubApp(subAppName)
        clearContent()
        
        local subApp = _G.PremiumSubApps[subAppName]
        if not subApp or not subApp.loadFunc then
            local empty = Instance.new("TextLabel", contentArea)
            empty.Size = UDim2.new(1, 0, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = "Sub-app belum tersedia."
            empty.TextColor3 = P.textFaint
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextXAlignment = Enum.TextXAlignment.Center
            return
        end
        
        subApp.loadFunc(contentArea)
    end

    -- ==================== BUILD SUB-APP BUTTONS ====================
    local subAppButtons = {}

    for i, app in ipairs(PermanentApps) do
        local btnContainer = Instance.new("Frame", gridContainer)
        btnContainer.Size = UDim2.new(0, 62, 0, 62)
        btnContainer.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", btnContainer)
        btn.Size = UDim2.new(0, 48, 0, 48)
        btn.Position = UDim2.new(0.5, -24, 0, 0)
        btn.BackgroundColor3 = P.bgCard2
        btn.Text = ""
        btn.AutoButtonColor = false
        Helpers.corner(btn, 14)
        Helpers.stroke(btn, P.border, 1, 0.4)

        -- Icon (dari IconPrem)
        local iconFrame = Instance.new("Frame", btn)
        iconFrame.Size = UDim2.new(0, 30, 0, 30)
        iconFrame.Position = UDim2.new(0.5, -15, 0.5, -15)
        iconFrame.BackgroundTransparency = 1

        local iconBuilder = _G.PremiumIcons and _G.PremiumIcons[app.icon]
        if iconBuilder then
            iconBuilder(iconFrame, P.textMain)
        else
            local letter = Instance.new("TextLabel", iconFrame)
            letter.Size = UDim2.new(1, 0, 1, 0)
            letter.BackgroundTransparency = 1
            letter.Text = string.sub(app.name, 1, 1)
            letter.TextColor3 = P.textMain
            letter.Font = Enum.Font.GothamBlack
            letter.TextSize = 14
        end

        -- Label
        local label = Instance.new("TextLabel", btnContainer)
        label.Size = UDim2.new(1, 0, 0, 12)
        label.Position = UDim2.new(0, 0, 0, 50)
        label.BackgroundTransparency = 1
        label.Text = app.name
        label.TextColor3 = P.textSub
        label.Font = Enum.Font.GothamBold
        label.TextSize = 8
        label.TextXAlignment = Enum.TextXAlignment.Center

        -- Highlight jika aktif
        if State.currentSubApp == app.name then
            btn.BackgroundColor3 = P.accent
            Helpers.stroke(btn, P.accentGlow, 2, 0)
            if iconBuilder then
                iconFrame:ClearAllChildren()
                iconBuilder(iconFrame, Color3.new(1, 1, 1))
            end
        end

        btn.MouseButton1Click:Connect(function()
            State.currentSubApp = app.name
            
            -- Update semua tombol
            for _, otherBtn in ipairs(subAppButtons) do
                otherBtn.BackgroundColor3 = P.bgCard2
                Helpers.stroke(otherBtn, P.border, 1, 0.4)
            end
            
            btn.BackgroundColor3 = P.accent
            Helpers.stroke(btn, P.accentGlow, 2, 0)
            
            renderSubApp(app.name)
        end)

        table.insert(subAppButtons, btn)
    end

    -- ==================== INITIAL RENDER ====================
    renderSubApp(State.currentSubApp)
end

print("[Premium] Loader loaded! Menunggu sub-app dari folder Permanent.")