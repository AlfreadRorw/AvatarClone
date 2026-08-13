-- ================================================
-- PHONE GUI - FULL FIXED - No White Screen
-- ================================================

local Services = _G.Services
local T = _G.T or {}
local Helpers = _G.Helpers or {}
local Config = _G.Config or {}
local LocalPlayer = _G.LocalPlayer

local Storage = _G.Storage or {}
local Firebase = _G.Firebase

-- Safe helpers
local function safeCorner(obj, radius)
    pcall(function()
        if obj then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius or 10)
            c.Parent = obj
        end
    end)
end

local function safeStroke(obj, color, thickness, transparency)
    pcall(function()
        if obj then
            local s = Instance.new("UIStroke")
            s.Color = color or Color3.fromRGB(200, 200, 200)
            s.Thickness = thickness or 1
            s.Transparency = transparency or 0
            s.Parent = obj
        end
    end)
end

local function safeTween(obj, props, time, easingStyle, easingDir)
    pcall(function()
        if obj and obj.Parent then
            game:GetService("TweenService"):Create(obj, TweenInfo.new(time or 0.25, easingStyle or Enum.EasingStyle.Quart, easingDir or Enum.EasingDirection.Out), props):Play()
        end
    end)
end

local function safePressFX(btn)
    pcall(function()
        if not btn then return end
        local origSize = btn.Size
        btn.MouseButton1Down:Connect(function()
            safeTween(btn, {Size = UDim2.new(origSize.X.Scale * 0.95, origSize.X.Offset * 0.95, origSize.Y.Scale * 0.95, origSize.Y.Offset * 0.95)}, 0.1)
        end)
        btn.MouseButton1Up:Connect(function()
            safeTween(btn, {Size = origSize}, 0.1)
        end)
    end)
end

-- ==================== GUI ROOT ====================
local gui = Instance.new("ScreenGui")
gui.Name = "PhoneGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 998
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService("CoreGui")

-- ==================== PHONE FRAME ====================
local phone = Instance.new("Frame")
phone.Size = UDim2.new(0, 0, 0, 0)
phone.Position = UDim2.new(0.5, 0, 0.52, 0)
phone.AnchorPoint = Vector2.new(0.5, 0.5)
phone.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
phone.ZIndex = 1
phone.Parent = gui
safeCorner(phone, 38)
safeStroke(phone, T.Accent or Color3.fromRGB(30, 30, 30), 2, 0.15)

local PHONE_SIZE = UDim2.new(0, 320, 0, 560)

-- ==================== SCREEN AREA ====================
local sa = Instance.new("Frame")
sa.Size = UDim2.new(1, -16, 1, -16)
sa.Position = UDim2.new(0, 8, 0, 8)
sa.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
sa.BorderSizePixel = 0
sa.ClipsDescendants = true
sa.ZIndex = 1
sa.Parent = phone
safeCorner(sa, 30)

-- ==================== STATUS BAR ====================
local sb = Instance.new("Frame")
sb.Size = UDim2.new(1, 0, 0, 34)
sb.BackgroundTransparency = 1
sb.ZIndex = 10
sb.Parent = sa

local clockLbl = Instance.new("TextLabel")
clockLbl.Size = UDim2.new(0, 80, 0, 30)
clockLbl.Position = UDim2.new(0, 14, 0, 0)
clockLbl.BackgroundTransparency = 1
clockLbl.Text = os.date("%H:%M")
clockLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
clockLbl.Font = Enum.Font.GothamBold
clockLbl.TextSize = 13
clockLbl.TextXAlignment = Enum.TextXAlignment.Left
clockLbl.ZIndex = 11
clockLbl.Parent = sb

task.spawn(function()
    while clockLbl.Parent do
        clockLbl.Text = os.date("%H:%M")
        task.wait(30)
    end
end)

-- ==================== DYNAMIC ISLAND ====================
local di = Instance.new("Frame")
di.Size = UDim2.new(0, 90, 0, 24)
di.Position = UDim2.new(0.5, -45, 0, 4)
di.BackgroundColor3 = Color3.new(0, 0, 0)
di.ZIndex = 15
di.Parent = sa
safeCorner(di, 100)

local diStroke = Instance.new("UIStroke")
diStroke.Color = Color3.new(1, 1, 1)
diStroke.Thickness = 1.5
diStroke.Transparency = 0.6
diStroke.Parent = di

