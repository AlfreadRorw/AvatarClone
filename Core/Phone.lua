-- ================================================
-- PHONE GUI - Complete Fixed
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

local function safeTween(obj, props, time, easingStyle)
    pcall(function()
        if obj and obj.Parent then
            game:GetService("TweenService"):Create(obj, TweenInfo.new(time or 0.25, easingStyle or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
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
local phone = Instance.new("Frame")
phone.Size = UDim2.new(0, 0, 0, 0)
phone.Position = UDim2.new(0.5, 0, 0.52, 0)
phone.AnchorPoint = Vector2.new(0.5, 0.5)
phone.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
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
sa.Parent = phone
safeCorner(sa, 30)

-- ==================== STATUS BAR ====================
local sb = Instance.new("Frame")
sb.Size = UDim2.new(1, 0, 0, 34)
sb.BackgroundTransparency = 1
sb.ZIndex = 100
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
clockLbl.ZIndex = 101
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
di.ZIndex = 110
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
dil.ZIndex = 111
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
sh.Parent = sa

local home = Instance.new("Frame")
home.Size = UDim2.new(1, 0, 1, 0)
home.BackgroundTransparency = 1
home.ClipsDescendants = true
home.Parent = sh

local homeWall = Instance.new("Frame")
homeWall.Size = UDim2.new(1, 0, 1, 0)
homeWall.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
homeWall.ZIndex = 0
homeWall.Parent = home
safeCorner(homeWall, 30)

-- ==================== DOCK ====================
local dockArea = Instance.new("Frame")
dockArea.Size = UDim2.new(0, 224, 0, 64)
dockArea.Position = UDim2.new(0.5, -112, 1, -84)
dockArea.BackgroundTransparency = 1
dockArea.ZIndex = 5
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
keyScreen.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
keyScreen.ZIndex = 80
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
keyScreen.ClipsDescendants = true
keyScreen.Parent = sa
safeCorner(keyScreen, 30)

-- Gradient background
local keyBgGradient = Instance.new("UIGradient")
keyBgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 35))
})
keyBgGradient.Rotation = 135
keyBgGradient.Parent = keyScreen

-- Key content
local keyContent = Instance.new("Frame")
keyContent.Size = UDim2.new(1, -40, 1, -40)
keyContent.Position = UDim2.new(0, 20, 0, 20)
keyContent.BackgroundTransparency = 1
keyContent.ZIndex = 82
keyContent.Parent = keyScreen

local keyLayout = Instance.new("UIListLayout")
keyLayout.Padding = UDim.new(0, 12)
keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
keyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
keyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
keyLayout.Parent = keyContent

-- Logo
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 80, 0, 80)
logoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
logoFrame.BackgroundTransparency = 0.9
logoFrame.LayoutOrder = 0
logoFrame.ZIndex = 83
logoFrame.Parent = keyContent
safeCorner(logoFrame, 20)
safeStroke(logoFrame, Color3.fromRGB(255, 255, 255), 2, 0.8)

local logoImage = Instance.new("ImageLabel")
logoImage.Size = UDim2.new(1, -10, 1, -10)
logoImage.Position = UDim2.new(0, 5, 0, 5)
logoImage.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
logoImage.Image = Config.LogoURL or "https://files.catbox.moe/io8o2d.png"
logoImage.ScaleType = Enum.ScaleType.Fit
logoImage.ZIndex = 84
logoImage.Parent = logoFrame
safeCorner(logoImage, 18)

-- Title
local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 34)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "PHONE ID VIEWER"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 22
keyTitle.LayoutOrder = 1
keyTitle.ZIndex = 83
keyTitle.Parent = keyContent

-- Description
local keyDesc = Instance.new("TextLabel")
keyDesc.Size = UDim2.new(1, -20, 0, 30)
keyDesc.BackgroundTransparency = 1
keyDesc.Text = "Masukkan access key untuk membuka semua fitur premium."
keyDesc.TextColor3 = Color3.fromRGB(150, 150, 170)
keyDesc.Font = Enum.Font.Gotham
keyDesc.TextSize = 11
keyDesc.TextWrapped = true
keyDesc.LayoutOrder = 2
keyDesc.ZIndex = 83
keyDesc.Parent = keyContent

-- Input container
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, 0, 0, 50)
inputContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
inputContainer.LayoutOrder = 3
inputContainer.ZIndex = 84
inputContainer.Parent = keyContent
safeCorner(inputContainer, 14)
safeStroke(inputContainer, Color3.fromRGB(255, 255, 255), 1, 0.8)

-- Key icon
local keyIcon = Instance.new("TextLabel")
keyIcon.Size = UDim2.new(0, 30, 0, 30)
keyIcon.Position = UDim2.new(0, 10, 0.5, -15)
keyIcon.BackgroundTransparency = 1
keyIcon.Text = "🔑"
keyIcon.Font = Enum.Font.GothamBold
keyIcon.TextSize = 16
keyIcon.ZIndex = 85
keyIcon.Parent = inputContainer

