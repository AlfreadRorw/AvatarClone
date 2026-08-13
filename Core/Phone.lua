-- Core/Phone.lua
-- Membuat GUI root, phone frame, screen area, home screen

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local Storage = _G.Storage

local appSettings = Storage.appSettings

-- ================= GUI ROOT =================
local gui = Instance.new("ScreenGui")
gui.Name = "PhoneGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 998
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local function getGuiParent()
    local ok, r = pcall(function()
        if gethui then return gethui() end
        if syn and syn.protect_gui then
            local sg = Instance.new("ScreenGui")
            syn.protect_gui(sg)
            sg.Parent = game:GetService("CoreGui")
            return sg
        end
        return game:GetService("CoreGui")
    end)
    return ok and r or game:GetService("CoreGui")
end
gui.Parent = getGuiParent()

-- ================= PHONE FRAME =================
local phone = Instance.new("Frame", gui)
phone.Size = UDim2.new(0, 0, 0, 0)
phone.Position = UDim2.new(0.5, 0, 0.52, 0)
phone.AnchorPoint = Vector2.new(0.5, 0.5)
phone.BackgroundColor3 = appSettings.bgColor or T.BG
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
Helpers.corner(phone, 38)
phone.BackgroundTransparency = 1 - (appSettings.phoneOpacity or 1)

local phoneStroke = Helpers.stroke(phone, T.Accent, 2, appSettings.glowEnabled and 0.5 or 0.15)

-- ================= ORIENTASI =================
local PHONE_SIZE_PORTRAIT = UDim2.new(0, 320, 0, 560)
local PHONE_SIZE = PHONE_SIZE_PORTRAIT
local isLandscapeMode = false

local function isPortrait()
    local cam = Services.Workspace.CurrentCamera
    if not cam then return true end
    return cam.ViewportSize.Y >= cam.ViewportSize.X
end

local function getGridIconSize()
    if isPortrait() then
        return UDim2.new(0, 72, 0, 86)
    else
        return UDim2.new(0, 68, 0, 78)
    end
end

-- ================= SCREEN AREA =================
local sa = Instance.new("Frame", phone)
sa.Size = UDim2.new(1, -16, 1, -16)
sa.Position = UDim2.new(0, 8, 0, 8)
sa.BackgroundColor3 = T.BG
sa.BorderSizePixel = 0
sa.ClipsDescendants = true
Helpers.corner(sa, 30)

-- ================= STATUS BAR =================
local sb = Instance.new("Frame", sa)
sb.Size = UDim2.new(1, 0, 0, 34)
sb.BackgroundTransparency = 1
sb.ZIndex = 100

local clockLbl = Instance.new("TextLabel", sb)
clockLbl.Size = UDim2.new(0, 80, 1, 0)
clockLbl.Position = UDim2.new(0, 14, 0, 0)
clockLbl.BackgroundTransparency = 1
clockLbl.Text = os.date("%H:%M")
clockLbl.TextColor3 = T.Text
clockLbl.Font = Enum.Font.GothamBold
clockLbl.TextSize = 13
clockLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while clockLbl.Parent do
        local format = appSettings.clockFormat == "12" and "%I:%M %p" or "%H:%M"
        clockLbl.Text = os.date(format)
        task.wait(30)
    end
end)

-- ================= DYNAMIC ISLAND =================
local di = Instance.new("Frame", sa)
di.Size = UDim2.new(0, 90, 0, 24)
di.Position = UDim2.new(0.5, -45, 0, 4)
di.BackgroundColor3 = Color3.new(0, 0, 0)
di.ZIndex = 110
Helpers.corner(di, 100)

local diStroke = Helpers.stroke(di, Color3.new(1, 1, 1), 1.5, 0.6)