local dil = Instance.new("TextLabel")
dil.Size = UDim2.new(1, -8, 1, 0)
dil.Position = UDim2.new(0, 4, 0, 0)
dil.BackgroundTransparency = 1
dil.Text = ""
dil.TextColor3 = Color3.new(1, 1, 1)
dil.Font = Enum.Font.GothamBold
dil.TextSize = 14
dil.TextXAlignment = Enum.TextXAlignment.Center
dil.ZIndex = 16
dil.Parent = di

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
    safeTween(di, {Size = UDim2.new(0, textWidth, 0, 32), Position = UDim2.new(0.5, -textWidth/2, 0, 2)}, 0.25, Enum.EasingStyle.Back)
    task.delay(1.8, function()
        if iid ~= my then return end
        safeTween(di, {Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(0.5, -45, 0, 4)}, 0.25)
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
local sh = Instance.new("Frame")
sh.Size = UDim2.new(1, 0, 1, -60)
sh.Position = UDim2.new(0, 0, 0, 34)
sh.BackgroundTransparency = 1
sh.ClipsDescendants = true
sh.ZIndex = 2
sh.Parent = sa

local home = Instance.new("Frame")
home.Size = UDim2.new(1, 0, 1, 0)
home.BackgroundTransparency = 1
home.ClipsDescendants = true
home.ZIndex = 2
home.Parent = sh

local homeWall = Instance.new("Frame")
homeWall.Size = UDim2.new(1, 0, 1, 0)
homeWall.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
homeWall.ZIndex = 1
homeWall.Parent = home
safeCorner(homeWall, 30)

-- ==================== DOCK ====================
local dockArea = Instance.new("Frame")
dockArea.Size = UDim2.new(0, 224, 0, 64)
dockArea.Position = UDim2.new(0.5, -112, 1, -84)
dockArea.BackgroundTransparency = 1
dockArea.ZIndex = 3
dockArea.Parent = home

local dockBg = Instance.new("Frame")
dockBg.Size = UDim2.new(1, 0, 0, 56)
dockBg.Position = UDim2.new(0, 0, 0, 4)
dockBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dockBg.BackgroundTransparency = 0.1
dockBg.Parent = dockArea
safeCorner(dockBg, 20)

local dockGrid = Instance.new("UIGridLayout")
dockGrid.CellSize = UDim2.new(0, 70, 0, 50)
dockGrid.CellPadding = UDim2.new(0, 2, 0, 0)
dockGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockGrid.VerticalAlignment = Enum.VerticalAlignment.Center
dockGrid.FillDirection = Enum.FillDirection.Horizontal
dockGrid.Parent = dockBg

-- ==================== APP GRID ====================
local appGrid = Instance.new("ScrollingFrame")
appGrid.Size = UDim2.new(1, -16, 1, -156)
appGrid.Position = UDim2.new(0, 8, 0, 70)
appGrid.BackgroundTransparency = 1
appGrid.ScrollBarThickness = 3
appGrid.ScrollBarImageColor3 = T.Accent or Color3.fromRGB(30, 30, 30)
appGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
appGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
appGrid.BorderSizePixel = 0
appGrid.ZIndex = 2
appGrid.Parent = home

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 72, 0, 86)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 12)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.Parent = appGrid

-- ==================== KEY SCREEN ====================
local keyScreen = Instance.new("Frame")
keyScreen.Size = UDim2.new(1, 0, 1, 0)
keyScreen.Position = UDim2.new(0, 0, 0, 0)
keyScreen.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
keyScreen.ZIndex = 5 -- ZIndex rendah, tapi tetap di atas home (ZIndex 2)
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
keyScreen.ClipsDescendants = true
keyScreen.Parent = sa
safeCorner(keyScreen, 30)

-- Background gradient
local keyBgGradient = Instance.new("UIGradient")
keyBgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 32)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 8, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 20, 36)),
})
keyBgGradient.Rotation = 135
keyBgGradient.Parent = keyScreen

-- Glow orbs
local glow1 = Instance.new("Frame")
glow1.Size = UDim2.new(0, 180, 0, 180)
glow1.Position = UDim2.new(0, -40, 0, -30)
glow1.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
glow1.BackgroundTransparency = 0.87
glow1.BorderSizePixel = 0
glow1.ZIndex = 1
glow1.Parent = keyScreen
safeCorner(glow1, 100)

local glow2 = Instance.new("Frame")
glow2.Size = UDim2.new(0, 150, 0, 150)
glow2.Position = UDim2.new(1, -50, 0, 150)
glow2.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
glow2.BackgroundTransparency = 0.88
glow2.BorderSizePixel = 0
glow2.ZIndex = 1
glow2.Parent = keyScreen
safeCorner(glow2, 100)

