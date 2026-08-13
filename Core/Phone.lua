-- Core/Phone.lua
-- Membangun frame fisik phone (bezel, notch), home screen (grid + dock),
-- dan Dynamic Island notification.
-- Dipanggil HANYA setelah requireValidKey() sukses (lihat Loader.lua).

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local T = _G.T
local Helpers = _G.Helpers

-- ================= STATE =================
_G.PhoneState = {
    selectedPlayer = nil,
    isLocked = false,  -- selalu false, sudah dihandle key system di Loader
    isCloning = false,
    toolEquipped = true,
}

-- ================= UKURAN PHONE =================
local PHONE_SIZE = UDim2.new(0, 300, 0, 560)

-- ================= ROOT GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "PhoneIDViewer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 998
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() gui.Parent = Services.CoreGui end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ================= FRAME UTAMA PHONE (bezel) =================
local phone = Instance.new("Frame")
phone.Name = "PhoneFrame"
phone.Size = UDim2.new(0, 0, 0, 0) -- dibuka lewat animasi di openPhone()
phone.AnchorPoint = Vector2.new(0.5, 0.5)
phone.Position = UDim2.new(0.5, 0, 0.5, 0)
phone.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
phone.BorderSizePixel = 0
phone.Visible = false
phone.ClipsDescendants = true
phone.ZIndex = 10
phone.Parent = gui

Helpers.corner(phone, 34)
Helpers.stroke(phone, Color3.fromRGB(60, 60, 66), 3, 0)

-- Notch / Dynamic Island bezel (kosmetik, di atas layar)
local notchFrame = Instance.new("Frame", phone)
notchFrame.Size = UDim2.new(0, 90, 0, 22)
notchFrame.Position = UDim2.new(0.5, -45, 0, 8)
notchFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notchFrame.ZIndex = 30
Helpers.corner(notchFrame, 100)

-- ================= LAYAR (screen) =================
local sh = Instance.new("Frame", phone) -- "screen holder"
sh.Name = "ScreenHolder"
sh.Size = UDim2.new(1, -12, 1, -44)
sh.Position = UDim2.new(0, 6, 0, 38)
sh.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
sh.ClipsDescendants = true
sh.ZIndex = 11
Helpers.corner(sh, 24)

-- ================= HOME SCREEN =================
local home = Instance.new("Frame", sh)
home.Name = "Home"
home.Size = UDim2.new(1, 0, 1, 0)
home.Position = UDim2.new(0, 0, 0, 0)
home.BackgroundTransparency = 1
home.ZIndex = 12

-- Jam kecil atas
local clockLbl = Instance.new("TextLabel", home)
clockLbl.Size = UDim2.new(1, -20, 0, 22)
clockLbl.Position = UDim2.new(0, 10, 0, 6)
clockLbl.BackgroundTransparency = 1
clockLbl.Text = os.date("%I:%M %p")
clockLbl.TextColor3 = T.Text or Color3.fromRGB(30, 30, 30)
clockLbl.Font = Enum.Font.GothamBold
clockLbl.TextSize = 12
clockLbl.TextXAlignment = Enum.TextXAlignment.Left
clockLbl.ZIndex = 12

task.spawn(function()
    while clockLbl.Parent do
        clockLbl.Text = os.date("%I:%M %p")
        task.wait(15)
    end
end)

-- Grid ikon (scrollable)
local appGrid = Instance.new("ScrollingFrame", home)
appGrid.Name = "AppGrid"
appGrid.Size = UDim2.new(1, -12, 1, -150)
appGrid.Position = UDim2.new(0, 6, 0, 34)
appGrid.BackgroundTransparency = 1
appGrid.BorderSizePixel = 0
appGrid.ScrollBarThickness = 3
appGrid.ScrollBarImageColor3 = T.Accent or Color3.fromRGB(30, 30, 30)
appGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
appGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
appGrid.ZIndex = 12

local gridLayout = Instance.new("UIGridLayout", appGrid)
gridLayout.CellSize = UDim2.new(0, 74, 0, 92)
gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

