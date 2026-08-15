local T = _G.T
local Helpers = _G.Helpers
local Phone = _G.Phone

local appGrid = Phone.appGrid
local dockBg = Phone.dockBg
local dockGrid = Phone.dockGrid
local gridLayout = Phone.gridLayout

local iconBuilders = _G.Icons or {}

local function buildAppIcon(name, order, parent, onOpen)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0, 74, 0, 92)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 58, 0, 58)
    btn.Position = UDim2.new(0.5, -29, 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
    btn.Text = ""
    btn.AutoButtonColor = false
    Helpers.corner(btn, 16)
    Helpers.stroke(btn, Color3.fromRGB(215, 215, 220), 1, 0.4)
    Helpers.pressFX(btn)
    
    local iconFrame = Instance.new("Frame", btn)
    iconFrame.Size = UDim2.new(0, 40, 0, 40)
    iconFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
    iconFrame.BackgroundTransparency = 1
    
    local builder = iconBuilders[name]
    if builder then
        builder(iconFrame, T.Text or Color3.fromRGB(30, 30, 30))
    else
        local letter = Instance.new("TextLabel", iconFrame)
        letter.Size = UDim2.new(1, 0, 1, 0)
        letter.BackgroundTransparency = 1
        letter.Text = string.sub(name, 1, 1):upper()
        letter.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
        letter.Font = Enum.Font.GothamBlack
        letter.TextSize = 22
    end
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 28)
    label.Position = UDim2.new(0, 0, 0, 63)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    
    btn.MouseButton1Click:Connect(onOpen)
    return container
end

-- ================= APP SCREEN =================
local sh = Phone.sh
local appScr = Instance.new("Frame", sh)
appScr.Size = UDim2.new(1, 0, 1, 0)
appScr.Position = UDim2.new(1, 0, 0, 0)
appScr.BackgroundTransparency = 1
appScr.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
appScr.ClipsDescendants = true

local appHdr = Instance.new("Frame", appScr)
appHdr.Size = UDim2.new(1, -12, 0, 36)
appHdr.Position = UDim2.new(0, 6, 0, 0)
appHdr.BackgroundTransparency = 1

local backBtn = Instance.new("TextButton", appHdr)
backBtn.Size = UDim2.new(0, 50, 0, 28)
backBtn.Position = UDim2.new(0, 0, 0, 4)
backBtn.BackgroundColor3 = T.Card or Color3.fromRGB(245, 245, 245)
backBtn.Text = "< Back"
backBtn.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 11
backBtn.AutoButtonColor = false
Helpers.corner(backBtn, 8)
Helpers.pressFX(backBtn)

local appTitle = Instance.new("TextLabel", appHdr)
appTitle.Size = UDim2.new(1, -120, 0, 28)
appTitle.Position = UDim2.new(0, 56, 0, 4)
appTitle.BackgroundTransparency = 1
appTitle.Text = ""
appTitle.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
appTitle.Font = Enum.Font.GothamBlack
appTitle.TextSize = 14
appTitle.TextXAlignment = Enum.TextXAlignment.Left

local appContent = Instance.new("ScrollingFrame", appScr)
appContent.Size = UDim2.new(1, -12, 1, -44)
appContent.Position = UDim2.new(0, 6, 0, 42)
appContent.BackgroundTransparency = 1
appContent.BorderSizePixel = 0
appContent.ScrollBarThickness = 3
appContent.ScrollBarImageColor3 = T.Accent or Color3.fromRGB(30, 30, 30)
appContent.CanvasSize = UDim2.new(0, 0, 0, 0)
appContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

local acl = Instance.new("UIListLayout", appContent)
acl.Padding = UDim.new(0, 8)
acl.SortOrder = Enum.SortOrder.LayoutOrder

local function clearAppContent()
    for _, c in ipairs(appContent:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local currOpener = nil

function _G.goHome()
    if _G.PhoneState.isLocked then return end
    Phone.home.Visible = true
    appScr.BackgroundTransparency = 1
    Helpers.tween(appScr, {Position = UDim2.new(1, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
    Helpers.tween(Phone.home, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
end

function _G.openApp(title, fn)
    if _G.PhoneState.isLocked then return end
    Phone.home.Visible = false
    appScr.BackgroundTransparency = 0
    appScr.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
    appTitle.Text = title
    clearAppContent()
    currOpener = fn
    fn()
    appScr.Position = UDim2.new(1, 0, 0, 0)
    Helpers.tween(appScr, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
    _G.showDynamicNotification(title, T.Accent)
end

function _G.refreshCurr()
    if currOpener then
        clearAppContent()
        currOpener()
    end
end

backBtn.MouseButton1Click:Connect(_G.goHome)

-- Export
_G.buildAppIcon = buildAppIcon
_G.appContent = appContent
_G.appScr = appScr
_G.appTitle = appTitle

-- ================= DOCK ICONS =================
buildAppIcon("Profile", 1, dockBg, function() _G.openApp("Profile", _G.openProfileApp) end)
buildAppIcon("Command", 2, dockBg, function() _G.openApp("Commands", _G.openCommandApp) end)
buildAppIcon("Settings", 3, dockBg, function() _G.openApp("Settings", _G.openSettingsApp) end)

-- ================= GRID ICONS =================
buildAppIcon("Players", 1, appGrid, function() _G.openApp("Players", _G.openPlayersApp) end)
buildAppIcon("Clone", 2, appGrid, function() _G.openApp("Clone", _G.openCloneApp) end)
buildAppIcon("Preset", 5, appGrid, function() _G.openApp("Preset", _G.openPresetApp) end)
buildAppIcon("Favs", 6, appGrid, function() _G.openApp("Favorites", _G.openFavoritesApp) end)
buildAppIcon("Items", 7, appGrid, function() _G.openApp("Items", _G.openItemsApp) end)
buildAppIcon("Teleport", 8, appGrid, function() _G.openApp("Save & Teleport", _G.openTeleportApp) end)
buildAppIcon("Size", 9, appGrid, function() _G.openApp("Size", _G.openSizeApp) end)
buildAppIcon("Volume", 10, appGrid, function() _G.openApp("Volume", _G.openVolumeApp) end)
buildAppIcon("Friends", 11, appGrid, function() _G.openApp("Friends", _G.openFriendsApp) end)
buildAppIcon("Server", 12, appGrid, function() _G.openApp("Server", _G.openServerApp) end)
buildAppIcon("Bundle", 13, appGrid, function() _G.openApp("Bundle", _G.openBundleApp) end)
buildAppIcon("ServerJoiner", 15, appGrid, function() _G.openApp("Server Joiner", _G.openServerJoinerApp) end)
buildAppIcon("WhoOnline", 16, appGrid, function() _G.openApp("Who's Online", _G.openWhoOnlineApp) end)
buildAppIcon("Message", 17, appGrid, function() _G.openApp("Messages", _G.openMessageApp) end)
buildAppIcon("Premium", 18, appGrid, function() _G.openApp("Premium", _G.openPremiumApp) end)
buildAppIcon("ChatAI", 19, appGrid, function() _G.openApp("Chat AI", _G.openChatAIApp) end)


return {
    buildAppIcon = buildAppIcon,
    appScr = appScr,
    appContent = appContent,
    appTitle = appTitle,
    clearAppContent = clearAppContent,
}