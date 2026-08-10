local T            = _G.T
local Helpers      = _G.Helpers
local iconBuilders = _G.iconBuilders
local appGrid      = _G.appGrid
local dockBg       = _G.dockBg
local openApp      = _G.openApp

-- ================= BUILD APP ICON =================
local function buildAppIcon(name, order, parent, onOpen)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0,74,0,96)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0,58,0,58)
    btn.Position = UDim2.new(0.5,-29,0,2)
    btn.BackgroundColor3 = Color3.fromRGB(248,248,252)
    btn.Text = ""
    btn.AutoButtonColor = false
    Helpers.corner(btn, 16)
    Helpers.stroke(btn, Color3.fromRGB(215,215,220), 1, 0.4)

    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(252,252,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(240,240,245))
    })
    btnGrad.Rotation = 135

    local iconFrame = Instance.new("Frame", btn)
    iconFrame.Size = UDim2.new(0,40,0,40)
    iconFrame.Position = UDim2.new(0.5,-20,0.5,-20)
    iconFrame.BackgroundTransparency = 1

    local builder = iconBuilders[name]
    if builder then
        builder(iconFrame, T.Text)
    else
        local fallback = Instance.new("TextLabel", iconFrame)
        fallback.Size = UDim2.new(1,0,1,0)
        fallback.BackgroundTransparency = 1
        fallback.Text = string.sub(name,1,1):upper()
        fallback.TextColor3 = T.Text
        fallback.Font = Enum.Font.GothamBlack
        fallback.TextSize = 22
    end

    Helpers.pressFX(btn)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1,0,0,28)
    label.Position = UDim2.new(0,0,0,63)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = T.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.LineHeight = 1.1

    btn.MouseButton1Click:Connect(onOpen)
    return container
end

-- ================= DOCK =================
local openPlayersApp    = _G.openPlayersApp
local openCommandApp    = _G.openCommandApp
local openSettingsApp   = _G.openSettingsApp
local openProfileApp    = _G.openProfileApp
local openCloneApp      = _G.openCloneApp
local openBodyApp       = _G.openBodyApp
local openAccessoryApp  = _G.openAccessoryApp
local openPresetApp     = _G.openPresetApp
local openFavoritesApp  = _G.openFavoritesApp
local openItemsApp      = _G.openItemsApp
local openTeleportApp   = _G.openTeleportApp
local openSizeApp       = _G.openSizeApp
local openVolumeApp     = _G.openVolumeApp
local openFriendsApp    = _G.openFriendsApp
local openServerApp     = _G.openServerApp
local openBundleApp     = _G.openBundleApp
local openAvatarItemsApp= _G.openAvatarItemsApp
local openPlayerLookupApp = _G.openPlayerLookupApp
local openServerJoinerApp = _G.openServerJoinerApp
local openWhoOnlineApp  = _G.openWhoOnlineApp
local openMessageApp    = _G.openMessageApp

-- DOCK
buildAppIcon("Profile",  1, dockBg, function() openApp("Profile",  openProfileApp) end)
buildAppIcon("Command",  2, dockBg, function() openApp("Commands", openCommandApp) end)
buildAppIcon("Settings", 3, dockBg, function() openApp("Settings", openSettingsApp) end)

-- APP GRID
buildAppIcon("Players",     1,  appGrid, function() openApp("Players",       openPlayersApp) end)
buildAppIcon("Clone",       2,  appGrid, function() openApp("Clone",         openCloneApp) end)
buildAppIcon("Body",        3,  appGrid, function() openApp("Body",          openBodyApp) end)
buildAppIcon("Accs",        4,  appGrid, function() openApp("Accessory",     openAccessoryApp) end)
buildAppIcon("Preset",      5,  appGrid, function() openApp("Preset",        openPresetApp) end)
buildAppIcon("Favs",        6,  appGrid, function() openApp("Favorites",     openFavoritesApp) end)
buildAppIcon("Items",       7,  appGrid, function() openApp("Items",         openItemsApp) end)
buildAppIcon("Teleport",    8,  appGrid, function() openApp("Save & Teleport", openTeleportApp) end)
buildAppIcon("Size",        9,  appGrid, function() openApp("Size",          openSizeApp) end)
buildAppIcon("Volume",      10, appGrid, function() openApp("Volume",        openVolumeApp) end)
buildAppIcon("Friends",     11, appGrid, function() openApp("Friends",       openFriendsApp) end)
buildAppIcon("Server",      12, appGrid, function() openApp("Server",        openServerApp) end)
buildAppIcon("Bundle",      13, appGrid, function() openApp("Bundle",        openBundleApp) end)
buildAppIcon("AvatarItems", 14, appGrid, function() openApp("Avatar & Items",openAvatarItemsApp) end)
buildAppIcon("Lookup",      15, appGrid, function() openApp("Player Lookup", openPlayerLookupApp) end)
buildAppIcon("ServerJoiner",16, appGrid, function() openApp("Server Joiner", openServerJoinerApp) end)
buildAppIcon("WhoOnline",   17, appGrid, function() openApp("Who's Online",  openWhoOnlineApp) end)
buildAppIcon("Message",     18, appGrid, function() openApp("Messages",      openMessageApp) end)