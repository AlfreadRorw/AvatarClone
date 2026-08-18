-- ================================================
-- PREMIUM APP - Loader dengan Navigasi Sub-App
-- Setiap Sub-App bisa dibuka seperti app biasa dengan Back button
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
    currentSubApp = nil, -- nil = main menu
    previousSubApp = nil,
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
_G.PremiumSubApps = _G.PremiumSubApps or {}

-- ==================== SUB-APP LIST ====================
local PermanentApps = {
    {name = "Target", icon = "Target", color = Color3.fromRGB(100, 170, 255)},
    {name = "Chat", icon = "Chat", color = Color3.fromRGB(80, 220, 150)},
    {name = "Jail", icon = "Jail", color = Color3.fromRGB(255, 90, 100)},
    {name = "Teleport", icon = "Teleport", color = Color3.fromRGB(168, 110, 255)},
    {name = "Bling", icon = "Bling", color = Color3.fromRGB(255, 195, 90)},
    {name = "Fly", icon = "Fly", color = Color3.fromRGB(80, 220, 255)},
    {name = "Movement", icon = "Movement", color = Color3.fromRGB(255, 150, 50)},
    {name = "Jumpscare", icon = "Jumpscare", color = Color3.fromRGB(255, 120, 200)},
    {name = "Aura", icon = "Aura", color = Color3.fromRGB(198, 150, 255)},
    {name = "Sky", icon = "Sky", color = Color3.fromRGB(100, 170, 255)},
    {name = "Dex", icon = "Dex", color = Color3.fromRGB(150, 150, 165)},
}

-- ==================== HELPER: SEND COMMAND ====================
local function sendCommand(cmdType, extraData, silent)
    if not State.selectedTargetId then
        _G.showDynamicNotification("⚠️ Pilih target dulu!", P.red)
        return false
    end
    local data = { type = cmdType, timestamp = os.time() }
    if extraData then
        for k, v in pairs(extraData) do data[k] = v end
    end
    pcall(function() Firebase.PushCommand(State.selectedTargetId, data) end)
    if not silent then
        _G.showDynamicNotification("✅ " .. cmdType .. " terkirim!", P.green)
    end
    return true
end
_G.PremiumSendCommand = sendCommand

-- ==================== OPEN PREMIUM APP (Main Menu) ====================
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

    -- ==================== SUB-APP GRID (Main Menu) ====================
    local gridContainer = Instance.new("ScrollingFrame", appContent)
    gridContainer.Size = UDim2.new(1, 0, 1, -52)
    gridContainer.Position = UDim2.new(0, 0, 0, 52)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ScrollBarThickness = 2
    gridContainer.ScrollBarImageColor3 = P.accent
    gridContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local gridPadding = Instance.new("UIPadding", gridContainer)
    gridPadding.PaddingLeft = UDim.new(0, 8)
    gridPadding.PaddingRight = UDim.new(0, 8)
    gridPadding.PaddingTop = UDim.new(0, 8)
    gridPadding.PaddingBottom = UDim.new(0, 20)

    local gridLayout = Instance.new("UIGridLayout", gridContainer)
    gridLayout.CellSize = UDim2.new(0.31, 0, 0, 100)
    gridLayout.CellPadding = UDim2.new(0.035, 0, 0, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ==================== BUILD SUB-APP BUTTONS ====================
    for i, app in ipairs(PermanentApps) do
        local container = Instance.new("Frame", gridContainer)
        container.Size = UDim2.new(0.31, 0, 0, 100)
        container.BackgroundTransparency = 1
        container.LayoutOrder = i

        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0, 60, 0, 60)
        btn.Position = UDim2.new(0.5, -30, 0, 0)
        btn.BackgroundColor3 = P.bgCard2
        btn.Text = ""
        btn.AutoButtonColor = false
        Helpers.corner(btn, 16)
        Helpers.stroke(btn, app.color, 1.5, 0.3)

        -- Icon
        local iconFrame = Instance.new("Frame", btn)
        iconFrame.Size = UDim2.new(0, 36, 0, 36)
        iconFrame.Position = UDim2.new(0.5, -18, 0.5, -18)
        iconFrame.BackgroundTransparency = 1

        local iconBuilder = _G.PremiumIcons and _G.PremiumIcons[app.icon]
        if iconBuilder then
            iconBuilder(iconFrame, app.color)
        else
            local letter = Instance.new("TextLabel", iconFrame)
            letter.Size = UDim2.new(1, 0, 1, 0)
            letter.BackgroundTransparency = 1
            letter.Text = string.sub(app.name, 1, 1)
            letter.TextColor3 = app.color
            letter.Font = Enum.Font.GothamBlack
            letter.TextSize = 18
        end

        -- Label
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 30)
        label.Position = UDim2.new(0, 0, 0, 64)
        label.BackgroundTransparency = 1
        label.Text = app.name
        label.TextColor3 = P.textMain
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Center

        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(0.5, -32, 0, -2)}):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.5, -30, 0, 0)}):Play()
        end)

        -- Click: buka sub-app
        btn.MouseButton1Click:Connect(function()
            State.currentSubApp = app.name
            _G.openPremiumSubApp(app.name)
        end)
    end
