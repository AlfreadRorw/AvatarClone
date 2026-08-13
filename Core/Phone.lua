-- ================================================
-- PHONE GUI - Complete with Notification System
-- Fixed: Build Icon untuk Key & Buy Button
-- ================================================

local Services = _G.Services
local T = _G.T
local Helpers = _G.Helpers
local Config = _G.Config
local LocalPlayer = _G.LocalPlayer

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

-- ==================== BUILD ICON HELPERS ====================
local function buildKeyIcon(parent, size, color)
    -- Icon kunci sederhana: lingkaran + batang + gigi
    local holder = Instance.new("Frame")
    holder.Size = size or UDim2.new(0, 24, 0, 18)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 90
    holder.Parent = parent
    
    -- Lingkaran kepala kunci
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, 0, 0.5, -6)
    circle.BackgroundTransparency = 1
    circle.ZIndex = 91
    circle.Parent = holder
    corner(circle, 100)
    stroke(circle, color or Color3.fromRGB(150, 150, 170), 2, 0)
    
    -- Batang kunci
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 14, 0, 3)
    bar.Position = UDim2.new(0, 10, 0.5, -1.5)
    bar.BackgroundColor3 = color or Color3.fromRGB(150, 150, 170)
    bar.ZIndex = 91
    bar.Parent = holder
    corner(bar, 1)
    
    -- Gigi 1
    local tooth1 = Instance.new("Frame")
    tooth1.Size = UDim2.new(0, 3, 0, 7)
    tooth1.Position = UDim2.new(0, 17, 0.5, -2)
    tooth1.BackgroundColor3 = color or Color3.fromRGB(150, 150, 170)
    tooth1.ZIndex = 91
    tooth1.Parent = holder
    
    -- Gigi 2
    local tooth2 = Instance.new("Frame")
    tooth2.Size = UDim2.new(0, 3, 0, 5)
    tooth2.Position = UDim2.new(0, 21, 0.5, -2)
    tooth2.BackgroundColor3 = color or Color3.fromRGB(150, 150, 170)
    tooth2.ZIndex = 91
    tooth2.Parent = holder
    
    return holder
end

local function buildCardIcon(parent, size, color)
    -- Icon kartu kredit: kotak rounded + garis + lingkaran
    local holder = Instance.new("Frame")
    holder.Size = size or UDim2.new(0, 24, 0, 16)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 90
    holder.Parent = parent
    
    -- Badan kartu
    local cardBody = Instance.new("Frame")
    cardBody.Size = UDim2.new(1, 0, 1, 0)
    cardBody.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    cardBody.ZIndex = 91
    cardBody.Parent = holder
    corner(cardBody, 4)
    stroke(cardBody, color or Color3.fromRGB(255, 255, 255), 1.5, 0)
    
    -- Garis magnetik
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(1, 0, 0, 4)
    stripe.Position = UDim2.new(0, 0, 0, 4)
    stripe.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    stripe.ZIndex = 92
    stripe.Parent = cardBody
    
    -- Lingkaran kecil
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0, 4, 0, 1)
    dot.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    dot.ZIndex = 92
    dot.Parent = cardBody
    corner(dot, 100)
    
    return holder
end

