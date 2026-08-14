-- ================================================
-- SETTINGS APP - Full Rewrite
-- Fix: timer pakai GetFullKeyInfo (1 roundtrip), countdown real, info lengkap
-- ================================================

local Services       = _G.Services
local LocalPlayer    = _G.LocalPlayer
local TeleportService = Services.TeleportService
local T              = _G.T or {}
local Helpers        = _G.Helpers or {}
local Storage        = _G.Storage or {}
local Firebase       = _G.Firebase
local Config         = _G.Config or {}

local appContent     = _G.appContent
local appSettings    = Storage.appSettings or {}

local corner   = Helpers.corner
local stroke   = Helpers.stroke
local pressFX  = Helpers.pressFX

local function safeTween(o, p, t)
    pcall(function()
        game:GetService("TweenService"):Create(o, TweenInfo.new(t or 0.2), p):Play()
    end)
end

-- ==================== COLOR PALETTE ====================
local C = {
    bg      = Color3.fromRGB(248, 248, 252),
    card    = Color3.fromRGB(255, 255, 255),
    card2   = Color3.fromRGB(242, 242, 248),
    border  = Color3.fromRGB(220, 220, 228),
    text    = Color3.fromRGB(20,  20,  28 ),
    text2   = Color3.fromRGB(100, 100, 115),
    text3   = Color3.fromRGB(160, 160, 175),
    accent  = Color3.fromRGB(0,   150, 255),
    green   = Color3.fromRGB(0,   200, 100),
    gold    = Color3.fromRGB(255, 185, 40 ),
    red     = Color3.fromRGB(255, 70,  70 ),
    discord = Color3.fromRGB(88,  101, 242),
    wa      = Color3.fromRGB(37,  211, 102),
    tg      = Color3.fromRGB(0,   136, 204),
}