-- TextBox
local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -46, 1, 0)
keyInput.Position = UDim2.new(0, 42, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.Text = ""
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 15
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 85
keyInput.Parent = inputContainer

-- Status label
local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1, 0, 0, 22)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 11
keyStatus.LayoutOrder = 4
keyStatus.ZIndex = 83
keyStatus.Parent = keyContent

-- Unlock button
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, 0, 0, 48)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 16
submitBtn.AutoButtonColor = false
submitBtn.LayoutOrder = 5
submitBtn.ZIndex = 84
submitBtn.Parent = keyContent
safeCorner(submitBtn, 14)
safePressFX(submitBtn)

-- Buy button
local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(1, 0, 0, 40)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.BackgroundTransparency = 0.9
buyBtn.Text = "💳 BUY KEY"
buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 13
buyBtn.AutoButtonColor = false
buyBtn.LayoutOrder = 6
buyBtn.ZIndex = 84
buyBtn.Parent = keyContent
safeCorner(buyBtn, 10)
safeStroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.6)
safePressFX(buyBtn)

-- Version info
local buildInfo = Instance.new("TextLabel")
buildInfo.Size = UDim2.new(1, 0, 0, 16)
buildInfo.BackgroundTransparency = 1
buildInfo.Text = "Build v2.1.0 | © 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
buildInfo.TextColor3 = Color3.fromRGB(80, 80, 100)
buildInfo.Font = Enum.Font.Gotham
buildInfo.TextSize = 8
buildInfo.LayoutOrder = 7
buildInfo.ZIndex = 83
buildInfo.Parent = keyContent

-- ==================== FUNCTIONS ====================
local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        keyStatus.Text = "⚠️ Masukkan key terlebih dahulu"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    if Firebase and Firebase.ValidateKey then
        keyStatus.Text = "⏳ Checking key..."
        keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        task.spawn(function()
            local ok, result = pcall(function()
                return Firebase.ValidateKey(key, LocalPlayer.UserId, LocalPlayer.DisplayName, LocalPlayer.Name)
            end)
            
            if ok and result then
                local isValid, message = result
                if isValid then
                    keyStatus.Text = "✅ " .. (message or "Key valid!")
                    keyStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                    
                    -- Simpan key ke storage
                    if Storage.saveKey then
                        Storage.saveKey(key)
                    end
                    
                    task.wait(0.8)
                    _G.unlock()
                else
                    keyStatus.Text = "❌ " .. (message or "Key tidak valid")
                    keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            else
                keyStatus.Text = "❌ Gagal terhubung ke server"
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

buyBtn.MouseButton1Click:Connect(function()
    local url = Config.BUY_KEY_URL or "https://discord.gg/yourdiscord"
    pcall(function() setclipboard(url) end)
    _G.showDynamicNotification("Link pembelian disalin!", Color3.fromRGB(255, 180, 50))
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
    if _G.goHome then _G.goHome() end
    _G.showDynamicNotification("Phone Unlocked!", Color3.fromRGB(0, 255, 100))
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    safeTween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    
    if _G.PhoneState.isLocked then
        -- Cek saved key dulu
        local savedKey = nil
        if Storage.getSavedKey then
            savedKey = Storage.getSavedKey()
        end
        
        if savedKey and savedKey ~= "" and Firebase and Firebase.CheckSavedKey then
            local ok, isValid = pcall(function()
                return Firebase.CheckSavedKey(LocalPlayer.UserId, savedKey)
            end)
            
            if ok and isValid then
                -- Key masih valid, langsung unlock
                _G.PhoneState.isLocked = false
                task.wait(0.3)
                if _G.goHome then _G.goHome() end
                _G.showDynamicNotification("✅ Welcome back!", Color3.fromRGB(0, 255, 100))
                return
            else
                -- Key expired
                if Storage.clearSavedKey then
                    Storage.clearSavedKey()
                end
            end
        end
        
        task.wait(0.5)
        _G.showKeyEntry()
    else
        if _G.goHome then
            _G.goHome()
        end
    end
end

function _G.closePhone()
    if not phone.Visible then return end
    safeTween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function()
        phone.Visible = false
    end)
end

-- ==================== ONLINE TRACKING (FIXED) ====================
local function setPlayerOnline()
    if Firebase and Firebase.SetOnline then
        local playerData = {
            name = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            userId = LocalPlayer.UserId,
            mapName = game.PlaceId,
            jobId = game.JobId,
            lastUpdate = os.time(),
        }
        Firebase.SetOnline(LocalPlayer.UserId, playerData)
    end
end

local function removePlayerOnline()
    if Firebase and Firebase.RemoveOnline then
        Firebase.RemoveOnline(LocalPlayer.UserId)
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
    if player == LocalPlayer then
        removePlayerOnline()
    end
end)

game:BindToClose(function()
    removePlayerOnline()
end)

LocalPlayer.OnTeleport:Connect(function()
    removePlayerOnline()
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
    PHONE_SIZE = PHONE_SIZE,
}