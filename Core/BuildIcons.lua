-- ================================================
-- BUILD ICONS - Dynamic with AppRegistry
-- ================================================

local T = _G.T
local Helpers = _G.Helpers
local Phone = _G.Phone
local AppRegistry = _G.AppRegistry or {}

local appGrid = Phone.appGrid
local dockBg = Phone.dockBg

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
    
    if type(onOpen) == "function" then
        btn.MouseButton1Click:Connect(onOpen)
    else
        btn.BackgroundTransparency = 0.5
        label.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    return container
end

-- App screen
local sh = Phone.sh
local appScr = Instance.new("Frame", sh)
appScr.Size = UDim2.new(1, 0, 1, 0)
appScr.Position = UDim2.new(1, 0, 0, 0)
appScr.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
appScr.ClipsDescendants = true

local appHdr = Instance.new("Frame", appScr)
appHdr.Size = UDim2.new(1, -12, 0, 36)
appHdr.Position = UDim2.new(0, 6, 0, 0)
appHdr.BackgroundTransparency = 1

local backBtn = Instance.new("TextButton", appHdr)
backBtn.Size = UDim2.new(0, 50, 0, 28)
backBtn.Position = UDim2.new(0, 0, 0, 4)
backBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
backBtn.Text = "< Back"
backBtn.TextColor3 = Color3.new(1, 1, 1)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 11
backBtn.AutoButtonColor = false
Helpers.corner(backBtn, 8)

local appTitle = Instance.new("TextLabel", appHdr)
appTitle.Size = UDim2.new(1, -120, 0, 28)
appTitle.Position = UDim2.new(0, 56, 0, 4)
appTitle.BackgroundTransparency = 1
appTitle.Text = ""
appTitle.TextColor3 = Color3.new(1, 1, 1)
appTitle.Font = Enum.Font.GothamBlack
appTitle.TextSize = 14
appTitle.TextXAlignment = Enum.TextXAlignment.Left

local appContent = Instance.new("ScrollingFrame", appScr)
appContent.Size = UDim2.new(1, -12, 1, -44)
appContent.Position = UDim2.new(0, 6, 0, 42)
appContent.BackgroundTransparency = 1
appContent.BorderSizePixel = 0
appContent.ScrollBarThickness = 3
appContent.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
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

function _G.goHome()
    if _G.PhoneState and _G.PhoneState.isLocked then return end
    Phone.home.Visible = true
    Helpers.tween(appScr, {Position = UDim2.new(1, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
    Helpers.tween(Phone.home, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
end

function _G.openApp(title, fn)
    if _G.PhoneState and _G.PhoneState.isLocked then return end
    
    if type(fn) ~= "function" then
        _G.showDynamicNotification("App unavailable", Color3.fromRGB(255, 80, 80))
        return
    end
    
    Phone.home.Visible = false
    appTitle.Text = title
    clearAppContent()
    fn()
    appScr.Position = UDim2.new(1, 0, 0, 0)
    Helpers.tween(appScr, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quart)
end

backBtn.MouseButton1Click:Connect(_G.goHome)

-- Export
_G.appContent = appContent
_G.appScr = appScr
_G.appTitle = appTitle

-- Build dock icons (only available apps)
local dockApps = {
    {name = "Settings", opener = _G.openSettingsApp},
}

for i, app in ipairs(dockApps) do
    buildAppIcon(app.name, i, dockBg, app.opener)
end

-- Build grid icons (only available apps)
local gridApps = {
    {name = "Players", opener = _G.openPlayersApp},
    {name = "NotifWeb", opener = _G.openNotifWebApp},
}

for i, app in ipairs(gridApps) do
    buildAppIcon(app.name, i, appGrid, app.opener)
end

return {
    appScr = appScr,
    appContent = appContent,
    appTitle = appTitle,
    clearAppContent = clearAppContent,
}