end

-- ==================== OPEN SUB-APP (Seperti App Biasa dengan Back) ====================
function _G.openPremiumSubApp(subAppName)
    if not hasAccess() then
        _G.showDynamicNotification("Akses Ditolak!", P.red)
        return
    end

    local subApp = _G.PremiumSubApps[subAppName]
    if not subApp or not subApp.loadFunc then
        _G.showDynamicNotification("Sub-app belum tersedia.", P.textFaint)
        return
    end

    -- Clear content
    for _, child in ipairs(appContent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    appContent.BackgroundColor3 = P.bg

    -- ==================== HEADER dengan BACK BUTTON ====================
    local headerFrame = Instance.new("Frame", appContent)
    headerFrame.Size = UDim2.new(1, 0, 0, 44)
    headerFrame.BackgroundColor3 = P.bgCard
    headerFrame.BorderSizePixel = 0
    Helpers.corner(headerFrame, 12)

    -- Back button (kembali ke main menu Premium)
    local backBtn = Instance.new("TextButton", headerFrame)
    backBtn.Size = UDim2.new(0, 60, 0, 28)
    backBtn.Position = UDim2.new(0, 6, 0.5, -14)
    backBtn.BackgroundColor3 = P.bgElevated
    backBtn.Text = "< Back"
    backBtn.TextColor3 = P.textMain
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 10
    backBtn.AutoButtonColor = false
    Helpers.corner(backBtn, 8)
    if Helpers.pressFX then Helpers.pressFX(backBtn) end

    backBtn.MouseButton1Click:Connect(function()
        State.currentSubApp = nil
        _G.openPremiumApp()
    end)

    -- Sub-app title
    local titleLbl = Instance.new("TextLabel", headerFrame)
    titleLbl.Size = UDim2.new(1, -140, 1, 0)
    titleLbl.Position = UDim2.new(0, 70, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = subAppName
    titleLbl.TextColor3 = P.textMain
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Target info
    local targetLbl = Instance.new("TextLabel", headerFrame)
    targetLbl.Size = UDim2.new(0, 80, 1, 0)
    targetLbl.Position = UDim2.new(1, -86, 0, 0)
    targetLbl.BackgroundTransparency = 1
    targetLbl.Text = State.selectedTargetName
    targetLbl.TextColor3 = P.accentGlow
    targetLbl.Font = Enum.Font.GothamBold
    targetLbl.TextSize = 9
    targetLbl.TextXAlignment = Enum.TextXAlignment.Right
    targetLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- ==================== CONTENT AREA ====================
    local contentArea = Instance.new("ScrollingFrame", appContent)
    contentArea.Size = UDim2.new(1, 0, 1, -52)
    contentArea.Position = UDim2.new(0, 0, 0, 52)
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

    -- Load sub-app content
    subApp.loadFunc(contentArea)
end

print("[Premium] Loader loaded! Sub-apps siap digunakan.")