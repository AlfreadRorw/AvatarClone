-- ================================================
-- PHONE GUI - Main Phone Frame
-- Dengan Key Entry Fullscreen & Auto-Login
-- ================================================

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local Storage = _G.Storage
local Firebase = _G.Firebase
local LocalPlayer = _G.LocalPlayer

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

-- ================= KEY ENTRY FULLSCREEN OVERLAY =================
-- Overlay fullscreen hitam yang menutupi semua
local keyOverlay = Instance.new("Frame", gui)  -- Langsung ke gui, bukan sa
keyOverlay.Size = UDim2.new(1, 0, 1, 0)
keyOverlay.Position = UDim2.new(0, 0, 0, 0)
keyOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyOverlay.BackgroundTransparency = 0  -- Sepenuhnya hitam (tidak transparan)
keyOverlay.ZIndex = 200  -- Di atas segalanya
keyOverlay.Visible = false
keyOverlay.BorderSizePixel = 0

-- Gradient untuk overlay
local overlayGradient = Instance.new("UIGradient", keyOverlay)
overlayGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5, 5, 10)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
})
overlayGradient.Rotation = 135

-- Container konten di tengah
local keyContent = Instance.new("Frame", keyOverlay)
keyContent.Size = UDim2.new(0, 280, 0, 400)
keyContent.Position = UDim2.new(0.5, -140, 0.5, -200)
keyContent.BackgroundTransparency = 1
keyContent.ZIndex = 201

-- Icon kunci (build dari Frame, bukan emoji)
local lockIconContainer = Instance.new("Frame", keyContent)
lockIconContainer.Size = UDim2.new(0, 60, 0, 60)
lockIconContainer.Position = UDim2.new(0.5, -30, 0, 0)
lockIconContainer.BackgroundTransparency = 1
lockIconContainer.ZIndex = 202

-- Body kunci (persegi panjang)
local lockBody = Instance.new("Frame", lockIconContainer)
lockBody.Size = UDim2.new(0, 36, 0, 28)
lockBody.Position = UDim2.new(0.5, -18, 0.5, -8)
lockBody.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
lockBody.ZIndex = 203
Helpers.corner(lockBody, 5)

-- Shackle kunci (lingkaran)
local lockShackle = Instance.new("Frame", lockIconContainer)
lockShackle.Size = UDim2.new(0, 20, 0, 24)
lockShackle.Position = UDim2.new(0.5, -10, 0.2, 0)
lockShackle.BackgroundTransparency = 1
lockShackle.ZIndex = 203
Helpers.stroke(lockShackle, Color3.fromRGB(0, 200, 255), 3, 0)
Helpers.corner(lockShackle, 100)

-- Keyhole (lingkaran kecil)
local keyhole = Instance.new("Frame", lockBody)
keyhole.Size = UDim2.new(0, 8, 0, 8)
keyhole.Position = UDim2.new(0.5, -4, 0.5, -4)
keyhole.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyhole.ZIndex = 204
Helpers.corner(keyhole, 100)

-- Judul
local keyTitle = Instance.new("TextLabel", keyContent)
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 80)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "ENTER ACCESS KEY"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 20
keyTitle.ZIndex = 202

-- Subtitle
local keySubtitle = Instance.new("TextLabel", keyContent)
keySubtitle.Size = UDim2.new(1, 0, 0, 20)
keySubtitle.Position = UDim2.new(0, 0, 0, 115)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "Key hanya bisa digunakan 1x per player"
keySubtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
keySubtitle.Font = Enum.Font.Gotham
keySubtitle.TextSize = 11
keySubtitle.ZIndex = 202

-- Input field
local keyInput = Instance.new("TextBox", keyContent)
keyInput.Size = UDim2.new(1, 0, 0, 50)
keyInput.Position = UDim2.new(0, 0, 0, 150)
keyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 20
keyInput.TextXAlignment = Enum.TextXAlignment.Center
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 203
Helpers.corner(keyInput, 12)
Helpers.stroke(keyInput, Color3.fromRGB(0, 200, 255), 2, 0.5)

-- Status label
local keyStatus = Instance.new("TextLabel", keyContent)
keyStatus.Size = UDim2.new(1, 0, 0, 30)
keyStatus.Position = UDim2.new(0, 0, 0, 210)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 12
keyStatus.ZIndex = 202

-- Loading spinner (build dari Frame)
local spinnerContainer = Instance.new("Frame", keyContent)
spinnerContainer.Size = UDim2.new(0, 30, 0, 30)
spinnerContainer.Position = UDim2.new(0.5, -15, 0, 210)
spinnerContainer.BackgroundTransparency = 1
spinnerContainer.Visible = false
spinnerContainer.ZIndex = 203

local spinnerRing = Instance.new("Frame", spinnerContainer)
spinnerRing.Size = UDim2.new(0, 24, 0, 24)
spinnerRing.Position = UDim2.new(0.5, -12, 0.5, -12)
spinnerRing.BackgroundTransparency = 1
spinnerRing.ZIndex = 204
Helpers.stroke(spinnerRing, Color3.fromRGB(0, 200, 255), 3, 0)
Helpers.corner(spinnerRing, 100)

