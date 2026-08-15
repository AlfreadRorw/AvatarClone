-- ================================================
-- PREMIUM.LUA — Dev/Permanent Control Panel
-- HANYA bisa dibuka kalau key user berstatus "permanent" ATAU dia developer.
--
-- Fitur:
--   1. Daftar SEMUA player yang online (lintas server/map, dari Firebase presence)
--   2. "TP ke Aku"      -> target dipindah ke lokasi dev. 
--   3. "TP-on-Tap"      -> dev toggle mode ON, lalu TAP di layar dev sendiri
--   4. Refresh daftar online, badge "same server" vs "different server".
-- ================================================

local Services         = _G.Services
local LocalPlayer      = _G.LocalPlayer
local Players          = Services.Players
local UserInputService = Services.UserInputService
local Workspace        = Services.Workspace
local TeleportService  = Services.TeleportService
local T                = _G.T or {}
local Helpers          = _G.Helpers or {}
local Firebase         = _G.Firebase
local Config           = _G.Config or {}

local corner  = Helpers.corner
local stroke  = Helpers.stroke
local pressFX = Helpers.pressFX

local C = {
    bg      = Color3.fromRGB(10, 8, 16),
    card    = Color3.fromRGB(20, 16, 30),
    card2   = Color3.fromRGB(28, 22, 42),
    border  = Color3.fromRGB(58, 44, 84),
    text    = Color3.fromRGB(240, 235, 250),
    text2   = Color3.fromRGB(165, 150, 190),
    text3   = Color3.fromRGB(105, 92, 130),
    gold    = Color3.fromRGB(255, 195, 60),
    purple  = Color3.fromRGB(168, 100, 255),
    green   = Color3.fromRGB(80, 230, 150),
    red     = Color3.fromRGB(255, 90, 100),
    blue    = Color3.fromRGB(100, 170, 255),
}

-- ==================== GATE AKSES ====================
local function checkPremiumAccess()
    local isDev = false
    local devCheckOk = pcall(function()
        if Config.DEVELOPER_USERNAME and Config.DEVELOPER_USERNAME ~= "" 
           and LocalPlayer.Name == Config.DEVELOPER_USERNAME then
            isDev = true
        end
        if Config.DEVELOPER_USER_ID and tostring(Config.DEVELOPER_USER_ID) ~= "" 
           and tostring(LocalPlayer.UserId) == tostring(Config.DEVELOPER_USER_ID) then
            isDev = true
        end
    end)

    if isDev then return true, true, "developer" end

    if not Firebase then return false, false, "firebase_missing" end
    if not Firebase.IsPermanentUser then return false, false, "function_missing" end

    local ok, isPerm = pcall(function()
        return Firebase.IsPermanentUser(LocalPlayer.UserId)
    end)

    if not ok then return false, false, "check_failed" end
    if isPerm == true then return true, false, "permanent_key" end

    return false, false, "not_permanent"
end

_G.hasPremiumAccess = function()
    local ok = checkPremiumAccess()
    return ok
end

