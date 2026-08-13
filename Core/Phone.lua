-- ================================================
-- PHONE GUI - Main Phone Frame & Lock Screen
-- ================================================

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local Storage = _G.Storage
local Firebase = _G.Firebase

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

-- Gradient untuk lock screen
local lockGradient = Instance.new("UIGradient", lock)
lockGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 5))
})
lockGradient.Rotation = 135

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

-- Update jam di lock screen
task.spawn(function()
    while cTime.Parent do
        local format = appSettings.clockFormat == "12" and "%I:%M %p" or "%H:%M"
        cTime.Text = os.date(format)
        task.wait(30)
    end
end)

local hint = Instance.new("TextLabel", lock)
hint.Size = UDim2.new(1, 0, 0, 30)
hint.Position = UDim2.new(0, 0, 0.88, 0)
hint.BackgroundTransparency = 1
hint.Text = "🔒 Click to enter key"
hint.TextColor3 = Color3.fromRGB(200, 200, 220)
hint.Font = Enum.Font.GothamBold
hint.TextSize = 13

lock.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        _G.showPass()
    end
end)

-- ================= KEY ENTRY SCREEN =================
local pass = Instance.new("Frame", sa)
pass.Size = UDim2.new(1, 0, 1, 0)
pass.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
pass.BackgroundTransparency = 0.15
pass.ZIndex = 90
pass.Visible = false
Helpers.corner(pass, 30)

-- Gradient background
local passGradient = Instance.new("UIGradient", pass)
passGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 10))
})
passGradient.Rotation = 45

-- Container untuk konten
local contentFrame = Instance.new("Frame", pass)
contentFrame.Size = UDim2.new(0.85, 0, 0.5, 0)
contentFrame.Position = UDim2.new(0.075, 0, 0.25, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 91

-- Icon lock
local lockIcon = Instance.new("TextLabel", contentFrame)
lockIcon.Size = UDim2.new(0, 60, 0, 60)
lockIcon.Position = UDim2.new(0.5, -30, 0, 0)
lockIcon.BackgroundTransparency = 1
lockIcon.Text = "🔒"
lockIcon.TextSize = 40
lockIcon.ZIndex = 92

-- Judul
local pTitle = Instance.new("TextLabel", contentFrame)
pTitle.Size = UDim2.new(1, 0, 0, 30)
pTitle.Position = UDim2.new(0, 0, 0, 70)
pTitle.BackgroundTransparency = 1
pTitle.Text = "ENTER ACCESS KEY"
pTitle.TextColor3 = Color3.new(1, 1, 1)
pTitle.Font = Enum.Font.GothamBlack
pTitle.TextSize = 18
pTitle.ZIndex = 92

-- Subtitle
local pSubtitle = Instance.new("TextLabel", contentFrame)
pSubtitle.Size = UDim2.new(1, 0, 0, 20)
pSubtitle.Position = UDim2.new(0, 0, 0, 105)
pSubtitle.BackgroundTransparency = 1
pSubtitle.Text = "Masukkan key untuk membuka"
pSubtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
pSubtitle.Font = Enum.Font.Gotham
pSubtitle.TextSize = 12
pSubtitle.ZIndex = 92

-- Input field
local keyInput = Instance.new("TextBox", contentFrame)
keyInput.Size = UDim2.new(1, 0, 0, 50)
keyInput.Position = UDim2.new(0, 0, 0, 140)
keyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
keyInput.BackgroundTransparency = 0.9
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 22
keyInput.TextXAlignment = Enum.TextXAlignment.Center
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 93
Helpers.corner(keyInput, 12)
Helpers.stroke(keyInput, Color3.fromRGB(0, 200, 255), 2, 0.5)

-- Status label
local statusLbl = Instance.new("TextLabel", contentFrame)
statusLbl.Size = UDim2.new(1, 0, 0, 30)
statusLbl.Position = UDim2.new(0, 0, 0, 200)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 12
statusLbl.ZIndex = 92

-- Loading spinner
local spinner = Instance.new("Frame", contentFrame)
spinner.Size = UDim2.new(0, 30, 0, 30)
spinner.Position = UDim2.new(0.5, -15, 0, 200)
spinner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
spinner.BackgroundTransparency = 1
spinner.Visible = false
spinner.ZIndex = 93

local spinnerDot = Instance.new("Frame", spinner)
spinnerDot.Size = UDim2.new(0, 20, 0, 20)
spinnerDot.Position = UDim2.new(0.5, -10, 0.5, -10)
spinnerDot.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
spinnerDot.ZIndex = 94
Helpers.corner(spinnerDot, 100)

-- Animasikan spinner
local function animateSpinner()
    task.spawn(function()
        while spinner.Visible do
            spinner.Rotation = (spinner.Rotation + 20) % 360
            task.wait(0.05)
        end
    end)
end

-- Tombol Unlock
local submitBtn = Instance.new("TextButton", contentFrame)
submitBtn.Size = UDim2.new(1, 0, 0, 50)
submitBtn.Position = UDim2.new(0, 0, 0, 240)
submitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.new(1, 1, 1)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 16
submitBtn.AutoButtonColor = false
submitBtn.ZIndex = 93
Helpers.corner(submitBtn, 12)
Helpers.pressFX(submitBtn)

-- Gradient untuk tombol
local btnGradient = Instance.new("UIGradient", submitBtn)
btnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 80))
})
btnGradient.Rotation = 90

