-- ================================================
-- PHONE GUI - Main Phone Frame
-- Key Entry di Dalam Phone (Bukan Fullscreen)
-- ================================================

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local Storage = _G.Storage
local Firebase = _G.Firebase
local LocalPlayer = _G.LocalPlayer

local appSettings = Storage.appSettings

-- Helper aliases
local corner = Helpers.corner
local stroke = Helpers.stroke
local tween = Helpers.tween
local pressFX = Helpers.pressFX

-- ==================== GUI ROOT ====================
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

-- ==================== PHONE FRAME ====================
local phone = Instance.new("Frame", gui)
phone.Size = UDim2.new(0, 0, 0, 0)
phone.Position = UDim2.new(0.5, 0, 0.52, 0)
phone.AnchorPoint = Vector2.new(0.5, 0.5)
phone.BackgroundColor3 = appSettings.bgColor or T.BG
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
corner(phone, 38)
phone.BackgroundTransparency = 1 - (appSettings.phoneOpacity or 1)

local phoneStroke = stroke(phone, T.Accent, 2, appSettings.glowEnabled and 0.5 or 0.15)

-- ==================== ORIENTASI ====================
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

-- ==================== SCREEN AREA ====================
local sa = Instance.new("Frame", phone)
sa.Size = UDim2.new(1, -16, 1, -16)
sa.Position = UDim2.new(0, 8, 0, 8)
sa.BackgroundColor3 = T.BG
sa.BorderSizePixel = 0
sa.ClipsDescendants = true
corner(sa, 30)

-- ==================== STATUS BAR ====================
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

-- ==================== DYNAMIC ISLAND ====================
local di = Instance.new("Frame", sa)
di.Size = UDim2.new(0, 90, 0, 24)
di.Position = UDim2.new(0.5, -45, 0, 4)
di.BackgroundColor3 = Color3.new(0, 0, 0)
di.ZIndex = 110
corner(di, 100)

local diStroke = stroke(di, Color3.new(1, 1, 1), 1.5, 0.6)

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

-- ==================== DYNAMIC BAR SYSTEM ====================
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
    tween(di, {Size = UDim2.new(0, textWidth, 0, 32), Position = UDim2.new(0.5, -textWidth/2, 0, 2)}, 0.25, Enum.EasingStyle.Back)
    task.delay(1.8, function()
        if iid ~= my then return end
        tween(di, {Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(0.5, -45, 0, 4)}, 0.25)
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

-- ==================== HOME SCREEN ====================
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
corner(homeWall, 30)

-- ==================== DOCK ====================
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
corner(dockBg, 20)

local dockGrid = Instance.new("UIGridLayout", dockBg)
dockGrid.CellSize = UDim2.new(0, 70, 0, 50)
dockGrid.CellPadding = UDim2.new(0, 2, 0, 0)
dockGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockGrid.VerticalAlignment = Enum.VerticalAlignment.Center
dockGrid.FillDirection = Enum.FillDirection.Horizontal

-- ==================== APP GRID ====================
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

-- ==================== KEY ENTRY SCREEN (DI DALAM PHONE) ====================
local keyScreen = Instance.new("Frame", sa)
keyScreen.Size = UDim2.new(1, 0, 1, 0)
keyScreen.Position = UDim2.new(0, 0, 0, 0)
keyScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
keyScreen.ZIndex = 80
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
corner(keyScreen, 30)

-- ==================== KEY ENTRY CONTENT ====================
-- Icon kunci
local lockIconFrame = Instance.new("Frame", keyScreen)
lockIconFrame.Size = UDim2.new(0, 70, 0, 70)
lockIconFrame.Position = UDim2.new(0.5, -35, 0, 50)
lockIconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockIconFrame.BackgroundTransparency = 0.9
lockIconFrame.ZIndex = 81
corner(lockIconFrame, 100)
stroke(lockIconFrame, Color3.fromRGB(255, 255, 255), 2, 0.5)

-- Body kunci
local lockBody = Instance.new("Frame", lockIconFrame)
lockBody.Size = UDim2.new(0, 30, 0, 24)
lockBody.Position = UDim2.new(0.5, -15, 0.5, -5)
lockBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockBody.ZIndex = 82
corner(lockBody, 5)

-- Shackle
local lockShackle = Instance.new("Frame", lockIconFrame)
lockShackle.Size = UDim2.new(0, 18, 0, 20)
lockShackle.Position = UDim2.new(0.5, -9, 0.2, 0)
lockShackle.BackgroundTransparency = 1
lockShackle.ZIndex = 82
stroke(lockShackle, Color3.fromRGB(255, 255, 255), 3, 0)
corner(lockShackle, 100)

-- Keyhole
local keyhole = Instance.new("Frame", lockBody)
keyhole.Size = UDim2.new(0, 8, 0, 8)
keyhole.Position = UDim2.new(0.5, -4, 0.5, -4)
keyhole.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyhole.ZIndex = 83
corner(keyhole, 100)

-- Title
local keyTitle = Instance.new("TextLabel", keyScreen)
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 140)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "ACCESS KEY"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 20
keyTitle.ZIndex = 81

