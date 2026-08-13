-- ================================================
-- PHONE GUI - Fixed + Upgraded Key Entry Design
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

local function safeGradient(obj, colors, rotation)
    pcall(function()
        if obj then
            local g = Instance.new("UIGradient")
            g.Color = colors
            g.Rotation = rotation or 0
            g.Parent = obj
            return g
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

local function safeCall(fn, ...)
    local args = {...}
    local ok, res = pcall(function()
        return fn(table.unpack(args))
    end)
    if not ok then
        warn("[PhoneGUI] Error:", res)
        return false, nil
    end
    return true, res
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
sh.ZIndex = 1
sh.Parent = sa

local home = Instance.new("Frame")
home.Size = UDim2.new(1, 0, 1, 0)
home.BackgroundTransparency = 1
home.ClipsDescendants = true
home.ZIndex = 1
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

-- ================================================================
-- ==================== KEY SCREEN (UPGRADED) ====================
-- ================================================================

local keyScreen = Instance.new("Frame")
keyScreen.Size = UDim2.new(1, 0, 1, 0)
keyScreen.Position = UDim2.new(0, 0, 0, 0)
keyScreen.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
keyScreen.ZIndex = 200          -- dinaikkan supaya selalu di atas home/dock
keyScreen.Visible = false
keyScreen.BorderSizePixel = 0
keyScreen.ClipsDescendants = true
keyScreen.Parent = sa
safeCorner(keyScreen, 30)

-- Background gradient utama
local keyBgGradient = Instance.new("UIGradient")
keyBgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 32)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 8, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 20, 36)),
})
keyBgGradient.Rotation = 135
keyBgGradient.Parent = keyScreen

-- Glow blobs dekoratif (radial-ish dengan blur transparansi pakai frame bulat besar)
local function makeGlow(size, pos, color, transparency, zindex)
    local glow = Instance.new("Frame")
    glow.Size = size
    glow.Position = pos
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundColor3 = color
    glow.BackgroundTransparency = transparency
    glow.BorderSizePixel = 0
    glow.ZIndex = zindex or 201
    glow.Parent = keyScreen
    safeCorner(glow, 500)
    return glow
end

local glow1 = makeGlow(UDim2.new(0, 220, 0, 220), UDim2.new(0, 20, 0, 40), Color3.fromRGB(120, 90, 255), 0.85, 201)
local glow2 = makeGlow(UDim2.new(0, 180, 0, 180), UDim2.new(1, -20, 0, 120), Color3.fromRGB(80, 200, 255), 0.88, 201)

-- Animasi glow melayang pelan
task.spawn(function()
    while keyScreen.Parent do
        safeTween(glow1, {Position = UDim2.new(0, 40, 0, 70)}, 3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        safeTween(glow2, {Position = UDim2.new(1, -40, 0, 90)}, 3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(3.5)
        safeTween(glow1, {Position = UDim2.new(0, 20, 0, 40)}, 3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        safeTween(glow2, {Position = UDim2.new(1, -20, 0, 120)}, 3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(3.5)
    end
end)

-- Key Content Wrapper (buat animasi masuk)
local keyContent = Instance.new("Frame")
keyContent.Size = UDim2.new(1, -44, 1, -44)
keyContent.Position = UDim2.new(0, 22, 0, 22)
keyContent.BackgroundTransparency = 1
keyContent.ZIndex = 210
keyContent.Parent = keyScreen

local keyLayout = Instance.new("UIListLayout")
keyLayout.Padding = UDim.new(0, 14)
keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
keyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
keyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
keyLayout.Parent = keyContent

-- Spacer atas fleksibel biar konten center vertikal enak
local topSpacer = Instance.new("Frame")
topSpacer.Size = UDim2.new(1, 0, 0, 4)
topSpacer.BackgroundTransparency = 1
topSpacer.LayoutOrder = 0
topSpacer.Parent = keyContent

-- ==================== BUILD LOCK ICON (UPGRADED, CUSTOM) ====================
local lockOuterRing = Instance.new("Frame")
lockOuterRing.Size = UDim2.new(0, 96, 0, 96)
lockOuterRing.BackgroundTransparency = 1
lockOuterRing.LayoutOrder = 1
lockOuterRing.ZIndex = 211
lockOuterRing.Parent = keyContent

-- Ring animasi berputar di belakang icon
local ringSpin = Instance.new("Frame")
ringSpin.Size = UDim2.new(1, 0, 1, 0)
ringSpin.Position = UDim2.new(0.5, 0, 0.5, 0)
ringSpin.AnchorPoint = Vector2.new(0.5, 0.5)
ringSpin.BackgroundTransparency = 1
ringSpin.ZIndex = 211
ringSpin.Parent = lockOuterRing
safeStroke(ringSpin, Color3.fromRGB(140, 110, 255), 2, 0.55)
safeCorner(ringSpin, 500)

task.spawn(function()
    local rot = 0
    while ringSpin.Parent do
        rot = (rot + 1) % 360
        ringSpin.Rotation = rot
        task.wait(0.03)
    end
end)

-- Container gembok dengan gradient premium
local lockContainer = Instance.new("Frame")
lockContainer.Size = UDim2.new(0, 78, 0, 78)
lockContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
lockContainer.AnchorPoint = Vector2.new(0.5, 0.5)
lockContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockContainer.BackgroundTransparency = 0.92
lockContainer.ZIndex = 212
lockContainer.Parent = lockOuterRing
safeCorner(lockContainer, 24)
safeStroke(lockContainer, Color3.fromRGB(180, 160, 255), 1.5, 0.5)
safeGradient(lockContainer, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 110, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)),
}), 90)

