-- ================================================
-- FIREBASE - Complete Real-time System
-- ================================================

local HttpService = game:GetService("HttpService")

local Firebase = {}

local config = {
    apiKey = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80",
    authDomain = "phone-id-viewer.firebaseapp.com",
    databaseURL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId = "phone-id-viewer",
    storageBucket = "phone-id-viewer.firebasestorage.app",
    messagingSenderId = "500715221525",
    appId = "1:500715221525:web:b4ed0d1e13ebc12c55941c"
}

local KEYS_PATH = "keys"
local ONLINE_PATH = "online"
local CHAT_PATH = "chat"
local NOTIF_PATH = "notifications"

local function getUrl(path)
    local baseUrl = config.databaseURL
    if not baseUrl:match("/$") then
        baseUrl = baseUrl .. "/"
    end
    return baseUrl .. path .. ".json?t=" .. tostring(os.time())
end

local function safeRequest(url, method, body)
    local success, result = pcall(function()
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
    
    if not success or not result or not result.Success then
        return nil
    end
    return result
end

-- ==================== CORE FUNCTIONS ====================
function Firebase.GetData(path)
    local result = safeRequest(getUrl(path), "GET")
    if not result then return nil end
    
    local ok, data = pcall(function()
        return HttpService:JSONDecode(result.Body)
    end)
    return ok and data or nil
end

function Firebase.SetData(path, data)
    local result = safeRequest(getUrl(path), "PUT", data)
    return result ~= nil
end

function Firebase.DeleteData(path)
    local result = safeRequest(getUrl(path), "DELETE")
    return result ~= nil
end

function Firebase.UpdateData(path, data)
    local result = safeRequest(getUrl(path), "PATCH", data)
    return result ~= nil
end

-- ==================== KEY SYSTEM ====================
function Firebase.ValidateKey(key, userId, playerName, playerUsername)
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
    
    if data.usedBy and data.usedBy ~= tostring(userId) then
        return false, "Key sudah digunakan player lain"
    end
    
    if not data.usedBy then
        data.usedBy = tostring(userId)
        data.usedAt = os.time()
        data.playerName = playerName or "Unknown"
        data.playerUsername = playerUsername or "Unknown"
        Firebase.SetData(KEYS_PATH .. "/" .. key, data)
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
    
    if data.usedBy ~= tostring(userId) then
        return false
    end
    
    return tonumber(data.expires) > os.time()
end

-- ==================== ONLINE SYSTEM ====================
function Firebase.SetOnline(userId, playerData)
    return Firebase.SetData(ONLINE_PATH .. "/" .. userId, playerData)
end

function Firebase.RemoveOnline(userId)
    return Firebase.DeleteData(ONLINE_PATH .. "/" .. userId)
end

function Firebase.GetOnlinePlayers()
    return Firebase.GetData(ONLINE_PATH)
end

-- ==================== CHAT SYSTEM ====================
function Firebase.SendChat(fromUserId, fromName, message, mapName)
    local chatData = {
        from = fromUserId,
        fromName = fromName,
        message = message,
        mapName = mapName,
        timestamp = os.time(),
    }
    return Firebase.SetData(CHAT_PATH .. "/" .. os.time() .. "_" .. fromUserId, chatData)
end

function Firebase.GetChats()
    return Firebase.GetData(CHAT_PATH)
end

-- ==================== NOTIFICATION SYSTEM ====================
function Firebase.SendNotification(targetUserId, title, message, fromName)
    local notifData = {
        title = title,
        message = message,
        from = fromName,
        timestamp = os.time(),
        read = false,
    }
    return Firebase.SetData(NOTIF_PATH .. "/" .. targetUserId .. "/" .. os.time(), notifData)
end

function Firebase.GetNotifications(userId)
    return Firebase.GetData(NOTIF_PATH .. "/" .. userId)
end

function Firebase.MarkNotificationRead(userId, notifId)
    return Firebase.UpdateData(NOTIF_PATH .. "/" .. userId .. "/" .. notifId, {read = true})
end

return Firebase