local function buildLockIcon(parent, size, color)
    -- Icon gembok: badan + shackle
    local holder = Instance.new("Frame")
    holder.Size = size or UDim2.new(0, 56, 0, 56)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 90
    holder.Parent = parent
    
    -- Badan gembok
    local body = Instance.new("Frame")
    body.Size = UDim2.new(0, 28, 0, 22)
    body.Position = UDim2.new(0.5, -14, 0.58, 0)
    body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    body.ZIndex = 91
    body.Parent = holder
    corner(body, 6)
    
    -- Lubang kunci
    local keyhole = Instance.new("Frame")
    keyhole.Size = UDim2.new(0, 6, 0, 8)
    keyhole.Position = UDim2.new(0.5, -3, 0.5, -4)
    keyhole.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
    keyhole.ZIndex = 92
    keyhole.Parent = body
    corner(keyhole, 3)
    
    -- Lingkaran lubang
    local keyholeCircle = Instance.new("Frame")
    keyholeCircle.Size = UDim2.new(0, 7, 0, 7)
    keyholeCircle.Position = UDim2.new(0.5, -3.5, 0.5, -10)
    keyholeCircle.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
    keyholeCircle.ZIndex = 92
    keyholeCircle.Parent = body
    corner(keyholeCircle, 100)
    
    -- Shackle (lengkungan atas)
    local shackle = Instance.new("Frame")
    shackle.Size = UDim2.new(0, 18, 0, 16)
    shackle.Position = UDim2.new(0.5, -9, 0.3, -2)
    shackle.BackgroundTransparency = 1
    shackle.ZIndex = 91
    shackle.Parent = holder
    corner(shackle, 100)
    stroke(shackle, Color3.fromRGB(255, 255, 255), 3.5, 0)
    
    return holder
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
clockLbl.Size = UDim2.new(0, 80, 0, 30)
clockLbl.Position = UDim2.new(0, 14, 0, 0)
clockLbl.BackgroundTransparency = 1
clockLbl.Text = os.date("%H:%M")
clockLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
clockLbl.Font = Enum.Font.GothamBold
clockLbl.TextSize = 13
clockLbl.TextXAlignment = Enum.TextXAlignment.Left
clockLbl.ZIndex = 101

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

-- ==================== KEY SCREEN (MODERN REDESIGN) ====================
local keyScreen = Instance.new("Frame", sa)
keyScreen.Size = UDim2.new(1, 0, 1, 0)
keyScreen.Position = UDim2.new(0, 0, 0, 0)
keyScreen.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
keyScreen.ZIndex = 80
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
keyScreen.ClipsDescendants = true
corner(keyScreen, 30)

-- Gradient background
local keyBgGradient = Instance.new("UIGradient", keyScreen)
keyBgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 20, 35))
})
keyBgGradient.Rotation = 135

-- Decorative glow orb (top)
local glowOrb = Instance.new("Frame", keyScreen)
glowOrb.Size = UDim2.new(0, 200, 0, 200)
glowOrb.Position = UDim2.new(0.5, -100, 0, -80)
glowOrb.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
glowOrb.BackgroundTransparency = 0.85
glowOrb.ZIndex = 81
corner(glowOrb, 100)

local glowOrb2 = Instance.new("Frame", keyScreen)
glowOrb2.Size = UDim2.new(0, 150, 0, 150)
glowOrb2.Position = UDim2.new(1, -60, 1, -60)
glowOrb2.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
glowOrb2.BackgroundTransparency = 0.85
glowOrb2.ZIndex = 81
corner(glowOrb2, 100)

-- ==================== MAIN CONTENT ====================
local keyContent = Instance.new("Frame", keyScreen)
keyContent.Size = UDim2.new(1, -40, 1, -40)
keyContent.Position = UDim2.new(0, 20, 0, 20)
keyContent.BackgroundTransparency = 1
keyContent.ZIndex = 82

local keyLayout = Instance.new("UIListLayout", keyContent)
keyLayout.Padding = UDim.new(0, 12)
keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
keyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
keyLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- ==================== BUILD LOCK ICON (Ganti Logo) ====================
local lockFrame = Instance.new("Frame", keyContent)
lockFrame.Size = UDim2.new(0, 80, 0, 80)
lockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockFrame.BackgroundTransparency = 0.9
lockFrame.LayoutOrder = 0
lockFrame.ZIndex = 83
corner(lockFrame, 20)
stroke(lockFrame, Color3.fromRGB(255, 255, 255), 2, 0.8)

buildLockIcon(lockFrame, UDim2.new(0, 56, 0, 56), Color3.fromRGB(255, 255, 255))

-- Title
local keyTitle = Instance.new("TextLabel", keyContent)
keyTitle.Size = UDim2.new(1, 0, 0, 34)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "PHONE ID VIEWER"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 22
keyTitle.LayoutOrder = 1
keyTitle.ZIndex = 83