-- Badan gembok
local lockBody = Instance.new("Frame")
lockBody.Size = UDim2.new(0, 36, 0, 28)
lockBody.Position = UDim2.new(0.5, 0, 0.58, 0)
lockBody.AnchorPoint = Vector2.new(0.5, 0.5)
lockBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockBody.ZIndex = 213
lockBody.Parent = lockContainer
safeCorner(lockBody, 8)
safeGradient(lockBody, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 215, 255)),
}), 90)

-- Lubang kunci (persegi bawah)
local keyhole = Instance.new("Frame")
keyhole.Size = UDim2.new(0, 8, 0, 11)
keyhole.Position = UDim2.new(0.5, 0, 0.62, 0)
keyhole.AnchorPoint = Vector2.new(0.5, 0.5)
keyhole.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
keyhole.ZIndex = 214
keyhole.Parent = lockBody
safeCorner(keyhole, 3)

-- Lingkaran lubang kunci
local keyholeCircle = Instance.new("Frame")
keyholeCircle.Size = UDim2.new(0, 9, 0, 9)
keyholeCircle.Position = UDim2.new(0.5, 0, 0.32, 0)
keyholeCircle.AnchorPoint = Vector2.new(0.5, 0.5)
keyholeCircle.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
keyholeCircle.ZIndex = 214
keyholeCircle.Parent = lockBody
safeCorner(keyholeCircle, 100)

-- Shackle (lengkungan atas) - dibentuk dari stroke arc-like pakai frame + corner besar
local shackle = Instance.new("Frame")
shackle.Size = UDim2.new(0, 26, 0, 24)
shackle.Position = UDim2.new(0.5, 0, 0.30, 0)
shackle.AnchorPoint = Vector2.new(0.5, 0.5)
shackle.BackgroundTransparency = 1
shackle.ZIndex = 213
shackle.Parent = lockContainer

local shackleStroke = Instance.new("UIStroke")
shackleStroke.Color = Color3.fromRGB(255, 255, 255)
shackleStroke.Thickness = 4
shackleStroke.Parent = shackle
safeCorner(shackle, 100)

-- Mask bawah shackle biar keliatan seperti "U" terbuka ke bawah menyatu ke body
local shackleMask = Instance.new("Frame")
shackleMask.Size = UDim2.new(1, 4, 0, 14)
shackleMask.Position = UDim2.new(0.5, 0, 1, 4)
shackleMask.AnchorPoint = Vector2.new(0.5, 0.5)
shackleMask.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shackleMask.BackgroundTransparency = 0.92
shackleMask.BorderSizePixel = 0
shackleMask.ZIndex = 213
shackleMask.Parent = lockContainer

-- Spacer kecil
local spacer1 = Instance.new("Frame")
spacer1.Size = UDim2.new(1, 0, 0, 2)
spacer1.BackgroundTransparency = 1
spacer1.LayoutOrder = 2
spacer1.Parent = keyContent

-- ==================== TITLE ====================
local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 32)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "ACCESS REQUIRED"
keyTitle.TextColor3 = Color3.new(1, 1, 1)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 22
keyTitle.LayoutOrder = 3
keyTitle.ZIndex = 211
keyTitle.Parent = keyContent

