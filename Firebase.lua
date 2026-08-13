-- ================================================
-- FIREBASE - Secure & Safe
-- ================================================

local HttpService = game:GetService("HttpService")
local Config = _G.Config

local Firebase = {}

local config = {
    apiKey = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80",
    authDomain = "phone-id-viewer.firebaseapp.com",
    databaseURL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId = "phone-id-viewer",
}

local KEYS_PATH = "keys"
local ONLINE_PATH = "online"
local CHAT_PATH = "chat"
local NOTIF_PATH = "notifications"

local DEBUG = Config and Config.DEBUG or false

local function log(...)
    if DEBUG then
        print("[Firebase]", ...)
    end
end

-- Safe URL builder with encoding
local function encodePath(part)
    return string.gsub(part, "([^%w%-_%.])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function getUrl(path)
    local baseUrl = config.databaseURL
    if not baseUrl:match("/$") then
        baseUrl = baseUrl .. "/"
    end
    return baseUrl .. path .. ".json?t=" .. tostring(os.time())
end

-- Safe request with detailed error
local function safeRequest(url, method, body)
    local ok, result = pcall(function()
        local options = {
            Url = url,
            Method = method,
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            }
        }
        if body then
            options.Body = HttpService:JSONEncode(body)
        end
        return HttpService:RequestAsync(options)
    end)
    
    if not ok then
        log("Request error:", tostring(result))
        return nil, "network_error"
    end
    
    if not result then
        return nil, "no_response"
    end
    
    if not result.Success then
        log("HTTP error:", result.StatusCode, result.StatusMessage)
        return nil, "http_" .. tostring(result.StatusCode)
    end
    
    return result, nil
end

function Firebase.GetData(path)
    local encodedPath = path:gsub("/", "/")
    local result, err = safeRequest(getUrl(encodedPath), "GET")
    if not result then
        return nil
    end
    
    local ok, data = pcall(function()
        return HttpService:JSONDecode(result.Body)
    end)
    
    if not ok then
        log("JSON decode error:", data)
        return nil
    end
    
    return data
end

function Firebase.SetData(path, data)
    local result, err = safeRequest(getUrl(path), "PUT", data)
    return result ~= nil
end

function Firebase.DeleteData(path)
    local result, err = safeRequest(getUrl(path), "DELETE")
    return result ~= nil
end

-- ==================== KEY SYSTEM ====================
function Firebase.ValidateKey(key, userId, playerName, playerUsername, mapName, jobId)
    if not key or key == "" then
        return false, "Key kosong"
    end
    
    key = key:upper():gsub("%s", "")
    local data = Firebase.GetData(KEYS_PATH .. "/" .. key)
    
    if not data or type(data) ~= "table" then
        return false, "Key tidak ditemukan"
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return false, "Key tidak valid"
    end
    
    if expires <= os.time() then
        Firebase.DeleteData(KEYS_PATH .. "/" .. key)
        return false, "Key sudah kedaluwarsa"
    end
    
    -- Race condition protection: double-check claim
    if data.usedBy and tostring(data.usedBy) ~= tostring(userId) then
        return false, "Key sudah digunakan player lain"
    end
    
    if not data.usedBy then
        -- Attempt claim
        data.usedBy = tostring(userId)
        data.usedAt = os.time()
        data.playerName = playerName or "Unknown"
        data.playerUsername = playerUsername or "Unknown"
        data.mapName = mapName or "Unknown"
        data.jobId = jobId or "Unknown"
        
        if not Firebase.SetData(KEYS_PATH .. "/" .. key, data) then
            return false, "Gagal claim key"
        end
        
        -- Verify claim
        local verifyData = Firebase.GetData(KEYS_PATH .. "/" .. key)
        if verifyData and verifyData.usedBy and tostring(verifyData.usedBy) ~= tostring(userId) then
            return false, "Claim gagal, key sudah diambil player lain"
        end
    end
    
    local remaining = expires - os.time()
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    
    return true, string.format("Berlaku %d jam %d menit", hours, minutes)
end

function Firebase.CheckSavedKey(userId, savedKey)
    if not savedKey or savedKey == "" then
        return false
    end
    
    local data = Firebase.GetData(KEYS_PATH .. "/" .. savedKey)
    if not data or type(data) ~= "table" then
        return false
    end
    
    if tostring(data.usedBy) ~= tostring(userId) then
        return false
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return false
    end
    
    return expires > os.time()
end

function Firebase.GetKeyTimeRemaining(userId, savedKey)
    if not savedKey or savedKey == "" then
        return nil
    end
    
    local data = Firebase.GetData(KEYS_PATH .. "/" .. savedKey)
    if not data or type(data) ~= "table" then
        return nil
    end
    
    if tostring(data.usedBy) ~= tostring(userId) then
        return nil
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return nil
    end
    
    return math.max(0, expires - os.time())
end

-- ==================== NOTIFICATION SYSTEM ====================
local notificationCounter = 0

function Firebase.SendNotification(targetUserId, title, message, fromName, fromUserId)
    notificationCounter = notificationCounter + 1
    local uniqueId = string.format("%d_%d_%d", os.time(), notificationCounter, math.random(1000, 9999))
    
    local notifData = {
        title = title,
        message = message,
        from = fromName or "Admin",
        fromUserId = fromUserId or "admin",
        timestamp = os.time(),
        read = false,
    }
    
    if targetUserId == "all" then
        local onlinePlayers = Firebase.GetData(ONLINE_PATH)
        if onlinePlayers then
            for userId, _ in pairs(onlinePlayers) do
                Firebase.SetData(NOTIF_PATH .. "/" .. userId .. "/" .. uniqueId, notifData)
            end
            return true
        end
        return false
    else
        return Firebase.SetData(NOTIF_PATH .. "/" .. targetUserId .. "/" .. uniqueId, notifData)
    end
end

function Firebase.GetNotifications(userId)
    return Firebase.GetData(NOTIF_PATH .. "/" .. userId)
end

function Firebase.DeleteNotification(userId, notifId)
    return Firebase.DeleteData(NOTIF_PATH .. "/" .. userId .. "/" .. notifId)
end

-- ==================== ONLINE SYSTEM ====================
function Firebase.SetOnline(userId, playerData)
    playerData.lastUpdate = os.time()
    return Firebase.SetData(ONLINE_PATH .. "/" .. userId, playerData)
end

function Firebase.RemoveOnline(userId)
    return Firebase.DeleteData(ONLINE_PATH .. "/" .. userId)
end

function Firebase.GetOnlinePlayers()
    local data = Firebase.GetData(ONLINE_PATH)
    if not data then
        return nil
    end
    
    -- Filter stale players (older than 180 seconds)
    local now = os.time()
    local active = {}
    for userId, playerData in pairs(data) do
        local lastUpdate = tonumber(playerData.lastUpdate)
        if lastUpdate and (now - lastUpdate) < 180 then
            active[userId] = playerData
        end
    end
    
    return active
end

return Firebase