local dil = Instance.new("TextLabel", di)
dil.Size = UDim2.new(1, -8, 1, 0)
dil.Position = UDim2.new(0, 4, 0, 0)
dil.BackgroundTransparency = 1
dil.Text = ""
dil.TextColor3 = Color3.new(1, 1, 1)
dil.Font = Enum.Font.GothamBold
dil.TextSize = 14
dil.TextXAlignment = Enum.TextXAlignment.Center
dil.ZIndex = 111

local dib = Instance.new("TextButton", di)
dib.Size = UDim2.new(1, 0, 1, 0)
dib.BackgroundTransparency = 1
dib.Text = ""
dib.ZIndex = 42

-- ================= DYNAMIC BAR SYSTEM =================
local iid = 0
local notifyQueue = {}
local isNotifying = false

local function processNotify()
    if #notifyQueue == 0 then isNotifying = false; return end
    isNotifying = true
    local info = table.remove(notifyQueue, 1)
    local text, color = info.text, info.color
    iid = iid + 1
    local my = iid
    dil.Text = text
    dil.TextColor3 = Color3.new(1, 1, 1)
    dil.TextTransparency = 0
    diStroke.Color = color or Color3.new(1, 1, 1)
    local textWidth = math.min(240, 12 * #text + 40)
    Helpers.tween(di, {Size = UDim2.new(0, textWidth, 0, 32), Position = UDim2.new(0.5, -textWidth/2, 0, 2)}, 0.25, Enum.EasingStyle.Back)
    task.delay(1.8, function()
        if iid ~= my then return end
        Helpers.tween(di, {Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(0.5, -45, 0, 4)}, 0.25)
        task.delay(0.3, function()
            if iid == my then dil.Text = ""; processNotify() end
        end)
    end)
end

function _G.showDynamicNotification(text, color)
    if appSettings.toastEnabled then
        table.insert(notifyQueue, {text = text, color = color})
        if not isNotifying then processNotify() end
    end
end

-- ================= HOME SCREEN =================
local sh = Instance.new("Frame", sa)
sh.Size = UDim2.new(1, 0, 1, -60)
sh.Position = UDim2.new(0, 0, 0, 34)
sh.BackgroundTransparency = 1
sh.ClipsDescendants = true

local home = Instance.new("Frame", sh)
home.Size = UDim2.new(1, 0, 1, 0)
home.BackgroundTransparency = 1
home.ClipsDescendants = true

local homeWall = Instance.new("Frame", home)
homeWall.Size = UDim2.new(1, 0, 1, 0)
homeWall.BackgroundColor3 = appSettings.bgColor or Color3.fromRGB(240, 240, 250)
homeWall.ZIndex = 0
Helpers.corner(homeWall, 30)

-- ================= DOCK =================
local dockArea = Instance.new("Frame", home)
dockArea.Size = UDim2.new(0, 224, 0, 64)
dockArea.Position = UDim2.new(0.5, -112, 1, -84)
dockArea.BackgroundTransparency = 1
dockArea.ZIndex = 5

local dockBg = Instance.new("Frame", dockArea)
dockBg.Size = UDim2.new(1, 0, 0, 56)
dockBg.Position = UDim2.new(0, 0, 0, 4)
dockBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dockBg.BackgroundTransparency = 0.1
Helpers.corner(dockBg, 20)

local dockGrid = Instance.new("UIGridLayout", dockBg)
dockGrid.CellSize = UDim2.new(0, 70, 0, 50)
dockGrid.CellPadding = UDim2.new(0, 2, 0, 0)
dockGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockGrid.VerticalAlignment = Enum.VerticalAlignment.Center
dockGrid.FillDirection = Enum.FillDirection.Horizontal

-- ================= APP GRID =================
local appGrid = Instance.new("ScrollingFrame", home)
appGrid.Size = UDim2.new(1, -16, 1, -156)
appGrid.Position = UDim2.new(0, 8, 0, 70)
appGrid.BackgroundTransparency = 1
appGrid.ScrollBarThickness = 3
appGrid.ScrollBarImageColor3 = T.Accent
appGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
appGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
appGrid.BorderSizePixel = 0

local gridLayout = Instance.new("UIGridLayout", appGrid)
gridLayout.CellSize = getGridIconSize()
gridLayout.CellPadding = UDim2.new(0, 10, 0, 12)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- ================= LOCK SCREEN =================
local lock = Instance.new("Frame", sa)
lock.Size = UDim2.new(1, 0, 1, 0)
lock.BackgroundColor3 = Color3.new(0, 0, 0)
lock.ZIndex = 80
lock.Visible = false
Helpers.corner(lock, 30)

local clockRing = Instance.new("Frame", lock)
clockRing.Size = UDim2.new(0, 160, 0, 160)
clockRing.Position = UDim2.new(0.5, -80, 0.2, 0)
clockRing.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
clockRing.BackgroundTransparency = 0.9
Helpers.corner(clockRing, 100)
Helpers.stroke(clockRing, Color3.fromRGB(255, 255, 255), 2, 0.3)

local cTime = Instance.new("TextLabel", clockRing)
cTime.Size = UDim2.new(1, 0, 0.4, 0)
cTime.Position = UDim2.new(0, 0, 0.2, 0)
cTime.BackgroundTransparency = 1
cTime.Text = os.date("%H:%M")
cTime.TextColor3 = Color3.new(1, 1, 1)
cTime.Font = Enum.Font.GothamBlack
cTime.TextSize = 38
cTime.TextScaled = true

local hint = Instance.new("TextLabel", lock)
hint.Size = UDim2.new(1, 0, 0, 30)
hint.Position = UDim2.new(0, 0, 0.88, 0)
hint.BackgroundTransparency = 1
hint.Text = "Click to unlock"
hint.TextColor3 = Color3.fromRGB(200, 200, 220)
hint.Font = Enum.Font.GothamBold
hint.TextSize = 13

lock.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        _G.showPass()
    end
end)