local spinnerDot = Instance.new("Frame", spinnerRing)
spinnerDot.Size = UDim2.new(0, 6, 0, 6)
spinnerDot.Position = UDim2.new(0.5, -3, 0, -2)
spinnerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
spinnerDot.ZIndex = 205
Helpers.corner(spinnerDot, 100)

-- Animasikan spinner
local function animateSpinner()
    task.spawn(function()
        while spinnerContainer.Visible do
            spinnerRing.Rotation = (spinnerRing.Rotation + 20) % 360
            task.wait(0.05)
        end
    end)
end

-- Tombol Unlock
local keySubmitBtn = Instance.new("TextButton", keyContent)
keySubmitBtn.Size = UDim2.new(1, 0, 0, 50)
keySubmitBtn.Position = UDim2.new(0, 0, 0, 250)
keySubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
keySubmitBtn.Text = "UNLOCK"
keySubmitBtn.TextColor3 = Color3.new(1, 1, 1)
keySubmitBtn.Font = Enum.Font.GothamBlack
keySubmitBtn.TextSize = 16
keySubmitBtn.AutoButtonColor = false
keySubmitBtn.ZIndex = 203
Helpers.corner(keySubmitBtn, 12)
Helpers.pressFX(keySubmitBtn)

-- Gradient untuk tombol
local submitGradient = Instance.new("UIGradient", keySubmitBtn)
submitGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 80))
})
submitGradient.Rotation = 90

-- Info tambahan
local keyInfo = Instance.new("TextLabel", keyContent)
keyInfo.Size = UDim2.new(1, 0, 0, 20)
keyInfo.Position = UDim2.new(0, 0, 0, 315)
keyInfo.BackgroundTransparency = 1
keyInfo.Text = "Dapatkan key dari developer"
keyInfo.TextColor3 = Color3.fromRGB(100, 100, 120)
keyInfo.Font = Enum.Font.Gotham
keyInfo.TextSize = 10
keyInfo.ZIndex = 202

-- ================= FUNGSI KEY =================
local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        keyStatus.Text = "Masukkan key terlebih dahulu"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    -- Tampilkan loading
    spinnerContainer.Visible = true
    animateSpinner()
    keyStatus.Text = ""
    keyInput.TextEditable = false
    keySubmitBtn.Text = "MEMERIKSA..."
    
    -- Validasi ke Firebase
    task.spawn(function()
        local userId = LocalPlayer.UserId
        local isValid, message = Firebase.ValidateKey(key, userId)
        
        task.wait(0.5)
        
        spinnerContainer.Visible = false
        keyInput.TextEditable = true
        keySubmitBtn.Text = "UNLOCK"
        
        if isValid then
            -- Simpan key ke storage
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
            
            -- Shake effect
            Helpers.tween(keyInput, {Position = UDim2.new(0, -5, 0, 150)}, 0.05)
            task.wait(0.05)
            Helpers.tween(keyInput, {Position = UDim2.new(0, 5, 0, 150)}, 0.05)
            task.wait(0.05)
            Helpers.tween(keyInput, {Position = UDim2.new(0, 0, 0, 150)}, 0.05)
            
            keyInput.Text = ""
        end
    end)
end

keySubmitBtn.MouseButton1Click:Connect(submitKey)

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
function _G.showKeyEntry()
    keyOverlay.Visible = true
    keyInput.Text = ""
    keyStatus.Text = ""
    task.wait(0.1)
    keyInput:CaptureFocus()
end

function _G.hideKeyEntry()
    keyOverlay.Visible = false
end

function _G.unlock()
    _G.PhoneState.isLocked = false
    keyOverlay.Visible = false
    keyInput.Text = ""
    keyStatus.Text = ""
    _G.goHome()
    Helpers.showDynamicNotification("Phone Unlocked!", Color3.fromRGB(0, 255, 100))
end

function _G.checkAutoLogin()
    local savedKey = Storage.appSettings.savedKey
    if savedKey and savedKey ~= "" then
        local userId = LocalPlayer.UserId
        local isValid, message = Firebase.CheckSavedKey(userId, savedKey)
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
    Helpers.tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    
    if _G.PhoneState.isLocked then
        -- Coba auto-login
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
    Helpers.tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function() 
        phone.Visible = false 
        if _G.PhoneState.isLocked then
            keyOverlay.Visible = false
        end
    end)
end

-- ================= CHECK AUTO-LOGIN SAAT STARTUP =================
task.spawn(function()
    task.wait(1)
    if _G.checkAutoLogin() then
        print("[Phone] Auto-login berhasil!")
    else
        print("[Phone] Menunggu input key...")
    end
end)

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
    home = home,
    homeWall = homeWall,
    sh = sh,
    dockArea = dockArea,
    dockBg = dockBg,
    dockGrid = dockGrid,
    appGrid = appGrid,
    gridLayout = gridLayout,
    keyOverlay = keyOverlay,
    isPortrait = isPortrait,
    getGridIconSize = getGridIconSize,
    PHONE_SIZE = PHONE_SIZE,
}