-- Description
local keyDesc = Instance.new("TextLabel", keyContent)
keyDesc.Size = UDim2.new(1, -20, 0, 30)
keyDesc.BackgroundTransparency = 1
keyDesc.Text = "Masukkan access key untuk membuka semua fitur premium."
keyDesc.TextColor3 = Color3.fromRGB(150, 150, 170)
keyDesc.Font = Enum.Font.Gotham
keyDesc.TextSize = 11
keyDesc.TextWrapped = true
keyDesc.LayoutOrder = 2
keyDesc.ZIndex = 83

-- Input container
local inputContainer = Instance.new("Frame", keyContent)
inputContainer.Size = UDim2.new(1, 0, 0, 50)
inputContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
inputContainer.LayoutOrder = 3
inputContainer.ZIndex = 84
corner(inputContainer, 14)
stroke(inputContainer, Color3.fromRGB(255, 255, 255), 1, 0.8)

-- Build Key Icon di input (ganti emoji 🔑)
local keyIconHolder = Instance.new("Frame")
keyIconHolder.Size = UDim2.new(0, 26, 0, 20)
keyIconHolder.Position = UDim2.new(0, 10, 0.5, -10)
keyIconHolder.BackgroundTransparency = 1
keyIconHolder.ZIndex = 85
keyIconHolder.Parent = inputContainer

buildKeyIcon(keyIconHolder, UDim2.new(0, 24, 0, 18), Color3.fromRGB(150, 150, 170))

-- TextBox
local keyInput = Instance.new("TextBox", inputContainer)
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

-- Status label
local keyStatus = Instance.new("TextLabel", keyContent)
keyStatus.Size = UDim2.new(1, 0, 0, 22)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 11
keyStatus.LayoutOrder = 4
keyStatus.ZIndex = 83

-- Unlock button (dengan build icon kunci kecil)
local submitBtn = Instance.new("TextButton", keyContent)
submitBtn.Size = UDim2.new(1, 0, 0, 48)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 16
submitBtn.AutoButtonColor = false
submitBtn.LayoutOrder = 5
submitBtn.ZIndex = 84
corner(submitBtn, 14)
pressFX(submitBtn)

-- Build key icon kecil di dalam unlock button
local unlockIconHolder = Instance.new("Frame")
unlockIconHolder.Size = UDim2.new(0, 20, 0, 16)
unlockIconHolder.Position = UDim2.new(0, 14, 0.5, -8)
unlockIconHolder.BackgroundTransparency = 1
unlockIconHolder.ZIndex = 85
unlockIconHolder.Parent = submitBtn

buildKeyIcon(unlockIconHolder, UDim2.new(0, 20, 0, 16), Color3.fromRGB(30, 30, 40))

-- Buy button (dengan build icon kartu)
local buyBtn = Instance.new("TextButton", keyContent)
buyBtn.Size = UDim2.new(1, 0, 0, 40)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.BackgroundTransparency = 0.9
buyBtn.Text = "BUY KEY"
buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 13
buyBtn.AutoButtonColor = false
buyBtn.LayoutOrder = 6
buyBtn.ZIndex = 84
corner(buyBtn, 10)
stroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.6)
pressFX(buyBtn)

-- Build card icon di buy button
local buyIconHolder = Instance.new("Frame")
buyIconHolder.Size = UDim2.new(0, 20, 0, 14)
buyIconHolder.Position = UDim2.new(0, 14, 0.5, -7)
buyIconHolder.BackgroundTransparency = 1
buyIconHolder.ZIndex = 85
buyIconHolder.Parent = buyBtn

buildCardIcon(buyIconHolder, UDim2.new(0, 20, 0, 14), Color3.fromRGB(255, 255, 255))

-- Version info
local buildInfo = Instance.new("TextLabel", keyContent)
buildInfo.Size = UDim2.new(1, 0, 0, 16)
buildInfo.BackgroundTransparency = 1
buildInfo.Text = "Build v2.1.0 | © 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
buildInfo.TextColor3 = Color3.fromRGB(80, 80, 100)
buildInfo.Font = Enum.Font.Gotham
buildInfo.TextSize = 8
buildInfo.LayoutOrder = 7
buildInfo.ZIndex = 83