-- ================= PASSCODE =================
local pass = Instance.new("Frame", sa)
pass.Size = UDim2.new(1, 0, 1, 0)
pass.BackgroundColor3 = Color3.new(0, 0, 0)
pass.BackgroundTransparency = 0.3
pass.ZIndex = 90
pass.Visible = false
Helpers.corner(pass, 30)

local pTitle = Instance.new("TextLabel", pass)
pTitle.Size = UDim2.new(1, 0, 0, 40)
pTitle.Position = UDim2.new(0, 0, 0.1, 0)
pTitle.BackgroundTransparency = 1
pTitle.Text = "Enter Passcode"
pTitle.TextColor3 = Color3.new(1, 1, 1)
pTitle.Font = Enum.Font.GothamBold
pTitle.TextSize = 20

local dotsH = Instance.new("Frame", pass)
dotsH.Size = UDim2.new(0, 200, 0, 30)
dotsH.Position = UDim2.new(0.5, -100, 0.25, 0)
dotsH.BackgroundTransparency = 1

local dots = {}
for i = 1, 4 do
    local d = Instance.new("Frame", dotsH)
    d.Size = UDim2.new(0, 24, 0, 24)
    d.Position = UDim2.new(0, (i-1) * 56 + 8, 0.5, -12)
    d.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    Helpers.corner(d, 100)
    table.insert(dots, d)
end

local numpad = Instance.new("Frame", pass)
numpad.Size = UDim2.new(0.8, 0, 0.45, 0)
numpad.Position = UDim2.new(0.1, 0, 0.4, 0)
numpad.BackgroundTransparency = 1

local numLayout = Instance.new("UIGridLayout", numpad)
numLayout.CellSize = UDim2.new(0, 70, 0, 56)
numLayout.CellPadding = UDim2.new(0, 8, 0, 8)
numLayout.FillDirection = Enum.FillDirection.Horizontal
numLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
numLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local passEntry = ""

local function updateDots()
    for i, dot in ipairs(dots) do
        dot.BackgroundColor3 = i <= #passEntry and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
    end
end