-- Subtitle
local keySub = Instance.new("TextLabel", keyScreen)
keySub.Size = UDim2.new(1, 0, 0, 20)
keySub.Position = UDim2.new(0, 0, 0, 175)
keySub.BackgroundTransparency = 1
keySub.Text = "Masukkan key untuk membuka phone"
keySub.TextColor3 = Color3.fromRGB(150, 150, 160)
keySub.Font = Enum.Font.Gotham
keySub.TextSize = 11
keySub.ZIndex = 81

-- Input field
local keyInput = Instance.new("TextBox", keyScreen)
keyInput.Size = UDim2.new(1, -40, 0, 45)
keyInput.Position = UDim2.new(0, 20, 0, 210)
keyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 18
keyInput.TextXAlignment = Enum.TextXAlignment.Center
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 82
corner(keyInput, 10)
stroke(keyInput, Color3.fromRGB(255, 255, 255), 1, 0.7)

-- Description di bawah text box
local keyDesc = Instance.new("TextLabel", keyScreen)
keyDesc.Size = UDim2.new(1, -40, 0, 40)
keyDesc.Position = UDim2.new(0, 20, 0, 258)
keyDesc.BackgroundTransparency = 1
keyDesc.Text = "Key hanya bisa digunakan 1x per player.\nKey akan otomatis terikat ke akun Roblox Anda."
keyDesc.TextColor3 = Color3.fromRGB(120, 120, 140)
keyDesc.Font = Enum.Font.Gotham
keyDesc.TextSize = 10
keyDesc.TextWrapped = true
keyDesc.TextXAlignment = Enum.TextXAlignment.Center
keyDesc.ZIndex = 81

-- Status label
local keyStatus = Instance.new("TextLabel", keyScreen)
keyStatus.Size = UDim2.new(1, 0, 0, 25)
keyStatus.Position = UDim2.new(0, 0, 0, 305)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 11
keyStatus.ZIndex = 81

-- Spinner
local spinnerFrame = Instance.new("Frame", keyScreen)
spinnerFrame.Size = UDim2.new(0, 30, 0, 30)
spinnerFrame.Position = UDim2.new(0.5, -15, 0, 305)
spinnerFrame.BackgroundTransparency = 1
spinnerFrame.Visible = false
spinnerFrame.ZIndex = 82

local spinnerRing = Instance.new("Frame", spinnerFrame)
spinnerRing.Size = UDim2.new(0, 24, 0, 24)
spinnerRing.Position = UDim2.new(0.5, -12, 0.5, -12)
spinnerRing.BackgroundTransparency = 1
spinnerRing.ZIndex = 83
stroke(spinnerRing, Color3.fromRGB(255, 255, 255), 3, 0)
corner(spinnerRing, 100)

local spinnerDot = Instance.new("Frame", spinnerRing)
spinnerDot.Size = UDim2.new(0, 6, 0, 6)
spinnerDot.Position = UDim2.new(0.5, -3, 0, -2)
spinnerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
spinnerDot.ZIndex = 84
corner(spinnerDot, 100)

local function animateSpinner()
    task.spawn(function()
        while spinnerFrame.Visible do
            spinnerRing.Rotation = (spinnerRing.Rotation + 20) % 360
            task.wait(0.05)
        end
    end)
end

-- Submit button
local submitBtn = Instance.new("TextButton", keyScreen)
submitBtn.Size = UDim2.new(1, -40, 0, 45)
submitBtn.Position = UDim2.new(0, 20, 0, 340)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 15
submitBtn.AutoButtonColor = false
submitBtn.ZIndex = 82
corner(submitBtn, 10)
pressFX(submitBtn)

-- Buy button
local buyBtn = Instance.new("TextButton", keyScreen)
buyBtn.Size = UDim2.new(1, -40, 0, 40)
buyBtn.Position = UDim2.new(0, 20, 0, 395)
buyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
buyBtn.Text = "BUY KEY"
buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 13
buyBtn.AutoButtonColor = false
buyBtn.ZIndex = 82
corner(buyBtn, 10)
stroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.5)
pressFX(buyBtn)

