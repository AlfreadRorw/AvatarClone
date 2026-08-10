local T        = _G.T
local Helpers  = _G.Helpers
local Storage  = _G.Storage
local Config   = _G.Config
local UIS      = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players  = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

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
if appSettings.bgGradient then
    Helpers.gradient(phone, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(250,250,250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230,230,230))
    }, 100)
end

-- Size constants
local PHONE_SIZE_PORTRAIT = UDim2.new(0, 320, 0, 560)
local PHONE_SIZE = PHONE_SIZE_PORTRAIT

local function isPortrait()
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    return cam.ViewportSize.Y >= cam.ViewportSize.X
end

-- Screen area
local sa = Instance.new("Frame", phone)
sa.Size = UDim2.new(1, -16, 1, -16)
sa.Position = UDim2.new(0, 8, 0, 8)
sa.BackgroundColor3 = T.BG
sa.BorderSizePixel = 0
sa.ClipsDescendants = true
Helpers.corner(sa, 30)

-- Status bar
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
        clockLbl.Text = os.date("%H:%M")
        task.wait(30)
    end
end)

-- Signal bars
local sbSignal = Instance.new("Frame", sb)
sbSignal.Size = UDim2.new(0, 20, 0, 14)
sbSignal.Position = UDim2.new(1, -80, 0.5, -7)
sbSignal.BackgroundTransparency = 1
sbSignal.ZIndex = 102
for i = 1, 4 do
    local bar = Instance.new("Frame", sbSignal)
    bar.Size = UDim2.new(0, 3, 0, 3 + i * 2)
    bar.Position = UDim2.new(0, (i-1)*5, 1, 0)
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.BackgroundColor3 = T.Text
    bar.BorderSizePixel = 0
    bar.ZIndex = 103
    Helpers.corner(bar, 1)
end

-- Battery
local sbBatFrame = Instance.new("Frame", sb)
sbBatFrame.Size = UDim2.new(0, 26, 0, 14)
sbBatFrame.Position = UDim2.new(1, -50, 0.5, -7)
sbBatFrame.BackgroundTransparency = 1
sbBatFrame.ZIndex = 102

local sbBatBody = Instance.new("Frame", sbBatFrame)
sbBatBody.Size = UDim2.new(0, 20, 0, 12)
sbBatBody.Position = UDim2.new(0, 0, 0.5, -6)
sbBatBody.BackgroundColor3 = T.Text
sbBatBody.BackgroundTransparency = 0.85
sbBatBody.BorderSizePixel = 0
sbBatBody.ZIndex = 103
Helpers.corner(sbBatBody, 3)
Helpers.stroke(sbBatBody, T.Text, 1, 0.3)

local sbBatFill = Instance.new("Frame", sbBatBody)
sbBatFill.Size = UDim2.new(0.75, -2, 1, -4)
sbBatFill.Position = UDim2.new(0, 1, 0, 2)
sbBatFill.BackgroundColor3 = T.Text
sbBatFill.BorderSizePixel = 0
sbBatFill.ZIndex = 104
Helpers.corner(sbBatFill, 2)

local sbBatTip = Instance.new("Frame", sbBatFrame)
sbBatTip.Size = UDim2.new(0, 3, 0, 5)
sbBatTip.Position = UDim2.new(0, 21, 0.5, -2)
sbBatTip.BackgroundColor3 = T.Text
sbBatTip.BackgroundTransparency = 0.5
sbBatTip.BorderSizePixel = 0
sbBatTip.ZIndex = 103
Helpers.corner(sbBatTip, 1)

-- Dynamic Island
local di = Instance.new("Frame", sa)
di.Size = UDim2.new(0, 90, 0, 24)
di.Position = UDim2.new(0.5, -45, 0, 4)
di.BackgroundColor3 = Color3.new(0, 0, 0)
di.ZIndex = 110
Helpers.corner(di, 100)

local diStroke = Helpers.stroke(di, Color3.new(1,1,1), 1.5, 0.6)
local dil = Instance.new("TextLabel", di)
dil.Size = UDim2.new(1,-8,1,0)
dil.Position = UDim2.new(0,4,0,0)
dil.BackgroundTransparency = 1
dil.Text = ""
dil.TextColor3 = Color3.new(1,1,1)
dil.Font = Enum.Font.GothamBold
dil.TextSize = 14
dil.TextXAlignment = Enum.TextXAlignment.Center
dil.ZIndex = 111