-- Key Content
local keyContent = Instance.new("Frame")
keyContent.Size = UDim2.new(1, -40, 1, -40)
keyContent.Position = UDim2.new(0, 20, 0, 20)
keyContent.BackgroundTransparency = 1
keyContent.ZIndex = 2
keyContent.Parent = keyScreen

local keyLayout = Instance.new("UIListLayout")
keyLayout.Padding = UDim.new(0, 12)
keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
keyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
keyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
keyLayout.Parent = keyContent

-- ==================== BUILD LOCK ICON ====================
local lockContainer = Instance.new("Frame")
lockContainer.Size = UDim2.new(0, 70, 0, 70)
lockContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockContainer.BackgroundTransparency = 0.9
lockContainer.LayoutOrder = 0
lockContainer.ZIndex = 3
lockContainer.Parent = keyContent
safeCorner(lockContainer, 20)
safeStroke(lockContainer, Color3.fromRGB(180, 160, 255), 2, 0.5)

-- Badan gembok
local lockBody = Instance.new("Frame")
lockBody.Size = UDim2.new(0, 32, 0, 26)
lockBody.Position = UDim2.new(0.5, -16, 0.58, 0)
lockBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockBody.ZIndex = 4
lockBody.Parent = lockContainer
safeCorner(lockBody, 6)

-- Lubang kunci
local keyhole = Instance.new("Frame")
keyhole.Size = UDim2.new(0, 7, 0, 10)
keyhole.Position = UDim2.new(0.5, -3.5, 0.5, -5)
keyhole.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
keyhole.ZIndex = 5
keyhole.Parent = lockBody
safeCorner(keyhole, 3)

-- Lingkaran lubang kunci
local keyholeCircle = Instance.new("Frame")
keyholeCircle.Size = UDim2.new(0, 8, 0, 8)
keyholeCircle.Position = UDim2.new(0.5, -4, 0.5, -12)
keyholeCircle.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
keyholeCircle.ZIndex = 5
keyholeCircle.Parent = lockBody
safeCorner(keyholeCircle, 100)

-- Shackle (lengkungan atas)
local shackle = Instance.new("Frame")
shackle.Size = UDim2.new(0, 20, 0, 18)
shackle.Position = UDim2.new(0.5, -10, 0.3, -4)
shackle.BackgroundTransparency = 1
shackle.ZIndex = 4
shackle.Parent = lockContainer
safeCorner(shackle, 100)
safeStroke(shackle, Color3.fromRGB(255, 255, 255), 4, 0)

-- ==================== TITLE ====================
local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "ACCESS REQUIRED"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 20
keyTitle.LayoutOrder = 1
keyTitle.ZIndex = 3
keyTitle.Parent = keyContent

-- ==================== DESCRIPTION ====================
local keyDesc = Instance.new("TextLabel")
keyDesc.Size = UDim2.new(1, -10, 0, 28)
keyDesc.BackgroundTransparency = 1
keyDesc.Text = "Masukkan access key untuk membuka semua fitur"
keyDesc.TextColor3 = Color3.fromRGB(150, 150, 180)
keyDesc.Font = Enum.Font.Gotham
keyDesc.TextSize = 11
keyDesc.TextWrapped = true
keyDesc.LayoutOrder = 2
keyDesc.ZIndex = 3
keyDesc.Parent = keyContent

-- ==================== INPUT CONTAINER ====================
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, 0, 0, 48)
inputContainer.BackgroundColor3 = Color3.fromRGB(22, 20, 36)
inputContainer.LayoutOrder = 3
inputContainer.ZIndex = 4
inputContainer.Parent = keyContent
safeCorner(inputContainer, 14)
safeStroke(inputContainer, Color3.fromRGB(120, 100, 220), 1.5, 0.5)

-- TextBox
local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -20, 1, 0)
keyInput.Position = UDim2.new(0, 10, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.Text = ""
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 14
keyInput.TextXAlignment = Enum.TextXAlignment.Center
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 5
keyInput.Parent = inputContainer

-- ==================== STATUS LABEL ====================
local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1, 0, 0, 20)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 10
keyStatus.LayoutOrder = 4
keyStatus.ZIndex = 3
keyStatus.Parent = keyContent

-- ==================== UNLOCK BUTTON ====================
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, 0, 0, 46)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(10, 10, 20)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 15
submitBtn.AutoButtonColor = false
submitBtn.LayoutOrder = 5
submitBtn.ZIndex = 4
submitBtn.Parent = keyContent
safeCorner(submitBtn, 14)
safePressFX(submitBtn)