-- ==================== UI BUILDER HELPERS ====================
local function section(title, order)
    local sec = Instance.new("Frame")
    sec.Name = "Sec_" .. title
    sec.Size = UDim2.new(1,0,0,0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundTransparency = 1
    sec.LayoutOrder = order
    sec.Parent = appContent

    local lay = Instance.new("UIListLayout", sec)
    lay.Padding = UDim.new(0,6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1,-8,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = C.text2
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = 0

    return sec
end

local function card(parent, order)
    local c = Instance.new("Frame")
    c.Name = "Card"
    c.Size = UDim2.new(1,0,0,0)
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.BackgroundColor3 = C.card
    c.BorderSizePixel = 0
    c.LayoutOrder = order
    c.Parent = parent
    corner(c, 14)
    stroke(c, C.border, 1, 0.3)

    local lay = Instance.new("UIListLayout", c)
    lay.Padding = UDim.new(0,0)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", c)
    pad.PaddingTop    = UDim.new(0,10)
    pad.PaddingBottom = UDim.new(0,10)
    pad.PaddingLeft   = UDim.new(0,12)
    pad.PaddingRight  = UDim.new(0,12)

    return c
end

local function label(parent, txt, sz, col, font, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,sz+4)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = col or C.text
    l.Font = font or Enum.Font.Gotham
    l.TextSize = sz or 11
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0
    l.Parent = parent
    return l
end

local function separator(parent, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,1)
    f.BackgroundColor3 = C.border
    f.BackgroundTransparency = 0.5
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.Parent = parent
    return f
end

local function actionRow(parent, order, title, sub, iconChar, iconColor, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,48)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = parent
    pressFX(btn)

    local iconBg = Instance.new("Frame", btn)
    iconBg.Size = UDim2.new(0,34,0,34)
    iconBg.Position = UDim2.new(0,0,0.5,-17)
    iconBg.BackgroundColor3 = iconColor or C.accent
    iconBg.BackgroundTransparency = 0.85
    corner(iconBg, 10)

    local iconLbl = Instance.new("TextLabel", iconBg)
    iconLbl.Size = UDim2.new(1,0,1,0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = iconChar or "⚡"
    iconLbl.TextSize = 17
    iconLbl.Font = Enum.Font.GothamBold

    local titleLbl = Instance.new("TextLabel", btn)
    titleLbl.Size = UDim2.new(1,-46,0,18)
    titleLbl.Position = UDim2.new(0,44,0,7)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = C.text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    if sub and sub ~= "" then
        local subLbl = Instance.new("TextLabel", btn)
        subLbl.Size = UDim2.new(1,-46,0,14)
        subLbl.Position = UDim2.new(0,44,0,26)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = sub
        subLbl.TextColor3 = C.text3
        subLbl.Font = Enum.Font.Gotham
        subLbl.TextSize = 9
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local chevron = Instance.new("TextLabel", btn)
    chevron.Size = UDim2.new(0,20,1,0)
    chevron.Position = UDim2.new(1,-22,0,0)
    chevron.BackgroundTransparency = 1
    chevron.Text = "›"
    chevron.TextColor3 = C.text3
    chevron.Font = Enum.Font.GothamBold
    chevron.TextSize = 18

    if onClick then btn.MouseButton1Click:Connect(onClick) end
    return btn
end

-- ==================== MAIN FUNCTION ====================
function _G.openSettingsApp()
    pcall(function()

        -- ============ 1. KEY STATUS DENGAN TIMER ============
        local keySec = section("KEY STATUS", 1)
        local keyCard = card(keySec, 1)

        -- Header baris atas: icon + status badge
        local keyTopRow = Instance.new("Frame", keyCard)
        keyTopRow.Size = UDim2.new(1,0,0,36)
        keyTopRow.BackgroundTransparency = 1
        keyTopRow.LayoutOrder = 0

        local keyIconFrame = Instance.new("Frame", keyTopRow)
        keyIconFrame.Size = UDim2.new(0,32,0,32)
        keyIconFrame.Position = UDim2.new(0,0,0.5,-16)
        keyIconFrame.BackgroundColor3 = C.accent
        keyIconFrame.BackgroundTransparency = 0.85
        corner(keyIconFrame, 9)

        local keyIconLbl = Instance.new("TextLabel", keyIconFrame)
        keyIconLbl.Size = UDim2.new(1,0,1,0)
        keyIconLbl.BackgroundTransparency = 1
        keyIconLbl.Text = "🔑"
        keyIconLbl.TextSize = 16

        local statusBadge = Instance.new("TextLabel", keyTopRow)
        statusBadge.Size = UDim2.new(0,70,0,22)
        statusBadge.Position = UDim2.new(0,40,0.5,-11)
        statusBadge.BackgroundColor3 = C.green
        statusBadge.BackgroundTransparency = 0.85
        statusBadge.Text = "ACTIVE"
        statusBadge.TextColor3 = C.green
        statusBadge.Font = Enum.Font.GothamBlack
        statusBadge.TextSize = 9
        corner(statusBadge, 7)

        -- Timer besar
        local timerLbl = Instance.new("TextLabel", keyCard)
        timerLbl.Size = UDim2.new(1,0,0,44)
        timerLbl.BackgroundTransparency = 1
        timerLbl.Text = "--:--:--"
        timerLbl.TextColor3 = C.text
        timerLbl.Font = Enum.Font.GothamBlack
        timerLbl.TextSize = 30
        timerLbl.LayoutOrder = 1

        -- Progress bar
        local progBg = Instance.new("Frame", keyCard)
        progBg.Size = UDim2.new(1,0,0,8)
        progBg.BackgroundColor3 = C.card2
        progBg.BorderSizePixel = 0
        progBg.LayoutOrder = 2
        corner(progBg, 4)

        local progFill = Instance.new("Frame", progBg)
        progFill.Size = UDim2.new(1,0,1,0)
        progFill.BackgroundColor3 = C.green
        progFill.BorderSizePixel = 0
        corner(progFill, 4)

        -- Info detail key
        local keyDetailRow = Instance.new("Frame", keyCard)
        keyDetailRow.Size = UDim2.new(1,0,0,0)
        keyDetailRow.AutomaticSize = Enum.AutomaticSize.Y
        keyDetailRow.BackgroundTransparency = 1
        keyDetailRow.LayoutOrder = 3

        local keyDetailLbl = Instance.new("TextLabel", keyDetailRow)
        keyDetailLbl.Size = UDim2.new(1,0,0,0)
        keyDetailLbl.AutomaticSize = Enum.AutomaticSize.Y
        keyDetailLbl.BackgroundTransparency = 1
        keyDetailLbl.Text = "Memuat info key..."
        keyDetailLbl.TextColor3 = C.text2
        keyDetailLbl.Font = Enum.Font.Code
        keyDetailLbl.TextSize = 9
        keyDetailLbl.TextWrapped = true
        keyDetailLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- *** UPDATE TIMER ***
        -- Ambil data sekali dari Firebase (bukan tiap detik), lalu countdown lokal
        local keyExpiresAt = 0
        local keyTotalSecs = 604800
        local keyCode = ""

        local function fetchKeyData()
            if not Firebase or not Firebase.GetFullKeyInfo then return end
            local ok, info = pcall(function()
                return Firebase.GetFullKeyInfo(LocalPlayer.UserId)
            end)
            if not ok or not info then return end

            keyExpiresAt = info.expiresAt or 0
            keyTotalSecs = info.totalSecs or 604800
            keyCode      = info.key or ""

            if info.ok then
                keyDetailLbl.Text = string.format(
                    "Key: %s\nPemilik: %s\nUser ID: %s\nPaket: %s",
                    info.key or "-",
                    info.playerName or "Unknown",
                    info.usedBy or "-",
                    info.durationLabel or "-"
                )
            else
                keyDetailLbl.Text = info.message or "Tidak ada key aktif."
                timerLbl.Text  = "NO KEY"
                timerLbl.TextColor3 = C.text3
                statusBadge.Text = "INACTIVE"
                statusBadge.BackgroundColor3 = C.text3
                statusBadge.TextColor3 = C.text3
                progFill.Size = UDim2.new(0,0,1,0)
            end
        end

        -- Fetch awal
        task.spawn(fetchKeyData)

        -- Refresh dari server tiap 5 menit (bukan tiap detik → hemat kuota Firebase)
        task.spawn(function()
            while timerLbl.Parent do
                task.wait(300)
                fetchKeyData()
            end
        end)

        -- Countdown lokal tiap detik (tidak butuh Firebase, pure math)
        task.spawn(function()
            while timerLbl.Parent do
                task.wait(1)
                if keyExpiresAt <= 0 then continue end
                local rem = keyExpiresAt - os.time()

                if rem <= 0 then
                    timerLbl.Text = "EXPIRED"
                    timerLbl.TextColor3 = C.red
                    statusBadge.Text = "EXPIRED"
                    statusBadge.BackgroundColor3 = C.red
                    statusBadge.TextColor3 = C.red
                    progFill.Size = UDim2.new(0,0,1,0)
                    continue
                end

                local h = math.floor(rem / 3600)
                local m = math.floor((rem % 3600) / 60)
                local s = rem % 60
                timerLbl.Text = ("%02d:%02d:%02d"):format(h, m, s)

                local ratio = math.clamp(rem / keyTotalSecs, 0, 1)
                progFill.Size = UDim2.new(ratio, 0, 1, 0)

                if rem > 86400 then
                    timerLbl.TextColor3 = C.green
                    statusBadge.Text = "ACTIVE"
                    statusBadge.BackgroundColor3 = C.green
                    statusBadge.TextColor3 = C.green
                    progFill.BackgroundColor3 = C.green
                elseif rem > 3600 then
                    timerLbl.TextColor3 = C.gold
                    statusBadge.Text = "WARNING"
                    statusBadge.BackgroundColor3 = C.gold
                    statusBadge.TextColor3 = C.gold
                    progFill.BackgroundColor3 = C.gold
                else
                    timerLbl.TextColor3 = C.red
                    statusBadge.Text = "CRITICAL"
                    statusBadge.BackgroundColor3 = C.red
                    statusBadge.TextColor3 = C.red
                    progFill.BackgroundColor3 = C.red
                end
            end
        end)

        -- ============ 2. DEVELOPER PROFILE ============
        local devSec = section("DEVELOPER", 2)
        local devCard = card(devSec, 1)

        local devRow = Instance.new("Frame", devCard)
        devRow.Size = UDim2.new(1,0,0,62)
        devRow.BackgroundTransparency = 1
        devRow.LayoutOrder = 0

        local devAvatarFrame = Instance.new("Frame", devRow)
        devAvatarFrame.Size = UDim2.new(0,50,0,50)
        devAvatarFrame.Position = UDim2.new(0,0,0.5,-25)
        devAvatarFrame.BackgroundColor3 = Color3.fromRGB(255,200,50)
        devAvatarFrame.BackgroundTransparency = 0.7
        corner(devAvatarFrame, 100)
        stroke(devAvatarFrame, C.gold, 2, 0)

        local devAvatar = Instance.new("ImageLabel", devAvatarFrame)
        devAvatar.Size = UDim2.new(1,-6,1,-6)
        devAvatar.Position = UDim2.new(0,3,0,3)
        devAvatar.BackgroundColor3 = Color3.fromRGB(220,220,220)
        devAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" ..
            tostring(Config.DEVELOPER_USER_ID or LocalPlayer.UserId) ..
            "&width=100&height=100&format=png"
        corner(devAvatar, 100)

        local devName = Instance.new("TextLabel", devRow)
        devName.Size = UDim2.new(1,-62,0,22)
        devName.Position = UDim2.new(0,62,0,10)
        devName.BackgroundTransparency = 1
        devName.Text = Config.DEVELOPER_USERNAME or "AlfreadR0rw"
        devName.TextColor3 = C.text
        devName.Font = Enum.Font.GothamBlack
        devName.TextSize = 14
        devName.TextXAlignment = Enum.TextXAlignment.Left

        local ownerBadge = Instance.new("TextLabel", devRow)
        ownerBadge.Size = UDim2.new(0,52,0,18)
        ownerBadge.Position = UDim2.new(0,62,0,34)
        ownerBadge.BackgroundColor3 = C.gold
        ownerBadge.Text = "OWNER"
        ownerBadge.TextColor3 = Color3.fromRGB(80,50,0)
        ownerBadge.Font = Enum.Font.GothamBlack
        ownerBadge.TextSize = 8
        corner(ownerBadge, 9)

        -- ============ 3. SOCIAL MEDIA ============
        local socSec = section("SOCIAL MEDIA", 3)
        local socCard = card(socSec, 1)

        local socials = {
            {"Discord",  "💬", C.discord, Config.DiscordURL  or ""},
            {"WhatsApp", "📱", C.wa,      Config.WhatsAppURL or ""},
            {"Telegram", "✈️", C.tg,      Config.TelegramURL or ""},
        }

        for i, soc in ipairs(socials) do
            local name, icon, col, link = soc[1], soc[2], soc[3], soc[4]
            if i > 1 then separator(socCard, (i-1)*2) end
            actionRow(socCard, i*2, name, "Klik untuk menyalin link", icon, col, function()
                pcall(function() Helpers.copyToClipboard(link) end)
                _G.showDynamicNotification(name .. " link disalin!", col)
            end)
        end

        -- ============ 4. AKSI CEPAT ============
        local actSec = section("AKSI CEPAT", 4)
        local actCard = card(actSec, 1)

        local actions = {
            {"Rejoin Server",  "Keluar dan masuk ulang",    "🔄", C.accent, function()
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
            end},
            {"Copy User ID",   "Salin ID Roblox kamu",      "🆔", C.accent, function()
                pcall(function() Helpers.copyToClipboard(tostring(LocalPlayer.UserId)) end)
                _G.showDynamicNotification("User ID disalin!", C.green)
            end},
            {"Buy Key",        "Beli key akses premium",    "💳", C.gold, function()
                local url = Config.BUY_KEY_URL or "https://discord.gg/"
                pcall(function() Helpers.copyToClipboard(url) end)
                _G.showDynamicNotification("Link pembelian disalin!", C.gold)
            end},
            {"Hapus Key Lokal", "Reset key di device ini",  "🗑️", C.red, function()
                if Storage.appSettings then
                    Storage.appSettings.savedKey = nil
                    pcall(function() if Storage.persistSettings then Storage.persistSettings() end end)
                end
                keyExpiresAt = 0
                timerLbl.Text = "NO KEY"
                timerLbl.TextColor3 = C.text3
                statusBadge.Text = "INACTIVE"
                statusBadge.TextColor3 = C.text3
                keyDetailLbl.Text = "Key dihapus dari device."
                _G.showDynamicNotification("Key dihapus dari device", C.red)
            end},
        }

        for i, act in ipairs(actions) do
            if i > 1 then separator(actCard, (i-1)*2) end
            actionRow(actCard, i*2, act[1], act[2], act[3], act[4], act[5])
        end

        -- ============ 5. INFO APP ============
        local infoSec = section("INFO", 5)
        local infoCard = card(infoSec, 1)
        label(infoCard, "PhoneIDViewer  v2.1.0", 11, C.text, Enum.Font.GothamBold, 0)
        label(infoCard, "© 2025 " .. (Config.DEVELOPER_USERNAME or "AlfreadR0rw"), 9, C.text3, Enum.Font.Gotham, 1)
        label(infoCard, "Build: Stable | Modular Architecture", 8, C.text3, Enum.Font.Gotham, 2)

    end) -- end pcall
end

print("[Settings] Loaded!")