local dib = Instance.new("TextButton", di)
dib.Size = UDim2.new(1,0,1,0)
dib.BackgroundTransparency = 1
dib.Text = ""
dib.ZIndex = 42

-- Expose DI ke Helpers
_G.PhoneDI  = di
_G.PhoneDIL = dil
_G.PhoneDIS = diStroke

-- Home screen container
local sh = Instance.new("Frame", sa)
sh.Size = UDim2.new(1,0,1,-60)
sh.Position = UDim2.new(0,0,0,34)
sh.BackgroundTransparency = 1
sh.ClipsDescendants = true

local home = Instance.new("Frame", sh)
home.Size = UDim2.new(1,0,1,0)
home.BackgroundTransparency = 1
home.ClipsDescendants = true

local homeWall = Instance.new("Frame", home)
homeWall.Size = UDim2.new(1,0,1,0)
homeWall.BackgroundColor3 = appSettings.bgColor or Color3.fromRGB(240,240,250)
homeWall.ZIndex = 0
Helpers.corner(homeWall, 30)
if appSettings.bgGradient then
    Helpers.gradient(homeWall, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220,220,240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(250,250,255))
    }, 135)
end

-- Dock
local dockArea = Instance.new("Frame", home)
dockArea.Size = UDim2.new(0,224,0,64)
dockArea.Position = UDim2.new(0.5,-112,1,-84)
dockArea.BackgroundTransparency = 1
dockArea.ZIndex = 5

local dockBg = Instance.new("Frame", dockArea)
dockBg.Size = UDim2.new(1,0,0,56)
dockBg.Position = UDim2.new(0,0,0,4)
dockBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
dockBg.BackgroundTransparency = 0.1
Helpers.corner(dockBg, 20)

local dockGrid = Instance.new("UIGridLayout", dockBg)
dockGrid.CellSize = UDim2.new(0,70,0,50)
dockGrid.CellPadding = UDim2.new(0,2,0,0)
dockGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockGrid.VerticalAlignment = Enum.VerticalAlignment.Center
dockGrid.FillDirection = Enum.FillDirection.Horizontal

-- App Grid
local appGrid = Instance.new("ScrollingFrame", home)
appGrid.Size = UDim2.new(1,-16,1,-156)
appGrid.Position = UDim2.new(0,8,0,70)
appGrid.BackgroundTransparency = 1
appGrid.ScrollBarThickness = 3
appGrid.ScrollBarImageColor3 = T.Accent
appGrid.CanvasSize = UDim2.new(0,0,0,0)
appGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
appGrid.BorderSizePixel = 0

local gridLayout = Instance.new("UIGridLayout", appGrid)
gridLayout.CellSize = UDim2.new(0,72,0,86)
gridLayout.CellPadding = UDim2.new(0,10,0,12)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- App Screen
local appScr = Instance.new("Frame", sh)
appScr.Size = UDim2.new(1,0,1,0)
appScr.Position = UDim2.new(1,0,0,0)
appScr.BackgroundTransparency = 1
appScr.BackgroundColor3 = T.BG
appScr.ClipsDescendants = true

local appHdr = Instance.new("Frame", appScr)
appHdr.Size = UDim2.new(1,-12,0,36)
appHdr.Position = UDim2.new(0,6,0,0)
appHdr.BackgroundTransparency = 1

local backBtn = Instance.new("TextButton", appHdr)
backBtn.Size = UDim2.new(0,50,0,28)
backBtn.Position = UDim2.new(0,0,0,4)
backBtn.BackgroundColor3 = T.Card
backBtn.Text = "< Back"
backBtn.TextColor3 = T.Text
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 11
backBtn.AutoButtonColor = false
Helpers.corner(backBtn, 8)
Helpers.stroke(backBtn, T.Border, 1, 0.3)
Helpers.pressFX(backBtn)

local appTitle = Instance.new("TextLabel", appHdr)
appTitle.Size = UDim2.new(1,-120,0,28)
appTitle.Position = UDim2.new(0,56,0,4)
appTitle.BackgroundTransparency = 1
appTitle.Text = ""
appTitle.TextColor3 = T.Text
appTitle.Font = Enum.Font.GothamBlack
appTitle.TextSize = 14
appTitle.TextXAlignment = Enum.TextXAlignment.Left

