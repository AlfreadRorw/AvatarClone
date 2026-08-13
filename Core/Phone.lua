-- ================================================
-- PHONE GUI - Complete with Auto-Login & Online Tracking
-- ================================================

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local LocalPlayer = _G.LocalPlayer
local MarketplaceService = Services.MarketplaceService

local Storage = _G.Storage
local Firebase = _G.Firebase

local corner = Helpers.corner or function(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = o
    return c
end

local stroke = Helpers.stroke or function(o, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or Color3.fromRGB(200, 200, 200)
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.Parent = o
    return s
end

local tween = Helpers.tween or function(o, p, tm, st)
    game:GetService("TweenService"):Create(o, TweenInfo.new(tm or 0.25, st or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p):Play()
end

local pressFX = Helpers.pressFX or function(b)
    local orig = b.Size
    b.MouseButton1Down:Connect(function()
        tween(b, {Size = UDim2.new(orig.X.Scale * 0.95, orig.X.Offset * 0.95, orig.Y.Scale * 0.95, orig.Y.Offset * 0.95)}, 0.1)
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, {Size = orig}, 0.1)
    end)
end

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
phone.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
corner(phone, 38)
phone.BackgroundTransparency = 0

stroke(phone, T.Accent or Color3.fromRGB(30, 30, 30), 2, 0.15)

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
sa.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
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
clockLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
clockLbl.Font = Enum.Font.GothamBold
clockLbl.TextSize = 13
clockLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while clockLbl.Parent do
        clockLbl.Text = os.date("%H:%M")
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

-- ==================== DYNAMIC BAR ====================
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
    table.insert(notifyQueue, {text = text, color = color})
    if not isNotifying then processNotify() end
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
homeWall.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
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
appGrid.ScrollBarImageColor3 = T.Accent or Color3.fromRGB(30, 30, 30)
appGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
appGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
appGrid.BorderSizePixel = 0

local gridLayout = Instance.new("UIGridLayout", appGrid)
gridLayout.CellSize = getGridIconSize()
gridLayout.CellPadding = UDim2.new(0, 10, 0, 12)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- ==================== KEY SCREEN ====================
local keyScreen = Instance.new("Frame", sa)
keyScreen.Size = UDim2.new(1, 0, 1, 0)
keyScreen.Position = UDim2.new(0, 0, 0, 0)
keyScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
keyScreen.ZIndex = 80
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
corner(keyScreen, 30)

local keyTitle = Instance.new("TextLabel", keyScreen)
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.new(0, 0, 0, 100)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "ACCESS KEY"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 20
keyTitle.ZIndex = 81

local keyInput = Instance.new("TextBox", keyScreen)
keyInput.Size = UDim2.new(1, -40, 0, 45)
keyInput.Position = UDim2.new(0, 20, 0, 150)
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

local keyStatus = Instance.new("TextLabel", keyScreen)
keyStatus.Size = UDim2.new(1, 0, 0, 25)
keyStatus.Position = UDim2.new(0, 0, 0, 210)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 11
keyStatus.ZIndex = 81

local submitBtn = Instance.new("TextButton", keyScreen)
submitBtn.Size = UDim2.new(1, -40, 0, 45)
submitBtn.Position = UDim2.new(0, 20, 0, 250)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 15
submitBtn.AutoButtonColor = false
submitBtn.ZIndex = 82
corner(submitBtn, 10)
pressFX(submitBtn)

local function getMapName()
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and result and result.Name then
        return result.Name
    end
    return "Unknown Map"
end

local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        keyStatus.Text = "Masukkan key"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    if Firebase and Firebase.ValidateKey then
        keyStatus.Text = "Checking..."
        keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        task.spawn(function()
            local ok, result = pcall(function()
                return Firebase.ValidateKey(key, LocalPlayer.UserId, LocalPlayer.DisplayName, LocalPlayer.Name, getMapName(), game.JobId)
            end)
            
            if ok and result then
                local isValid, message = result
                if isValid then
                    if Storage and Storage.appSettings then
                        Storage.appSettings.savedKey = key
                        Storage.persistSettings()
                        print("[Phone] Key saved to storage:", key)
                    end
                    
                    keyStatus.Text = message or "Key valid!"
                    keyStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                    
                    task.wait(0.5)
                    _G.unlock()
                else
                    keyStatus.Text = message or "Key tidak valid"
                    keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                    keyInput.Text = ""
                end
            else
                keyStatus.Text = "Gagal terhubung"
                keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
    else
        task.wait(0.5)
        _G.unlock()
    end
end

submitBtn.MouseButton1Click:Connect(submitKey)
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then submitKey() end
end)

-- ==================== STATE ====================
_G.PhoneState = {
    selectedPlayer = nil,
    isLocked = true,
    isCloning = false,
    toolEquipped = true,
}

-- ==================== FUNCTIONS ====================
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
    if _G.goHome then _G.goHome() end
    _G.showDynamicNotification("Phone Unlocked!", Color3.fromRGB(0, 255, 100))
end

function _G.checkAutoLogin()
    local savedKey = nil
    if Storage and Storage.appSettings then
        savedKey = Storage.appSettings.savedKey
    end
    
    if savedKey and savedKey ~= "" and Firebase and Firebase.CheckSavedKey then
        local ok, result = pcall(function()
            return Firebase.CheckSavedKey(LocalPlayer.UserId, savedKey)
        end)
        if ok and result then
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
            if _G.goHome then _G.goHome() end
        end
    else
        if _G.goHome then _G.goHome() end
    end
end

function _G.closePhone()
    if not phone.Visible then return end
    tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function() phone.Visible = false end)
end

-- ==================== ONLINE TRACKING ====================
task.spawn(function()
    if Firebase and Firebase.SetOnline then
        local playerData = {
            name = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            userId = LocalPlayer.UserId,
            mapName = getMapName(),
            jobId = game.JobId,
            lastUpdate = os.time(),
        }
        Firebase.SetOnline(LocalPlayer.UserId, playerData)
        
        while true do
            task.wait(60)
            playerData.mapName = getMapName()
            playerData.lastUpdate = os.time()
            Firebase.SetOnline(LocalPlayer.UserId, playerData)
        end
    end
end)

-- Auto-login at startup
task.spawn(function()
    task.wait(2)
    local ok, result = pcall(_G.checkAutoLogin)
    if ok and result then
        print("[Phone] Auto-login success!")
    else
        print("[Phone] Waiting for key...")
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