-- ==================== UI HELPERS ====================
local function section(title, order)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1,0,0,0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.BackgroundTransparency = 1
    sec.LayoutOrder = order
    sec.Parent = _G.appContent -- DYNAMIC REFERENCE FIX

    local lay = Instance.new("UIListLayout", sec)
    lay.Padding = UDim.new(0,6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1,-8,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = C.gold
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = 0

    return sec
end

local function card(parent, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1,0,0,0)
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.BackgroundColor3 = C.card
    c.BorderSizePixel = 0
    c.LayoutOrder = order
    c.Parent = parent
    corner(c, 14)
    stroke(c, C.border, 1, 0.25)

    local lay = Instance.new("UIListLayout", c)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", c)
    pad.PaddingTop    = UDim.new(0,10)
    pad.PaddingBottom = UDim.new(0,10)
    pad.PaddingLeft   = UDim.new(0,12)
    pad.PaddingRight  = UDim.new(0,12)
    return c
end

-- ==================== ACCESS DENIED SCREEN ====================
local function renderAccessDenied(reason)
    if _G.showDynamicNotification then
        _G.showDynamicNotification("🔒 Aplikasi ini cuman untuk Dev dan User Permanen!", C.red)
    end

    local sec = section("AKSES DITOLAK", 1)
    local c = card(sec, 1)

    local icon = Instance.new("TextLabel", c)
    icon.Size = UDim2.new(1,0,0,50)
    icon.BackgroundTransparency = 1
    icon.Text = "🔒"
    icon.TextSize = 34
    icon.LayoutOrder = 0

    local title = Instance.new("TextLabel", c)
    title.Size = UDim2.new(1,0,0,24)
    title.BackgroundTransparency = 1
    title.Text = "Akses Terbatas"
    title.TextColor3 = C.text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 14
    title.LayoutOrder = 1

    local desc = Instance.new("TextLabel", c)
    desc.Size = UDim2.new(1,0,0,40)
    desc.BackgroundTransparency = 1
    desc.Text = "Aplikasi ini hanya dapat diakses oleh Developer dan User Permanen."
    desc.TextColor3 = C.text2
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 11
    desc.TextWrapped = true
    desc.LayoutOrder = 2

    local backBtn = Instance.new("TextButton", c)
    backBtn.Size = UDim2.new(1, 0, 0, 36)
    backBtn.BackgroundColor3 = C.red
    backBtn.BackgroundTransparency = 0.2
    backBtn.Text = "Kembali ke Home"
    backBtn.TextColor3 = C.text
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 11
    backBtn.AutoButtonColor = false
    backBtn.LayoutOrder = 3
    corner(backBtn, 8)
    pressFX(backBtn)

    backBtn.MouseButton1Click:Connect(function()
        if _G.openApp and _G.openHomeApp then
            _G.openApp("Home", _G.openHomeApp)
        else
            if _G.appContent then
                for _, child in ipairs(_G.appContent:GetChildren()) do
                    if not child:IsA("UIListLayout") then child:Destroy() end
                end
            end
            if _G.showDynamicNotification then
                _G.showDynamicNotification("Tutup dan buka kembali handphone-mu.", C.text3)
            end
        end
    end)
end

-- ==================== TP-ON-TAP RAYCAST ====================
local tpOnTapActive  = false
local tpOnTapTarget  = nil 
local tpTapConnection = nil

local function screenPointToGroundWorld(screenPos)
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    local unitRay = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local excludeList = {}
    if LocalPlayer.Character then table.insert(excludeList, LocalPlayer.Character) end
    raycastParams.FilterDescendantsInstances = excludeList
    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
    if result then return result.Position end
    return nil
end

local function sendTapTeleportToTarget(worldPos)
    if not tpOnTapTarget then return end
    local targetUid = tpOnTapTarget.userId

    if tpOnTapTarget.sameServer then
        local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUid))
        if targetPlayer and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.CFrame = CFrame.new(worldPos + Vector3.new(0, 3, 0)) end)
                _G.showDynamicNotification("📍 " .. tpOnTapTarget.name .. " di-TP ke titik tap!", C.purple)
                return
            end
        end
    end

    if Firebase and Firebase.PushCommand then
        pcall(function()
            Firebase.PushCommand(targetUid, {
                type = "teleport_to_point",
                x = worldPos.X, y = worldPos.Y + 3, z = worldPos.Z,
                fromPlaceId = tostring(game.PlaceId),
                fromJobId   = game.JobId,
                senderLabel = "DEV",
                timestamp = os.time(),
            })
        end)
        _G.showDynamicNotification("📡 Perintah TP dikirim ke " .. tpOnTapTarget.name, C.blue)
    end
end

local function enableTpOnTap(target)
    tpOnTapActive = true
    tpOnTapTarget = target
    tpTapConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end 
        if not tpOnTapActive then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position
            local worldPos = screenPointToGroundWorld(Vector2.new(pos.X, pos.Y))
            if worldPos then sendTapTeleportToTarget(worldPos) end
        end
    end)
    _G.showDynamicNotification("🎯 TP-on-Tap AKTIF untuk " .. target.name, C.gold)
end

local function disableTpOnTap()
    tpOnTapActive = false
    tpOnTapTarget = nil
    if tpTapConnection then
        tpTapConnection:Disconnect()
        tpTapConnection = nil
    end
    _G.showDynamicNotification("TP-on-Tap dimatikan", C.text3)
end