local appContent = Instance.new("ScrollingFrame", appScr)
appContent.Size = UDim2.new(1,-12,1,-44)
appContent.Position = UDim2.new(0,6,0,42)
appContent.BackgroundTransparency = 1
appContent.BorderSizePixel = 0
appContent.ScrollBarThickness = 3
appContent.ScrollBarImageColor3 = T.Accent
appContent.CanvasSize = UDim2.new(0,0,0,0)
appContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

local acl = Instance.new("UIListLayout", appContent)
acl.Padding = UDim.new(0,8)
acl.SortOrder = Enum.SortOrder.LayoutOrder

-- Lock screen
local lock = Instance.new("Frame", sa)
lock.Size = UDim2.new(1,0,1,0)
lock.BackgroundColor3 = Color3.new(0,0,0)
lock.ZIndex = 80
lock.Visible = false
Helpers.corner(lock, 30)

local lockBg = Instance.new("Frame", lock)
lockBg.Size = UDim2.new(1,0,1,0)
lockBg.BackgroundColor3 = Color3.fromRGB(20,20,30)
Helpers.corner(lockBg, 30)
Helpers.gradient(lockBg, ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45,45,65)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30,20,50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15,10,30))
}, 135)
lockBg.ZIndex = 81

local clockRing = Instance.new("Frame", lock)
clockRing.Size = UDim2.new(0,160,0,160)
clockRing.Position = UDim2.new(0.5,-80,0.2,0)
clockRing.BackgroundColor3 = Color3.fromRGB(255,255,255)
clockRing.BackgroundTransparency = 0.9
Helpers.corner(clockRing, 100)
clockRing.ZIndex = 83
Helpers.stroke(clockRing, Color3.fromRGB(255,255,255), 2, 0.3)

local cTime = Instance.new("TextLabel", clockRing)
cTime.Size = UDim2.new(1,0,0.4,0)
cTime.Position = UDim2.new(0,0,0.2,0)
cTime.BackgroundTransparency = 1
cTime.Text = os.date("%H:%M")
cTime.TextColor3 = Color3.new(1,1,1)
cTime.Font = Enum.Font.GothamBlack
cTime.TextSize = 38
cTime.TextScaled = true
cTime.ZIndex = 84

local dLabel = Instance.new("TextLabel", clockRing)
dLabel.Size = UDim2.new(1,0,0.2,0)
dLabel.Position = UDim2.new(0,0,0.65,0)
dLabel.BackgroundTransparency = 1
dLabel.Text = os.date("%A, %d %B")
dLabel.TextColor3 = Color3.fromRGB(220,220,240)
dLabel.Font = Enum.Font.Gotham
dLabel.TextSize = 5
dLabel.TextScaled = true
dLabel.ZIndex = 84

task.spawn(function()
    while cTime.Parent do
        cTime.Text = os.date("%H:%M")
        dLabel.Text = os.date("%A, %d %B")
        task.wait(10)
    end
end)

local brandFrame = Instance.new("Frame", lock)
brandFrame.Size = UDim2.new(0,200,0,50)
brandFrame.Position = UDim2.new(0.5,-100,0.52,0)
brandFrame.BackgroundTransparency = 1
brandFrame.ZIndex = 84

local bunkerLbl = Instance.new("TextLabel", brandFrame)
bunkerLbl.Size = UDim2.new(1,0,0,28)
bunkerLbl.BackgroundTransparency = 1
bunkerLbl.Text = "The Bunker"
bunkerLbl.TextColor3 = Color3.new(1,1,1)
bunkerLbl.Font = Enum.Font.GothamBlack
bunkerLbl.TextSize = 22
bunkerLbl.ZIndex = 84

local byLbl = Instance.new("TextLabel", brandFrame)
byLbl.Size = UDim2.new(1,0,0,16)
byLbl.Position = UDim2.new(0,0,0,30)
byLbl.BackgroundTransparency = 1
byLbl.Text = "by alfread"
byLbl.TextColor3 = Color3.fromRGB(200,200,220)
byLbl.Font = Enum.Font.Gotham
byLbl.TextSize = 12
byLbl.ZIndex = 84

local hint = Instance.new("TextLabel", lock)
hint.Size = UDim2.new(1,0,0,30)
hint.Position = UDim2.new(0,0,0.88,0)
hint.BackgroundTransparency = 1
hint.Text = "Click buat buka"
hint.TextColor3 = Color3.fromRGB(200,200,220)
hint.Font = Enum.Font.GothamBold
hint.TextSize = 13
hint.ZIndex = 83

