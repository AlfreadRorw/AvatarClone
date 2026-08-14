-- ================================================
-- FIREBASE.LUA - Full Rewrite
-- Support: syn.request, http_request, request, HttpService
-- Fix: key field compat (expires & expiresAt), chat reply, player reply
-- ================================================

local HttpService = game:GetService("HttpService")
local Firebase = {}

local DB_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app"
local API_KEY = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80"

-- ==================== HTTP CORE ====================
local function doRequest(method, url, body)
    local opts = {
        Url = url,
        Method = method,
        Headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
        },
    }
    if body ~= nil then
        opts.Body = HttpService:JSONEncode(body)
    end

    local ok, res = pcall(function()
        if syn and syn.request then
            return syn.request(opts)
        elseif http_request then
            return http_request(opts)
        elseif request then
            return request(opts)
        elseif HttpService.RequestAsync then
            return HttpService:RequestAsync(opts)
        end
        error("No HTTP method available")
    end)

    if not ok or not res then return nil end

    -- Normalise keduanya: executor (StatusCode) dan HttpService (.Success)
    local success = res.Success or (res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300)
    if not success then return nil end

    local rawBody = res.Body or res.body or ""
    if rawBody == "" or rawBody == "null" then return "_ok_" end -- DELETE etc
    local jok, data = pcall(function() return HttpService:JSONDecode(rawBody) end)
    return jok and data or nil
end

local function url(path)
    return DB_URL .. "/" .. path .. ".json?auth=" .. API_KEY
        .. "&nc=" .. tostring(os.time()) -- cache bust
end

function Firebase.GetData(path)
    local res = doRequest("GET", url(path), nil)
    if res == "_ok_" then return nil end
    return res
end

function Firebase.SetData(path, data)
    return doRequest("PUT", url(path), data) ~= nil
end

function Firebase.PatchData(path, data)
    return doRequest("PATCH", url(path), data) ~= nil
end

function Firebase.PushData(path, data)
    return doRequest("POST", url(path), data) ~= nil
end

function Firebase.DeleteData(path)
    return doRequest("DELETE", url(path), nil) ~= nil
end

-- ==================== HELPERS ====================
local DURATION_SECS = {["3d"] = 259200, ["7d"] = 604800, ["30d"] = 2592000}

-- Support both 'expires' (website lama) and 'expiresAt' (sistem baru)
local function getExpiry(data)
    if not data then return 0 end
    return tonumber(data.expiresAt or data.expires or 0)
end