-- ==================== DESCRIPTION ====================
local keyDesc = Instance.new("TextLabel")
keyDesc.Size = UDim2.new(1, -10, 0, 32)
keyDesc.BackgroundTransparency = 1
keyDesc.Text = "Masukkan access key kamu untuk membuka semua fitur premium"
keyDesc.TextColor3 = Color3.fromRGB(160, 160, 190)
keyDesc.Font = Enum.Font.Gotham
keyDesc.TextSize = 12
keyDesc.TextWrapped = true
keyDesc.LayoutOrder = 4
keyDesc.ZIndex = 211
keyDesc.Parent = keyContent

-- Spacer sebelum input
local spacer2 = Instance.new("Frame")
spacer2.Size = UDim2.new(1, 0, 0, 4)
spacer2.BackgroundTransparency = 1
spacer2.LayoutOrder = 5
spacer2.Parent = keyContent

-- ==================== INPUT CONTAINER (UPGRADED) ====================
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, 0, 0, 52)
inputContainer.BackgroundColor3 = Color3.fromRGB(20, 18, 34)
inputContainer.LayoutOrder = 6
inputContainer.ZIndex = 211
inputContainer.Parent = keyContent
safeCorner(inputContainer, 16)

local inputStroke = safeStroke and nil
local inputStrokeObj = Instance.new("UIStroke")
inputStrokeObj.Color = Color3.fromRGB(120, 100, 220)
inputStrokeObj.Thickness = 1.5
inputStrokeObj.Transparency = 0.4
inputStrokeObj.Parent = inputContainer

-- Key icon kecil di input (bentuk kunci sederhana: lingkaran + batang + gigi)
local keyIconHolder = Instance.new("Frame")
keyIconHolder.Size = UDim2.new(0, 22, 0, 16)
keyIconHolder.Position = UDim2.new(0, 14, 0.5, 0)
keyIconHolder.AnchorPoint = Vector2.new(0, 0.5)
keyIconHolder.BackgroundTransparency = 1
keyIconHolder.ZIndex = 212
keyIconHolder.Parent = inputContainer

local keyIconCircle = Instance.new("Frame")
keyIconCircle.Size = UDim2.new(0, 10, 0, 10)
keyIconCircle.Position = UDim2.new(0, 0, 0.5, 0)
keyIconCircle.AnchorPoint = Vector2.new(0, 0.5)
keyIconCircle.BackgroundTransparency = 1
keyIconCircle.ZIndex = 212
keyIconCircle.Parent = keyIconHolder
local kicStroke = Instance.new("UIStroke")
kicStroke.Color = Color3.fromRGB(160, 150, 220)
kicStroke.Thickness = 2
kicStroke.Parent = keyIconCircle
safeCorner(keyIconCircle, 100)

local keyIconBar = Instance.new("Frame")
keyIconBar.Size = UDim2.new(0, 12, 0, 3)
keyIconBar.Position = UDim2.new(0, 9, 0.5, -1.5)
keyIconBar.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
keyIconBar.ZIndex = 212
keyIconBar.Parent = keyIconHolder
safeCorner(keyIconBar, 2)

local keyIconTooth1 = Instance.new("Frame")
keyIconTooth1.Size = UDim2.new(0, 3, 0, 6)
keyIconTooth1.Position = UDim2.new(0, 15, 0.5, -1.5)
keyIconTooth1.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
keyIconTooth1.ZIndex = 212
keyIconTooth1.Parent = keyIconHolder

local keyIconTooth2 = Instance.new("Frame")
keyIconTooth2.Size = UDim2.new(0, 3, 0, 4)
keyIconTooth2.Position = UDim2.new(0, 19, 0.5, -1.5)
keyIconTooth2.BackgroundColor3 = Color3.fromRGB(160, 150, 220)
keyIconTooth2.ZIndex = 212
keyIconTooth2.Parent = keyIconHolder

-- TextBox
local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -85, 1, 0)
keyInput.Position = UDim2.new(0, 44, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.Text = ""
keyInput.PlaceholderText = "KEY-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
keyInput.TextColor3 = Color3.new(1, 1, 1)
keyInput.Font = Enum.Font.GothamBold
keyInput.TextSize = 15
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.ZIndex = 212
keyInput.Parent = inputContainer

-- Paste button kecil di kanan input
local pasteBtn = Instance.new("TextButton")
pasteBtn.Size = UDim2.new(0, 34, 0, 34)
pasteBtn.Position = UDim2.new(1, -42, 0.5, 0)
pasteBtn.AnchorPoint = Vector2.new(0, 0.5)
pasteBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 220)
pasteBtn.BackgroundTransparency = 0.85
pasteBtn.Text = "📋"
pasteBtn.TextSize = 14
pasteBtn.AutoButtonColor = false
pasteBtn.ZIndex = 212
pasteBtn.Parent = inputContainer
safeCorner(pasteBtn, 10)
safePressFX(pasteBtn)