-- Passcode screen
local pass = Instance.new("Frame", sa)
pass.Size = UDim2.new(1,0,1,0)
pass.BackgroundColor3 = Color3.new(0,0,0)
pass.BackgroundTransparency = 0.3
pass.ZIndex = 90
pass.Visible = false
Helpers.corner(pass, 30)

local pTitle = Instance.new("TextLabel", pass)
pTitle.Size = UDim2.new(1,0,0,40)
pTitle.Position = UDim2.new(0,0,0.1,0)
pTitle.BackgroundTransparency = 1
pTitle.Text = "Enter Passcode"
pTitle.TextColor3 = Color3.new(1,1,1)
pTitle.Font = Enum.Font.GothamBold
pTitle.TextSize = 20
pTitle.ZIndex = 91

local dotsH = Instance.new("Frame", pass)
dotsH.Size = UDim2.new(0,200,0,30)
dotsH.Position = UDim2.new(0.5,-100,0.25,0)
dotsH.BackgroundTransparency = 1
dotsH.ZIndex = 91

local dots = {}
for i = 1, 4 do
    local d = Instance.new("Frame", dotsH)
    d.Size = UDim2.new(0,24,0,24)
    d.Position = UDim2.new(0,(i-1)*56+8,0.5,-12)
    d.BackgroundColor3 = Color3.fromRGB(100,100,100)
    Helpers.corner(d, 100)
    d.ZIndex = 92
    table.insert(dots, d)
end

local numpad = Instance.new("Frame", pass)
numpad.Size = UDim2.new(0.8,0,0.45,0)
numpad.Position = UDim2.new(0.1,0,0.4,0)
numpad.BackgroundTransparency = 1
numpad.ZIndex = 91

local numLayout = Instance.new("UIGridLayout", numpad)
numLayout.CellSize = UDim2.new(0,70,0,56)
numLayout.CellPadding = UDim2.new(0,8,0,8)
numLayout.FillDirection = Enum.FillDirection.Horizontal
numLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
numLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function updateDots()
    local passEntry = _G.PhoneState.passEntry
    for i, dot in ipairs(dots) do
        dot.BackgroundColor3 = i <= #passEntry
            and Color3.fromRGB(255,255,255)
            or  Color3.fromRGB(100,100,100)
    end
end

-- Functions
local function showPass() lock.Visible=false; pass.Visible=true; _G.PhoneState.passEntry=""; updateDots() end
local function hidePass() pass.Visible=false; lock.Visible=true end

local function goHome()
    if _G.PhoneState.isLocked then return end
    home.Visible = true
    appScr.BackgroundTransparency = 1
    Helpers.tween(appScr, {Position=UDim2.new(1,0,0,0)}, 0.28, Enum.EasingStyle.Quart)
    Helpers.tween(home, {Position=UDim2.new(0,0,0,0)}, 0.28, Enum.EasingStyle.Quart)
end