-- ==================== FUNCTIONS ====================
local function submitKey()
    local key = keyInput.Text:upper():gsub("%s", "")
    
    if key == "" then
        keyStatus.Text = "Masukkan key terlebih dahulu"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        return
    end
    
    if Firebase and Firebase.ValidateKey then
        keyStatus.Text = "Checking key..."
        keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        task.spawn(function()
            local ok, isValid, message = pcall(function()
                return Firebase.ValidateKey(key, LocalPlayer.UserId, LocalPlayer.DisplayName, LocalPlayer.Name)
            end)
            
            if ok and isValid then
                keyStatus.Text = message or "Key valid!"
                keyStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                -- Simpan key ke storage
                if Storage and Storage.saveKey then
                    Storage.saveKey(key)
                elseif Storage and Storage.appSettings then
                    Storage.appSettings.savedKey = key
                    if Storage.persistSettings then
                        Storage.persistSettings()
                    end
                end
                
                task.wait(0.8)
                _G.unlock()
            else
                keyStatus.Text = message or "Key tidak valid"
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
    
    -- Coba buka browser langsung
    local opened = false
    
    -- Method 1: GuiService:OpenBrowserWindow
    pcall(function()
        if game:GetService("GuiService"):OpenBrowserWindow then
            game:GetService("GuiService"):OpenBrowserWindow(url)
            opened = true
        end
    end)
    
    -- Method 2: setclipboard + notifikasi jika tidak bisa buka browser
    if not opened then
        pcall(function()
            if setclipboard then
                setclipboard(url)
            elseif Helpers and Helpers.copyToClipboard then
                Helpers.copyToClipboard(url)
            end
        end)
        _G.showDynamicNotification("Link disalin! Buka browser manual", Color3.fromRGB(255, 180, 50))
    else
        _G.showDynamicNotification("Membuka browser...", Color3.fromRGB(0, 255, 100))
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
local keyScreenAnim = false

function _G.showKeyEntry()
    keyScreen.Visible = true
    keyInput.Text = ""
    keyStatus.Text = ""
    if not keyScreenAnim then
        keyContent.Position = UDim2.new(0, 20, -0.1, 0)
        keyContent.BackgroundTransparency = 0.2
        tween(keyContent, {Position = UDim2.new(0, 20, 0, 20)}, 0.3, Enum.EasingStyle.Quart)
        tween(keyContent, {BackgroundTransparency = 1}, 0.3)
        keyScreenAnim = true
    end
    task.wait(0.1)
    keyInput:CaptureFocus()
end

function _G.hideKeyEntry()
    keyScreen.Visible = false
    keyScreenAnim = false
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
    tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    
    if _G.PhoneState.isLocked then
        -- Cek saved key dulu
        local savedKey = nil
        if Storage and Storage.getSavedKey then
            savedKey = Storage.getSavedKey()
        end
        
        if savedKey and savedKey ~= "" and Firebase and Firebase.CheckSavedKey then
            local okCheck, isValid = pcall(function()
                return Firebase.CheckSavedKey(LocalPlayer.UserId, savedKey)
            end)
            
            if okCheck and isValid then
                _G.PhoneState.isLocked = false
                task.wait(0.3)
                if _G.goHome then _G.goHome() end
                _G.showDynamicNotification("Welcome back!", Color3.fromRGB(0, 255, 100))
                return
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
    tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function()
        phone.Visible = false
    end)
end

-- ==================== ONLINE TRACKING ====================
task.spawn(function()
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
        
        while true do
            task.wait(60)
            playerData.lastUpdate = os.time()
            playerData.mapName = game.PlaceId
            playerData.jobId = game.JobId
            Firebase.SetOnline(LocalPlayer.UserId, playerData)
        end
    end
end)

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    if Firebase and Firebase.RemoveOnline then
        Firebase.RemoveOnline(LocalPlayer.UserId)
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