-- Tombol back
local backBtn = Instance.new("TextButton", contentFrame)
backBtn.Size = UDim2.new(0.5, 0, 0, 35)
backBtn.Position = UDim2.new(0.25, 0, 0, 300)
backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
backBtn.Text = "Back"
backBtn.TextColor3 = Color3.new(1, 1, 1)
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 13
backBtn.AutoButtonColor = false
backBtn.ZIndex = 93
Helpers.corner(backBtn, 8)
Helpers.pressFX(backBtn)

-- Fungsi submit key
local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        statusLbl.Text = "⚠️ Masukkan key terlebih dahulu"
        statusLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    -- Tampilkan loading
    spinner.Visible = true
    animateSpinner()
    statusLbl.Text = ""
    keyInput.TextEditable = false
    submitBtn.Text = "MEMERIKSA..."
    submitBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Validasi ke Firebase (asynchronous)
    task.spawn(function()
        local isValid, message = Firebase.ValidateKey(key)
        
        task.wait(0.5) -- Delay untuk efek loading
        
        spinner.Visible = false
        keyInput.TextEditable = true
        submitBtn.Text = "UNLOCK"
        submitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        
        if isValid then
            -- Sukses
            statusLbl.Text = "✅ " .. (message or "Key valid!")
            statusLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            -- Animasi sukses
            Helpers.tween(submitBtn, {BackgroundColor3 = Color3.fromRGB(0, 255, 100)}, 0.3)
            
            task.wait(0.5)
            _G.unlock()
            statusLbl.Text = ""
        else
            -- Gagal
            statusLbl.Text = "❌ " .. (message or "Key tidak valid")
            statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            
            -- Shake effect
            Helpers.tween(keyInput, {Position = UDim2.new(0, -5, 0, 140)}, 0.05)
            task.wait(0.05)
            Helpers.tween(keyInput, {Position = UDim2.new(0, 5, 0, 140)}, 0.05)
            task.wait(0.05)
            Helpers.tween(keyInput, {Position = UDim2.new(0, 0, 0, 140)}, 0.05)
            
            -- Clear input
            keyInput.Text = ""
        end
    end)
end

submitBtn.MouseButton1Click:Connect(submitKey)

-- Back button
backBtn.MouseButton1Click:Connect(function()
    pass.Visible = false
    lock.Visible = true
    keyInput.Text = ""
    statusLbl.Text = ""
end)

-- Enter key
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitKey()
    end
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
    keyInput.Text = ""
    statusLbl.Text = ""
    -- Focus ke input
    task.wait(0.1)
    keyInput:CaptureFocus()
end

function _G.hidePass()
    pass.Visible = false
    lock.Visible = true
end

function _G.unlock()
    _G.PhoneState.isLocked = false
    lock.Visible = false
    pass.Visible = false
    keyInput.Text = ""
    statusLbl.Text = ""
    _G.goHome()
    Helpers.showDynamicNotification("Phone Unlocked! 🔓", Color3.fromRGB(0, 255, 100))
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    Helpers.tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    if _G.PhoneState.isLocked then
        lock.Visible = true
        pass.Visible = false
        -- Langsung tampilkan key entry setelah delay singkat
        task.wait(0.5)
        if lock.Visible and _G.PhoneState.isLocked then
            _G.showPass()
        end
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
}