pasteBtn.MouseButton1Click:Connect(function()
    local ok, clip = pcall(function() return getclipboard() end)
    if ok and clip and clip ~= "" then
        keyInput.Text = clip
        _G.showDynamicNotification("Key ditempel!", Color3.fromRGB(120, 100, 220))
    end
end)

-- Fokus glow di border input saat difokus
keyInput.Focused:Connect(function()
    safeTween(inputStrokeObj, {Transparency = 0.1}, 0.2)
end)
keyInput.FocusLost:Connect(function()
    safeTween(inputStrokeObj, {Transparency = 0.4}, 0.2)
end)

-- ==================== STATUS LABEL ====================
local keyStatus = Instance.new("TextLabel")
keyStatus.Size = UDim2.new(1, 0, 0, 20)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 11
keyStatus.LayoutOrder = 7
keyStatus.ZIndex = 211
keyStatus.Parent = keyContent

-- ==================== UNLOCK BUTTON (UPGRADED) ====================
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, 0, 0, 50)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "🔓  UNLOCK"
submitBtn.TextColor3 = Color3.fromRGB(20, 15, 40)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 16
submitBtn.AutoButtonColor = false
submitBtn.LayoutOrder = 8
submitBtn.ZIndex = 211
submitBtn.Parent = keyContent
safeCorner(submitBtn, 16)
safeGradient(submitBtn, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 220, 245)),
}), 90)
safePressFX(submitBtn)

-- Loading spinner overlay di tombol (dipakai saat checking)
local loadingDot = Instance.new("Frame")
loadingDot.Size = UDim2.new(0, 8, 0, 8)
loadingDot.AnchorPoint = Vector2.new(0.5, 0.5)
loadingDot.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingDot.BackgroundColor3 = Color3.fromRGB(120, 100, 220)
loadingDot.Visible = false
loadingDot.ZIndex = 212
loadingDot.Parent = submitBtn
safeCorner(loadingDot, 100)

local loadingSpin
local function startLoading()
    submitBtn.Text = ""
    loadingDot.Visible = true
    loadingSpin = true
    task.spawn(function()
        local t = 0
        while loadingSpin do
            t = t + 0.05
            loadingDot.Position = UDim2.new(0.5 + math.cos(t * 6) * 0.15, 0, 0.5 + math.sin(t * 6) * 0.15, 0)
            task.wait(0.03)
        end
    end)
end
local function stopLoading(text)
    loadingSpin = false
    loadingDot.Visible = false
    submitBtn.Text = text or "🔓  UNLOCK"
end

-- ==================== BUY BUTTON ====================
local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(1, 0, 0, 42)
buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.BackgroundTransparency = 0.92
buyBtn.Text = "💳  BUY KEY"
buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyBtn.Font = Enum.Font.GothamBold
buyBtn.TextSize = 13
buyBtn.AutoButtonColor = false
buyBtn.LayoutOrder = 9
buyBtn.ZIndex = 211
buyBtn.Parent = keyContent
safeCorner(buyBtn, 12)
safeStroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.65)
safePressFX(buyBtn)

-- ==================== VERSION INFO ====================
local buildInfo = Instance.new("TextLabel")
buildInfo.Size = UDim2.new(1, 0, 0, 16)
buildInfo.BackgroundTransparency = 1
buildInfo.Text = "Build v2.2.0 | © 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw")
buildInfo.TextColor3 = Color3.fromRGB(80, 80, 100)
buildInfo.Font = Enum.Font.Gotham
buildInfo.TextSize = 8
buildInfo.LayoutOrder = 10
buildInfo.ZIndex = 211
buildInfo.Parent = keyContent

-- ==================== FUNCTIONS ====================
local isSubmitting = false

local function shakeInput()
    pcall(function()
        local origPos = inputContainer.Position
        safeTween(inputContainer, {Position = origPos + UDim2.new(0, 8, 0, 0)}, 0.06)
        task.delay(0.06, function()
            safeTween(inputContainer, {Position = origPos - UDim2.new(0, 8, 0, 0)}, 0.06)
            task.delay(0.06, function()
                safeTween(inputContainer, {Position = origPos}, 0.06)
            end)
        end)
    end)
end