-- Dock (bawah, ikon tetap terlihat)
local dockBg = Instance.new("Frame", home)
dockBg.Name = "Dock"
dockBg.Size = UDim2.new(1, -16, 0, 100)
dockBg.Position = UDim2.new(0, 8, 1, -108)
dockBg.BackgroundColor3 = T.Card or Color3.fromRGB(245, 245, 245)
dockBg.BackgroundTransparency = 0.15
dockBg.ZIndex = 12
Helpers.corner(dockBg, 20)
Helpers.stroke(dockBg, T.Border or Color3.fromRGB(200, 200, 200), 1, 0.5)

local dockGrid = Instance.new("Frame", dockBg)
dockGrid.Name = "DockGrid"
dockGrid.Size = UDim2.new(1, 0, 1, 0)
dockGrid.BackgroundTransparency = 1
dockGrid.ZIndex = 12

local dockLayout = Instance.new("UIListLayout", dockGrid)
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dockLayout.Padding = UDim.new(0, 6)
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ================= DYNAMIC ISLAND NOTIFICATION =================
-- Muncul sesaat di atas layar (dekat notch) tiap kali openApp() dipanggil,
-- juga dipakai module lain lewat Helpers.showDynamicNotification / _G.showDynamicNotification.
local diHolder = Instance.new("Frame", phone)
diHolder.Name = "DynamicIsland"
diHolder.Size = UDim2.new(0, 200, 0, 26)
diHolder.Position = UDim2.new(0.5, -100, 0, 8)
diHolder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
diHolder.BackgroundTransparency = 1
diHolder.ClipsDescendants = true
diHolder.ZIndex = 40
Helpers.corner(diHolder, 100)

local diStroke = Helpers.stroke(diHolder, Color3.new(1, 1, 1), 1, 1)

local dil = Instance.new("TextLabel", diHolder)
dil.Size = UDim2.new(1, -16, 1, 0)
dil.Position = UDim2.new(0, 8, 0, 0)
dil.BackgroundTransparency = 1
dil.Text = ""
dil.TextColor3 = Color3.new(1, 1, 1)
dil.Font = Enum.Font.GothamBold
dil.TextSize = 11
dil.TextTruncate = Enum.TextTruncate.AtEnd
dil.ZIndex = 41

_G.di = diHolder
_G.dil = dil
_G.diStroke = diStroke

local diActiveToken = 0
function _G.showDynamicNotification(text, color)
    diActiveToken = diActiveToken + 1
    local myToken = diActiveToken

    dil.Text = text or ""
    diStroke.Color = color or Color3.new(1, 1, 1)
    diHolder.BackgroundTransparency = 0
    diStroke.Transparency = 0.4

    Helpers.tween(diHolder, {Size = UDim2.new(0, 200, 0, 26)}, 0.2, Enum.EasingStyle.Back)

    task.delay(2.2, function()
        if myToken ~= diActiveToken then return end -- notif baru sudah menimpa, jangan sembunyikan
        Helpers.tween(diHolder, {Size = UDim2.new(0, 90, 0, 22)}, 0.2)
        task.delay(0.2, function()
            if myToken ~= diActiveToken then return end
            diHolder.BackgroundTransparency = 1
            diStroke.Transparency = 1
        end)
    end)
end

-- ================= PHONE FUNCTIONS =================
-- showPass/hidePass/unlock tetap ada sebagai stub
-- supaya kode lama yang memanggilnya tidak error
function _G.showPass() end
function _G.hidePass() end
function _G.unlock()
    _G.PhoneState.isLocked = false
    if _G.goHome then _G.goHome() end
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    Helpers.tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    -- Langsung goHome, tidak ada lock screen lagi
    if _G.goHome then _G.goHome() end
end

function _G.closePhone()
    if not phone.Visible then return end
    Helpers.tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function() phone.Visible = false end)
end

-- ================= EXPORT =================
-- Core/BuildIcons.lua baca semua field ini lewat _G.Phone
local Phone = {
    gui = gui,
    phone = phone,
    sh = sh,
    home = home,
    appGrid = appGrid,
    gridLayout = gridLayout,
    dockBg = dockBg,
    dockGrid = dockGrid,
    clockLbl = clockLbl,
    PHONE_SIZE = PHONE_SIZE,
}

print("[Phone] Frame utama siap dibangun.")

return Phone