local function clearAppContent()
    for _, c in ipairs(appContent:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local currOpener = nil
local function openApp(title, fn)
    if _G.PhoneState.isLocked then return end
    home.Visible = false
    appScr.BackgroundTransparency = 0
    appScr.BackgroundColor3 = T.BG
    appTitle.Text = title
    clearAppContent()
    currOpener = fn
    fn()
    appScr.Position = UDim2.new(1,0,0,0)
    Helpers.tween(appScr, {Position=UDim2.new(0,0,0,0)}, 0.28, Enum.EasingStyle.Quart)
    Helpers.tween(home, {Position=UDim2.new(0,0,0,0)}, 0.28, Enum.EasingStyle.Quart)
    Helpers.showDynamicNotification(title, T.Accent)
end

local function refreshCurr()
    if currOpener then clearAppContent(); currOpener() end
end

local function unlock()
    _G.PhoneState.isLocked = false
    lock.Visible = false
    pass.Visible = false
    _G.PhoneState.lastAutoLockTime = tick()
    goHome()
end

local function onNum(n)
    local state = _G.PhoneState
    if #state.passEntry >= 4 then return end
    state.passEntry = state.passEntry .. n
    updateDots()
    if #state.passEntry == 4 then
        task.wait(0.15)
        if state.passEntry == (Storage.appSettings.passcode or "2006") then
            unlock()
        else
            for _, dot in ipairs(dots) do
                Helpers.tween(dot, {Position = dot.Position + UDim2.new(0,10,0,0)}, 0.05)
                task.wait(0.05)
                Helpers.tween(dot, {Position = dot.Position - UDim2.new(0,20,0,0)}, 0.05)
                task.wait(0.05)
                Helpers.tween(dot, {Position = dot.Position + UDim2.new(0,10,0,0)}, 0.05)
            end
            state.passEntry = ""
            updateDots()
        end
    end
end

-- Numpad buttons
for _, n in ipairs({1,2,3,4,5,6,7,8,9}) do
    local b = Instance.new("TextButton", numpad)
    b.Text = tostring(n)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 24
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.AutoButtonColor = false
    Helpers.corner(b, 100)
    b.ZIndex = 92
    Helpers.pressFX(b)
    b.MouseButton1Click:Connect(function() onNum(tostring(n)) end)
end

local btnCancel = Instance.new("TextButton", numpad)
btnCancel.Text = "Cancel"
btnCancel.TextColor3 = Color3.fromRGB(255,200,200)
btnCancel.Font = Enum.Font.Gotham
btnCancel.TextSize = 14
btnCancel.BackgroundColor3 = Color3.fromRGB(80,40,40)
btnCancel.AutoButtonColor = false
Helpers.corner(btnCancel, 100)
btnCancel.ZIndex = 92
btnCancel.LayoutOrder = 10
Helpers.pressFX(btnCancel)
btnCancel.MouseButton1Click:Connect(function()
    _G.PhoneState.passEntry = ""
    updateDots()
    hidePass()
end)

local btn0 = Instance.new("TextButton", numpad)
btn0.Text = "0"
btn0.TextColor3 = Color3.new(1,1,1)
btn0.Font = Enum.Font.GothamBold
btn0.TextSize = 24
btn0.BackgroundColor3 = Color3.fromRGB(50,50,50)
btn0.AutoButtonColor = false
Helpers.corner(btn0, 100)
btn0.ZIndex = 92
btn0.LayoutOrder = 11
Helpers.pressFX(btn0)
btn0.MouseButton1Click:Connect(function() onNum("0") end)

local btnDel = Instance.new("TextButton", numpad)
btnDel.Text = "Del"
btnDel.TextColor3 = Color3.new(1,1,1)
btnDel.Font = Enum.Font.Gotham
btnDel.TextSize = 18
btnDel.BackgroundColor3 = Color3.fromRGB(70,70,70)
btnDel.AutoButtonColor = false
Helpers.corner(btnDel, 100)
btnDel.ZIndex = 92
btnDel.LayoutOrder = 12
Helpers.pressFX(btnDel)
btnDel.MouseButton1Click:Connect(function()
    local s = _G.PhoneState
    if #s.passEntry > 0 then
        s.passEntry = s.passEntry:sub(1,-2)
        updateDots()
    end
end)

lock.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        showPass()
    end
end)

dib.MouseButton1Click:Connect(function()
    if appScr.Position.X.Scale == 0 then goHome() end
end)

backBtn.MouseButton1Click:Connect(goHome)

-- Auto lock
UIS.InputBegan:Connect(function()
    _G.PhoneState.lastAutoLockTime = tick()
end)

task.spawn(function()
    while true do
        task.wait(5)
        local s = _G.PhoneState
        local settings = Storage.appSettings
        if settings.autoLockSeconds > 0 and not s.isLocked then
            if tick() - s.lastAutoLockTime > settings.autoLockSeconds then
                s.isLocked = true
                lock.Visible = true
                pass.Visible = false
            end
        end
    end
end)

-- Expose globals
_G.phone       = phone
_G.phoneStroke = phoneStroke
_G.homeWall    = homeWall
_G.appGrid     = appGrid
_G.dockBg      = dockBg
_G.appContent  = appContent
_G.appTitle    = appTitle
_G.openApp     = openApp
_G.goHome      = goHome
_G.refreshCurr = refreshCurr
_G.clearAppContent = clearAppContent

return {
    phone       = phone,
    phoneStroke = phoneStroke,
    homeWall    = homeWall,
    appGrid     = appGrid,
    dockBg      = dockBg,
    appContent  = appContent,
    appTitle    = appTitle,
    openApp     = openApp,
    goHome      = goHome,
    refreshCurr = refreshCurr,
}