local function fmtRemaining(secs)
    if not secs or secs <= 0 then return "Expired" end
    local d = math.floor(secs / 86400)
    local h = math.floor((secs % 86400) / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    if d > 0 then return ("%dh %djam %dmenit"):format(d, h, m) end
    if h > 0 then return ("%djam %dmenit"):format(h, m) end
    if m > 0 then return ("%dmenit %ddetik"):format(m, s) end
    return ("%ddetik"):format(s)
end

Firebase.fmtRemaining = fmtRemaining

-- ==================== KEY SYSTEM ====================

-- ValidateKey: return isValid(bool), message(string)
function Firebase.ValidateKey(key, userId, playerDisplayName, playerUsername)
    if not key or key == "" then return false, "Key tidak boleh kosong." end
    key = key:upper():gsub("%s+", "")

    local data = Firebase.GetData("keys/" .. key)
    if not data or type(data) ~= "table" then
        return false, "Key tidak ditemukan."
    end

    local now   = os.time()
    local exp   = getExpiry(data)
    -- Normalise usedBy dari berbagai format (false/nil/""/tostring)
    local rawBy = data.usedBy or data.boundUserId
    local usedBy = (rawBy and tostring(rawBy) ~= "false" and tostring(rawBy) ~= "nil" and tostring(rawBy) ~= "") and tostring(rawBy) or ""
    local isUsed = data.used == true or usedBy ~= ""

    -- Dipakai orang lain
    if isUsed and usedBy ~= "" and usedBy ~= tostring(userId) then
        return false, "Key sudah digunakan player lain."
    end

    -- Expired
    if exp > 0 and now > exp then
        return false, "Key sudah expired. Beli key baru."
    end

    -- Belum dipakai → bind sekarang
    if not isUsed then
        local durSecs = DURATION_SECS[data.duration or "7d"] or 604800
        exp = now + durSecs
        Firebase.SetData("keys/" .. key, {
            duration      = data.duration or "7d",
            durationLabel = data.durationLabel or "7 Hari",
            createdAt     = data.createdAt or now,
            created       = data.created or now,
            used          = true,
            usedBy        = tostring(userId),
            boundUserId   = tostring(userId),
            playerName    = playerDisplayName or "Unknown",
            playerUsername= playerUsername or "Unknown",
            activatedAt   = now,
            expiresAt     = exp,
            expires       = exp,
        })
        Firebase.SetData("user_keys/" .. tostring(userId), {
            key           = key,
            expiresAt     = exp,
            expires       = exp,
            durationLabel = data.durationLabel or "7 Hari",
            activatedAt   = now,
        })
        return true, "Key aktif! " .. fmtRemaining(exp - now)
    end

    -- Key milik user ini, masih valid
    return true, "Selamat datang! " .. fmtRemaining(exp - now)
end

-- CheckSavedKey: cukup userId, ambil key dari /user_keys/<uid>
-- Return: bool
function Firebase.CheckSavedKey(userId, savedKeyHint)
    local uid = tostring(userId)
    local keyCode = savedKeyHint

    if not keyCode or keyCode == "" then
        local saved = Firebase.GetData("user_keys/" .. uid)
        if saved and type(saved) == "table" then
            keyCode = saved.key or ""
            -- Quick check dari index
            local quickExp = getExpiry(saved)
            if quickExp > 0 and os.time() <= quickExp then
                return true
            end
        end
    end

    if not keyCode or keyCode == "" then return false end

    local data = Firebase.GetData("keys/" .. keyCode)
    if not data or type(data) ~= "table" then return false end
    local rawBy = tostring(data.usedBy or data.boundUserId or "")
    if rawBy ~= uid then return false end
    return getExpiry(data) > os.time()
end

-- GetKeyTimeRemaining: return sisa detik atau nil
function Firebase.GetKeyTimeRemaining(userId, savedKeyHint)
    local uid = tostring(userId)
    local keyCode = savedKeyHint

    if not keyCode or keyCode == "" then
        local saved = Firebase.GetData("user_keys/" .. uid)
        if saved and type(saved) == "table" then
            keyCode = saved.key or ""
            -- Quick check
            local quickExp = getExpiry(saved)
            if quickExp > 0 then
                local rem = quickExp - os.time()
                if rem > 0 then return rem end
            end
        end
    end

    if not keyCode or keyCode == "" then return nil end

    local data = Firebase.GetData("keys/" .. keyCode)
    if not data or type(data) ~= "table" then return nil end
    local rawBy = tostring(data.usedBy or data.boundUserId or "")
    if rawBy ~= uid then return nil end
    local rem = getExpiry(data) - os.time()
    return rem > 0 and rem or nil
end

-- GetKeyInfo: return raw key data
function Firebase.GetKeyInfo(savedKey)
    if not savedKey or savedKey == "" then return nil end
    return Firebase.GetData("keys/" .. savedKey)
end

-- GetFullKeyInfo: return tabel lengkap untuk Settings
function Firebase.GetFullKeyInfo(userId)
    local uid = tostring(userId)
    local saved = Firebase.GetData("user_keys/" .. uid)
    local keyCode = saved and (saved.key or "") or ""

    if keyCode == "" then
        return {ok=false, message="Tidak ada key tersimpan.", remaining=0}
    end

    local data = Firebase.GetData("keys/" .. keyCode)
    if not data or type(data) ~= "table" then
        return {ok=false, message="Key tidak ditemukan.", remaining=0}
    end

    local now = os.time()
    local exp = getExpiry(data)
    local rem = exp > 0 and (exp - now) or 0

    if rem <= 0 then
        return {ok=false, message="Key expired.", remaining=0, key=keyCode}
    end

    local totalSecs = DURATION_SECS[data.duration or "7d"] or 604800
    return {
        ok           = true,
        key          = keyCode,
        remaining    = rem,
        expiresAt    = exp,
        durationLabel= data.durationLabel or "-",
        duration     = data.duration or "7d",
        totalSecs    = totalSecs,
        ratio        = math.clamp(rem / totalSecs, 0, 1),
        playerName   = data.playerName or data.playerUsername or "Unknown",
        playerUsername = data.playerUsername or "Unknown",
        usedBy       = tostring(data.usedBy or data.boundUserId or "-"),
        message      = fmtRemaining(rem),
    }
end

-- ==================== ONLINE SYSTEM ====================
function Firebase.SetOnline(userId, playerData)
    return Firebase.SetData("online/" .. tostring(userId), playerData)
end

function Firebase.RemoveOnline(userId)
    return Firebase.DeleteData("online/" .. tostring(userId))
end

function Firebase.GetOnlinePlayers()
    return Firebase.GetData("online")
end

-- ==================== CHAT SYSTEM ====================
-- Kirim pesan dari PLAYER ke chat (muncul di website)
function Firebase.SendChat(fromUserId, fromName, fromUsername, message, replyToId, replyToName)
    if not message or message == "" then return false end
    local chatData = {
        from         = "player",
        fromName     = fromName or "Player",
        fromUsername = fromUsername or "unknown",
        fromUserId   = tostring(fromUserId or 0),
        senderName   = fromName or "Player",     -- compat website lama
        message      = message,
        target       = "admin",
        targetName   = "Admin",
        timestamp    = os.time(),
        replyTo      = replyToId or nil,
        replyToName  = replyToName or nil,
    }
    return Firebase.PushData("chat", chatData)
end

-- Ambil semua chat
function Firebase.GetChats()
    return Firebase.GetData("chat")
end

-- ==================== NOTIFICATION SYSTEM ====================
-- Cek notif masuk untuk userId ini
function Firebase.GetNotifications(userId)
    return Firebase.GetData("notifications/" .. tostring(userId))
end

-- Hapus notif setelah dibaca
function Firebase.DeleteNotification(userId, notifId)
    return Firebase.DeleteData("notifications/" .. tostring(userId) .. "/" .. notifId)
end

-- Hapus semua notif user
function Firebase.ClearNotifications(userId)
    return Firebase.DeleteData("notifications/" .. tostring(userId))
end

return Firebase