local function submitKey()
    if isSubmitting then return end

    local key = keyInput.Text:upper():gsub("%s", "")

    if key == "" then
        keyStatus.Text = "⚠️ Masukkan key terlebih dahulu"
        keyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
        shakeInput()
        return
    end

    isSubmitting = true
    startLoading()
    keyStatus.Text = "⏳ Checking key..."
    keyStatus.TextColor3 = Color3.fromRGB(200, 190, 255)

    if Firebase and Firebase.ValidateKey then
        task.spawn(function()
            local ok, isValid, message = pcall(function()
                return Firebase.ValidateKey(key, LocalPlayer.UserId, LocalPlayer.DisplayName, LocalPlayer.Name)
            end)

            -- pcall mengembalikan (ok, ...results). Perbaiki unpack:
            if ok then
                -- result asli ada di isValid, message posisi kedua dari return function
            end

            isSubmitting = false
            stopLoading()

            if ok then
                local valid, msg = isValid, message
                if valid then
                    keyStatus.Text = "✅ " .. (msg or "Key valid!")
                    keyStatus.TextColor3 = Color3.fromRGB(0, 255, 130)

                    pcall(function()
                        if Storage.saveKey then
                            Storage.saveKey(key)
                        end
                    end)

                    task.wait(0.8)
                    _G.unlock()
                else
                    keyStatus.Text = "❌ " .. (msg or "Key tidak valid")
                    keyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
                    shakeInput()
                end
            else
                warn("[Phone] Firebase.ValidateKey error:", isValid)
                keyStatus.Text = "❌ Gagal terhubung ke server"
                keyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
                shakeInput()
            end
        end)
    else
        -- Tidak ada Firebase configured — fallback langsung unlock (dev/testing mode)
        task.spawn(function()
            task.wait(0.5)
            isSubmitting = false
            stopLoading()
            _G.unlock()
        end)
    end
end

submitBtn.MouseButton1Click:Connect(submitKey)

keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then submitKey() end
end)

buyBtn.MouseButton1Click:Connect(function()
    local url = Config.BUY_KEY_URL or "https://discord.gg/yourdiscord"
    pcall(function() setclipboard(url) end)
    _G.showDynamicNotification("Link pembelian disalin!", Color3.fromRGB(180, 150, 255))
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
    isSubmitting = false
    stopLoading()

    -- Animasi masuk: fade + scale dari kecil
    keyContent.Position = UDim2.new(0, 22, 0.05, 22)
    keyContent.BackgroundTransparency = 1
    safeTween(keyContent, {Position = UDim2.new(0, 22, 0, 22)}, 0.35, Enum.EasingStyle.Back)

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
    _G.showDynamicNotification("Phone Unlocked!", Color3.fromRGB(0, 255, 130))
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    safeTween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)

    if _G.PhoneState.isLocked then
        task.spawn(function()
            local savedKey = nil

            -- Ambil saved key dengan aman
            local okGet, resGet = pcall(function()
                if Storage.getSavedKey then
                    return Storage.getSavedKey()
                end
                return nil
            end)
            if okGet then
                savedKey = resGet
            else
                warn("[Phone] Storage.getSavedKey error:", resGet)
            end

            local autoUnlocked = false

            if savedKey and savedKey ~= "" and Firebase and Firebase.CheckSavedKey then
                local done = false
                local isValid = false

                task.spawn(function()
                    local okCheck, resCheck = pcall(function()
                        return Firebase.CheckSavedKey(LocalPlayer.UserId, savedKey)
                    end)
                    if okCheck then
                        isValid = resCheck
                    else
                        warn("[Phone] Firebase.CheckSavedKey error:", resCheck)
                    end
                    done = true
                end)

                -- Timeout manual 5 detik supaya tidak menggantung
                local waited = 0
                while not done and waited < 5 do
                    task.wait(0.1)
                    waited = waited + 0.1
                end

                if done and isValid then
                    autoUnlocked = true
                    _G.PhoneState.isLocked = false
                    if _G.goHome then _G.goHome() end
                    _G.showDynamicNotification("✅ Welcome back!", Color3.fromRGB(0, 255, 130))
                else
                    if not done then
                        warn("[Phone] Firebase.CheckSavedKey timeout")
                    end
                    pcall(function()
                        if Storage.clearSavedKey then
                            Storage.clearSavedKey()
                        end
                    end)
                end
            end

            -- Fallback tegas: kalau belum unlocked, SELALU tampilkan key entry
            if not autoUnlocked then
                task.wait(0.3)
                _G.showKeyEntry()
            end
        end)
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

-- ==================== ONLINE TRACKING ====================
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
        pcall(function()
            Firebase.SetOnline(LocalPlayer.UserId, playerData)
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