local function onNum(n)
    if #passEntry >= 4 then return end
    passEntry = passEntry .. n
    updateDots()
    if #passEntry == 4 then
        task.wait(0.15)
        if passEntry == (appSettings.passcode or "2006") then
            _G.unlock()
        else
            passEntry = ""
            updateDots()
        end
    end
end

for _, n in ipairs({1, 2, 3, 4, 5, 6, 7, 8, 9}) do
    local b = Instance.new("TextButton", numpad)
    b.Text = tostring(n)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 24
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.AutoButtonColor = false
    Helpers.corner(b, 100)
    Helpers.pressFX(b)
    b.MouseButton1Click:Connect(function() onNum(tostring(n)) end)
end

local btn0 = Instance.new("TextButton", numpad)
btn0.Text = "0"
btn0.TextColor3 = Color3.new(1, 1, 1)
btn0.Font = Enum.Font.GothamBold
btn0.TextSize = 24
btn0.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btn0.AutoButtonColor = false
Helpers.corner(btn0, 100)
btn0.LayoutOrder = 11
Helpers.pressFX(btn0)
btn0.MouseButton1Click:Connect(function() onNum("0") end)

local btnDel = Instance.new("TextButton", numpad)
btnDel.Text = "Del"
btnDel.TextColor3 = Color3.new(1, 1, 1)
btnDel.Font = Enum.Font.Gotham
btnDel.TextSize = 18
btnDel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
btnDel.AutoButtonColor = false
Helpers.corner(btnDel, 100)
btnDel.LayoutOrder = 12
Helpers.pressFX(btnDel)
btnDel.MouseButton1Click:Connect(function()
    if #passEntry > 0 then passEntry = passEntry:sub(1, -2); updateDots() end
end)

-- ================= STATE =================
_G.PhoneState = {
    selectedPlayer = nil,
    isLocked = true,
    isCloning = false,
    toolEquipped = true,
}

-- ================= PHONE FUNCTIONS =================
function _G.showPass()
    lock.Visible = false
    pass.Visible = true
    passEntry = ""
    updateDots()
end

function _G.hidePass()
    pass.Visible = false
    lock.Visible = true
end

function _G.unlock()
    _G.PhoneState.isLocked = false
    lock.Visible = false
    pass.Visible = false
    _G.goHome()
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    Helpers.tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    if _G.PhoneState.isLocked then
        lock.Visible = true
        pass.Visible = false
    else
        _G.goHome()
    end
end

function _G.closePhone()
    if not phone.Visible then return end
    Helpers.tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function() phone.Visible = false end)
end

-- ================= EXPORT =================
return {
    gui = gui,
    phone = phone,
    sa = sa,
    sb = sb,
    clockLbl = clockLbl,
    di = di,
    dil = dil,
    diStroke = diStroke,
    dib = dib,
    lock = lock,
    pass = pass,
    home = home,
    homeWall = homeWall,
    sh = sh,
    dockArea = dockArea,
    dockBg = dockBg,
    dockGrid = dockGrid,
    appGrid = appGrid,
    gridLayout = gridLayout,
    isPortrait = isPortrait,
    getGridIconSize = getGridIconSize,
    PHONE_SIZE = PHONE_SIZE,
    applyPhoneOrientationSize = function()
        local cam = Services.Workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        if vp.X <= 0 or vp.Y <= 0 then return end
        local landscape = vp.X > vp.Y
        if landscape then
            local phoneW = math.min(vp.X - 10, 520)
            local phoneH = math.min(vp.Y - 10, 320)
            PHONE_SIZE = UDim2.new(0, phoneW, 0, phoneH)
            phone.Position = UDim2.new(0.5, 0, 0.5, 0)
        else
            PHONE_SIZE = PHONE_SIZE_PORTRAIT
            phone.Position = UDim2.new(0.5, 0, 0.52, 0)
        end
        if phone.Visible then
            Helpers.tween(phone, {Size = PHONE_SIZE, Position = phone.Position}, 0.3, Enum.EasingStyle.Quart)
        end
    end,
}