-- ==================== TP KE AKU (DEV) ====================
local function teleportTargetToMe(target)
    if target.sameServer then
        local targetPlayer = Players:GetPlayerByUserId(tonumber(target.userId))
        local myChar = LocalPlayer.Character
        if targetPlayer and targetPlayer.Character and myChar then
            local myHrp = myChar:FindFirstChild("HumanoidRootPart")
            local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp and targetHrp then
                pcall(function() targetHrp.CFrame = myHrp.CFrame * CFrame.new(3, 0, 0) end)
                _G.showDynamicNotification("📍 " .. target.name .. " ditarik ke posisimu!", C.purple)
                return
            end
        end
    end

    if Firebase and Firebase.PushCommand then
        pcall(function()
            Firebase.PushCommand(target.userId, {
                type = "teleport_to_dev",
                devUserId   = LocalPlayer.UserId,
                devPlaceId  = tostring(game.PlaceId),
                devJobId    = game.JobId,
                senderLabel = "DEV",
                timestamp = os.time(),
            })
        end)
        _G.showDynamicNotification("📡 Perintah TP dikirim ke " .. target.name, C.blue)
    end
end

-- ==================== RENDER PLAYER CARD ====================
local function renderPlayerCard(parent, playerData, order)
    local uid       = tostring(playerData.userId)
    local name      = playerData.displayName or playerData.name or "Unknown"
    local username  = playerData.name or "unknown"
    local placeId   = tostring(playerData.mapName or playerData.placeId or "")
    local sameServer = placeId == tostring(game.PlaceId)
    local isMe = uid == tostring(LocalPlayer.UserId)

    if isMe then return end

    local pcard = Instance.new("Frame", parent)
    pcard.Size = UDim2.new(1,0,0,0)
    pcard.AutomaticSize = Enum.AutomaticSize.Y
    pcard.BackgroundColor3 = C.card2
    pcard.LayoutOrder = order
    corner(pcard, 12)
    stroke(pcard, sameServer and C.green or C.border, 1, sameServer and 0.5 or 0.3)

    local pad = Instance.new("UIPadding", pcard)
    pad.PaddingTop = UDim.new(0,10); pad.PaddingBottom = UDim.new(0,10)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)

    local lay = Instance.new("UIListLayout", pcard)
    lay.Padding = UDim.new(0,8)

    local infoRow = Instance.new("Frame", pcard)
    infoRow.Size = UDim2.new(1,0,0,40)
    infoRow.BackgroundTransparency = 1
    infoRow.LayoutOrder = 0

    local avatarFrame = Instance.new("Frame", infoRow)
    avatarFrame.Size = UDim2.new(0,38,0,38)
    avatarFrame.BackgroundColor3 = C.card
    corner(avatarFrame, 100)
    stroke(avatarFrame, sameServer and C.green or C.text3, 1.5, 0.2)

    local avatarImg = Instance.new("ImageLabel", avatarFrame)
    avatarImg.Size = UDim2.new(1,-4,1,-4)
    avatarImg.Position = UDim2.new(0,2,0,2)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=100&height=100&format=png"
    corner(avatarImg, 100)

    local nameLbl = Instance.new("TextLabel", infoRow)
    nameLbl.Size = UDim2.new(1,-118,0,18)
    nameLbl.Position = UDim2.new(0,46,0,1)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = C.text
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local userLbl = Instance.new("TextLabel", infoRow)
    userLbl.Size = UDim2.new(1,-118,0,14)
    userLbl.Position = UDim2.new(0,46,0,19)
    userLbl.BackgroundTransparency = 1
    userLbl.Text = "@"..username
    userLbl.TextColor3 = C.text3
    userLbl.Font = Enum.Font.Gotham
    userLbl.TextSize = 9
    userLbl.TextXAlignment = Enum.TextXAlignment.Left

    local badge = Instance.new("Frame", infoRow)
    badge.Size = UDim2.new(0,72,0,18)
    badge.Position = UDim2.new(1,-72,0,10)
    badge.BackgroundColor3 = sameServer and C.green or C.blue
    badge.BackgroundTransparency = 0.82
    corner(badge, 7)

    local badgeLbl = Instance.new("TextLabel", badge)
    badgeLbl.Size = UDim2.new(1,0,1,0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text = sameServer and "SAME SERVER" or "DIFF SERVER"
    badgeLbl.TextColor3 = sameServer and C.green or C.blue
    badgeLbl.Font = Enum.Font.GothamBlack
    badgeLbl.TextSize = 7

    local actRow = Instance.new("Frame", pcard)
    actRow.Size = UDim2.new(1,0,0,32)
    actRow.BackgroundTransparency = 1
    actRow.LayoutOrder = 1

    local btnToMe = Instance.new("TextButton", actRow)
    btnToMe.Size = UDim2.new(0.5,-4,1,0)
    btnToMe.Position = UDim2.new(0,0,0,0)
    btnToMe.BackgroundColor3 = C.purple
    btnToMe.BackgroundTransparency = 0.8
    btnToMe.Text = "📍 TP ke Aku"
    btnToMe.TextColor3 = C.purple
    btnToMe.Font = Enum.Font.GothamBold
    btnToMe.TextSize = 10
    btnToMe.AutoButtonColor = false
    corner(btnToMe, 9)
    pressFX(btnToMe)
    btnToMe.MouseButton1Click:Connect(function()
        teleportTargetToMe({userId=uid, name=name, sameServer=sameServer})
    end)

    local btnTapMode = Instance.new("TextButton", actRow)
    btnTapMode.Size = UDim2.new(0.5,-4,1,0)
    btnTapMode.Position = UDim2.new(0.5,4,0,0)
    local isThisTapTarget = tpOnTapActive and tpOnTapTarget and tpOnTapTarget.userId == uid
    btnTapMode.BackgroundColor3 = isThisTapTarget and C.gold or C.card
    btnTapMode.BackgroundTransparency = isThisTapTarget and 0.75 or 0
    btnTapMode.Text = isThisTapTarget and "🎯 Tap AKTIF" or "🎯 TP-on-Tap"
    btnTapMode.TextColor3 = isThisTapTarget and C.gold or C.text2
    btnTapMode.Font = Enum.Font.GothamBold
    btnTapMode.TextSize = 10
    btnTapMode.AutoButtonColor = false
    corner(btnTapMode, 9)
    stroke(btnTapMode, isThisTapTarget and C.gold or C.border, 1, 0.4)
    pressFX(btnTapMode)
    btnTapMode.MouseButton1Click:Connect(function()
        if isThisTapTarget then
            disableTpOnTap()
        else
            enableTpOnTap({userId=uid, name=name, sameServer=sameServer})
        end
        _G.refreshCurrentApp and _G.refreshCurrentApp()
    end)
end

local _buildPremiumUI

-- ==================== BUKA APP ====================
function _G.openPremiumApp()
    local renderOk, renderErr = pcall(function()
        local hasAccess, isDev, reason = checkPremiumAccess()
        if not hasAccess then
            renderAccessDenied(reason)
            return
        end

        if _G.showDynamicNotification then
            if isDev then
                _G.showDynamicNotification("👑 Developer Access — Premium Terbuka", C.gold)
            else
                _G.showDynamicNotification("✨ Key Permanen Terverifikasi", C.purple)
            end
        end

        _buildPremiumUI(isDev)
    end)

    if not renderOk then
        warn("[Premium] Error saat render app: " .. tostring(renderErr))
        if _G.showDynamicNotification then
            _G.showDynamicNotification("⚠️ Premium gagal dimuat!", C.red)
        end
        -- Tampilkan pesan error di layar supaya tidak sekadar blank/putih
        if _G.appContent then
            local errLbl = Instance.new("TextLabel", _G.appContent)
            errLbl.Size = UDim2.new(1, 0, 1, 0)
            errLbl.BackgroundTransparency = 1
            errLbl.Text = "Error Load Premium:\n" .. tostring(renderErr)
            errLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
            errLbl.Font = Enum.Font.GothamBold
            errLbl.TextSize = 12
            errLbl.TextWrapped = true
        end
    end
end

-- ==================== BANGUN UI PREMIUM ====================
_buildPremiumUI = function(isDev)
    local header = Instance.new("Frame", _G.appContent) -- DYNAMIC REFERENCE FIX
    header.Size = UDim2.new(1,0,0,50)
    header.BackgroundColor3 = C.card
    header.LayoutOrder = 0
    corner(header, 12)
    stroke(header, C.gold, 1, 0.5)

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1,-20,0,22)
    hTitle.Position = UDim2.new(0,12,0,6)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "👑 Premium Control"
    hTitle.TextColor3 = C.gold
    hTitle.Font = Enum.Font.GothamBlack
    hTitle.TextSize = 13
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1,-20,0,14)
    hSub.Position = UDim2.new(0,12,0,28)
    hSub.BackgroundTransparency = 1
    hSub.Text = isDev and "Developer Access — Kontrol Penuh" or "Key Permanen Aktif"
    hSub.TextColor3 = C.text2
    hSub.Font = Enum.Font.Gotham
    hSub.TextSize = 9
    hSub.TextXAlignment = Enum.TextXAlignment.Left

    if tpOnTapActive and tpOnTapTarget then
        local statusSec = section("STATUS", 1)
        local statusCard = card(statusSec, 1)
        statusCard.BackgroundColor3 = Color3.fromRGB(40, 32, 10)
        stroke(statusCard, C.gold, 1, 0.3)

        local statusLbl = Instance.new("TextLabel", statusCard)
        statusLbl.Size = UDim2.new(1,0,0,18)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = "🎯 TP-on-Tap AKTIF"
        statusLbl.TextColor3 = C.gold
        statusLbl.Font = Enum.Font.GothamBlack
        statusLbl.TextSize = 11
        statusLbl.LayoutOrder = 0

        local statusSub = Instance.new("TextLabel", statusCard)
        statusSub.Size = UDim2.new(1,0,0,16)
        statusSub.BackgroundTransparency = 1
        statusSub.Text = "Target: " .. tpOnTapTarget.name .. " — tap dimana saja di layar"
        statusSub.TextColor3 = C.text2
        statusSub.Font = Enum.Font.Gotham
        statusSub.TextSize = 9
        statusSub.TextWrapped = true
        statusSub.LayoutOrder = 1

        local stopBtn = Instance.new("TextButton", statusCard)
        stopBtn.Size = UDim2.new(1,0,0,30)
        stopBtn.BackgroundColor3 = C.red
        stopBtn.BackgroundTransparency = 0.8
        stopBtn.Text = "Matikan TP-on-Tap"
        stopBtn.TextColor3 = C.red
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.TextSize = 10
        stopBtn.AutoButtonColor = false
        stopBtn.LayoutOrder = 2
        corner(stopBtn, 9)
        pressFX(stopBtn)
        stopBtn.MouseButton1Click:Connect(function()
            disableTpOnTap()
            _G.openApp and _G.openApp("Premium", _G.openPremiumApp)
        end)
    end

    local listSec = section("SEMUA PLAYER ONLINE", 2)

    local refreshBtn = Instance.new("TextButton", listSec)
    refreshBtn.Size = UDim2.new(1,0,0,32)
    refreshBtn.BackgroundColor3 = C.card2
    refreshBtn.Text = "🔄  Refresh Daftar"
    refreshBtn.TextColor3 = C.text2
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 10
    refreshBtn.AutoButtonColor = false
    refreshBtn.LayoutOrder = 1
    corner(refreshBtn, 9)
    stroke(refreshBtn, C.border, 1, 0.3)
    pressFX(refreshBtn)

    local listContainer = Instance.new("Frame", listSec)
    listContainer.Size = UDim2.new(1,0,0,0)
    listContainer.AutomaticSize = Enum.AutomaticSize.Y
    listContainer.BackgroundTransparency = 1
    listContainer.LayoutOrder = 2

    local listLayout = Instance.new("UIListLayout", listContainer)
    listLayout.Padding = UDim.new(0,8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function loadPlayerList()
        for _, c in ipairs(listContainer:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end

        if not Firebase or not Firebase.GetOnlinePlayers then
            local e = Instance.new("TextLabel", listContainer)
            e.Size = UDim2.new(1,0,0,30)
            e.BackgroundTransparency = 1
            e.Text = "Firebase tidak tersedia"
            e.TextColor3 = C.text3
            e.Font = Enum.Font.Gotham
            e.TextSize = 10
            return
        end

        local ok, onlineData = pcall(function() return Firebase.GetOnlinePlayers() end)
        if not ok or not onlineData or type(onlineData) ~= "table" then
            local e = Instance.new("TextLabel", listContainer)
            e.Size = UDim2.new(1,0,0,30)
            e.BackgroundTransparency = 1
            e.Text = "Tidak ada player online"
            e.TextColor3 = C.text3
            e.Font = Enum.Font.Gotham
            e.TextSize = 10
            return
        end

        local list = {}
        for _, p in pairs(onlineData) do
            if type(p) == "table" then table.insert(list, p) end
        end
        table.sort(list, function(a,b)
            local aSame = tostring(a.mapName) == tostring(game.PlaceId)
            local bSame = tostring(b.mapName) == tostring(game.PlaceId)
            if aSame ~= bSame then return aSame end
            return tostring(a.displayName or a.name) < tostring(b.displayName or b.name)
        end)

        local order = 0
        for _, p in ipairs(list) do
            order = order + 1
            renderPlayerCard(listContainer, p, order)
        end
    end

    refreshBtn.MouseButton1Click:Connect(loadPlayerList)
    task.spawn(loadPlayerList)
end

print("[Premium] Loaded! Gate: key permanent atau developer.")