-- ==================== BUY BUTTON ====================
local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(1, 0, 0, 38)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.BackgroundTransparency = 0.92
buyBtn.Text = "BUY KEY"
buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 12
buyBtn.AutoButtonColor = false
buyBtn.LayoutOrder = 6
buyBtn.ZIndex = 4
buyBtn.Parent = keyContent
safeCorner(buyBtn, 10)
safeStroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.7)
safePressFX(buyBtn)

-- ==================== VERSION ====================
local buildInfo = Instance.new("TextLabel")
buildInfo.Size = UDim2.new(1, 0, 0, 14)
buildInfo.BackgroundTransparency = 1
buildInfo.Text = "v2.2.0 | " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
buildInfo.TextColor3 = Color3.fromRGB(80, 80, 100)
buildInfo.Font = Enum.Font.Gotham
buildInfo.TextSize = 8
buildInfo.LayoutOrder = 7
buildInfo.ZIndex = 3
buildInfo.Parent = keyContent

-- ==================== FUNCTIONS ====================
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
            local ok, isValid, message = pcall(function()
                return Firebase.ValidateKey(key, LocalPlayer.UserId, LocalPlayer.DisplayName, LocalPlayer.Name)
            end)
            
            if ok and isValid then
                keyStatus.Text = message or "Key valid!"
                keyStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                if Storage.saveKey then
                    pcall(function() Storage.saveKey(key) end)
                end
                
                task.wait(0.5)
                _G.unlock()
            else
                keyStatus.Text = message or "Key tidak valid"
                keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
    else
        task.wait(0.3)
        _G.unlock()
    end
end

submitBtn.MouseButton1Click:Connect(submitKey)

keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then submitKey() end
end)

buyBtn.MouseButton1Click:Connect(function()
    local url = Config.BUY_KEY_URL or "https://discord.gg/"
    pcall(function() setclipboard(url) end)
    _G.showDynamicNotification("Link disalin!", Color3.fromRGB(180, 150, 255))
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
    pcall(function() keyInput:CaptureFocus() end)
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
    _G.showDynamicNotification("Unlocked!", Color3.fromRGB(0, 255, 100))
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    safeTween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    
    if _G.PhoneState.isLocked then
        -- Cek saved key
        local savedKey = nil
        pcall(function()
            if Storage.getSavedKey then
                savedKey = Storage.getSavedKey()
            end
        end)
        
        local autoUnlocked = false
        
        if savedKey and savedKey ~= "" and Firebase and Firebase.CheckSavedKey then
            local okCheck, isValid = pcall(function()
                return Firebase.CheckSavedKey(LocalPlayer.UserId, savedKey)
            end)
            
            if okCheck and isValid then
                autoUnlocked = true
                _G.PhoneState.isLocked = false
                task.wait(0.2)
                if _G.goHome then _G.goHome() end
                _G.showDynamicNotification("Welcome back!", Color3.fromRGB(0, 255, 100))
            else
                pcall(function()
                    if Storage.clearSavedKey then Storage.clearSavedKey() end
                end)
            end
        end
        
        if not autoUnlocked then
            task.wait(0.3)
            _G.showKeyEntry()
        end
    else
        if _G.goHome then _G.goHome() end
    end
end

function _G.closePhone()
    if not phone.Visible then return end
    safeTween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function()
        phone.Visible = false
    end)
end

-- ==================== ONLINE TRACKING ====================
local function setPlayerOnline()
    if Firebase and Firebase.SetOnline then
        pcall(function()
            Firebase.SetOnline(LocalPlayer.UserId, {
                name = LocalPlayer.Name,
                displayName = LocalPlayer.DisplayName,
                userId = LocalPlayer.UserId,
                mapName = game.PlaceId,
                jobId = game.JobId,
                lastUpdate = os.time(),
            })
        end)
    end
end

local function removePlayerOnline()
    if Firebase and Firebase.RemoveOnline then
        pcall(function()
            Firebase.RemoveOnline(LocalPlayer.UserId)
        end)
    end
end

task.spawn(function()
    setPlayerOnline()
    while true do
        task.wait(30)
        setPlayerOnline()
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then removePlayerOnline() end
end)

game:BindToClose(function() removePlayerOnline() end)

LocalPlayer.OnTeleport:Connect(function() removePlayerOnline() end)

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
    PHONE_SIZE = PHONE_SIZE,
}