-- Info bawah
local keyInfo = Instance.new("TextLabel", keyScreen)
keyInfo.Size = UDim2.new(1, 0, 0, 20)
keyInfo.Position = UDim2.new(0, 0, 0, 445)
keyInfo.BackgroundTransparency = 1
keyInfo.Text = "1 key = 1 player | Auto-lock saat expired"
keyInfo.TextColor3 = Color3.fromRGB(80, 80, 90)
keyInfo.Font = Enum.Font.Gotham
keyInfo.TextSize = 9
keyInfo.ZIndex = 81

-- Buy button click
buyBtn.MouseButton1Click:Connect(function()
    local url = Config.BUY_KEY_URL or "https://discord.gg/"
    -- Buka link di browser
    pcall(function()
        setclipboard(url)
    end)
    _G.showDynamicNotification("Link copied to clipboard!", Color3.fromRGB(255, 200, 50))
    keyStatus.Text = "Link: " .. url
    keyStatus.TextColor3 = Color3.fromRGB(0, 200, 255)
end)

-- ==================== KEY FUNCTIONS ====================
local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        keyStatus.Text = "Masukkan key terlebih dahulu"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    spinnerFrame.Visible = true
    animateSpinner()
    keyStatus.Text = ""
    keyInput.TextEditable = false
    submitBtn.Text = "CHECKING..."
    
    task.spawn(function()
        local userId = LocalPlayer.UserId
        local isValid, message = Firebase.ValidateKey(key, userId)
        
        task.wait(0.5)
        
        spinnerFrame.Visible = false
        keyInput.TextEditable = true
        submitBtn.Text = "UNLOCK"
        
        if isValid then
            Storage.appSettings.savedKey = key
            Storage.persistSettings()
            
            keyStatus.Text = message or "Key valid!"
            keyStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
            
            task.wait(0.5)
            _G.unlock()
            keyStatus.Text = ""
        else
            keyStatus.Text = message or "Key tidak valid"
            keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            
            -- Shake
            tween(keyInput, {Position = UDim2.new(0, 15, 0, 210)}, 0.05)
            task.wait(0.05)
            tween(keyInput, {Position = UDim2.new(0, 25, 0, 210)}, 0.05)
            task.wait(0.05)
            tween(keyInput, {Position = UDim2.new(0, 20, 0, 210)}, 0.05)
            
            keyInput.Text = ""
        end
    end)
end

submitBtn.MouseButton1Click:Connect(submitKey)

keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitKey()
    end
end)

-- ==================== STATE ====================
_G.PhoneState = {
    selectedPlayer = nil,
    isLocked = true,
    isCloning = false,
    toolEquipped = true,
}

-- ==================== PHONE FUNCTIONS ====================
function _G.showKeyEntry()
    keyScreen.Visible = true
    keyInput.Text = ""
    keyStatus.Text = ""
    task.wait(0.1)
    keyInput:CaptureFocus()
end

function _G.hideKeyEntry()
    keyScreen.Visible = false
end

function _G.unlock()
    _G.PhoneState.isLocked = false
    keyScreen.Visible = false
    keyInput.Text = ""
    keyStatus.Text = ""
    _G.goHome()
    _G.showDynamicNotification("Phone Unlocked!", Color3.fromRGB(0, 255, 100))
end

function _G.checkAutoLogin()
    local savedKey = Storage.appSettings.savedKey
    if savedKey and savedKey ~= "" then
        local userId = LocalPlayer.UserId
        local isValid = Firebase.CheckSavedKey(userId, savedKey)
        if isValid then
            _G.PhoneState.isLocked = false
            return true
        end
    end
    return false
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    
    if _G.PhoneState.isLocked then
        if not _G.checkAutoLogin() then
            task.wait(0.5)
            _G.showKeyEntry()
        else
            _G.goHome()
        end
    else
        _G.goHome()
    end
end

function _G.closePhone()
    if not phone.Visible then return end
    tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function()
        phone.Visible = false
    end)
end

-- Auto-login check at startup
task.spawn(function()
    task.wait(1)
    if _G.checkAutoLogin() then
        print("[Phone] Auto-login berhasil!")
    else
        print("[Phone] Menunggu input key...")
    end
end)

-- ==================== EXPORT ====================
return {
    gui = gui,
    phone = phone,
    sa = sa,
    sb = sb,
    clockLbl = clockLbl,
    di = di,
    dil = dil,
    diStroke = diStroke,
    home = home,
    homeWall = homeWall,
    sh = sh,
    dockArea = dockArea,
    dockBg = dockBg,
    dockGrid = dockGrid,
    appGrid = appGrid,
    gridLayout = gridLayout,
    keyScreen = keyScreen,
    isPortrait = isPortrait,
    getGridIconSize = getGridIconSize,
    PHONE_SIZE = PHONE_SIZE,
}