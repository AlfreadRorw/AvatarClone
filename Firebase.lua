-- ================================================
-- FIREBASE - Complete with Map Names, Chat, Notification
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

-- ==================== HELPER FUNCTIONS ====================
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

-- ==================== BASE DATA FUNCTIONS ====================
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

function Firebase.PushData(path, data)
    local result = safeRequest(getUrl(path), "POST", data)
    return result ~= nil
end

function Firebase.DeleteData(path)
    local result = safeRequest(getUrl(path), "DELETE")
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
    
    if data.usedBy and tostring(data.usedBy) ~= tostring(userId) then
        return false, "Key sudah digunakan player lain"
    end
    
    if not data.usedBy then
        data.usedBy = tostring(userId)
        data.usedAt = os.time()
        data.playerName = playerName or "Unknown"
        data.playerUsername = playerUsername or "Unknown"
        data.mapName = mapName or "Unknown"
        data.jobId = jobId or "Unknown"
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
    
    if tostring(data.usedBy) ~= tostring(userId) then
        return false
    end
    
    return tonumber(data.expires) > os.time()
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
    
    return expires - os.time()
end

function Firebase.GetKeyInfo(savedKey)
    if not savedKey or savedKey == "" then
        return nil
    end
    return Firebase.GetData(KEYS_PATH .. "/" .. savedKey)
end

function Firebase.GetAllKeys()
    return Firebase.GetData(KEYS_PATH)
end

function Firebase.DeleteKey(key)
    return Firebase.DeleteData(KEYS_PATH .. "/" .. key)
end

-- ==================== NOTIFICATION SYSTEM ====================
function Firebase.SendNotification(targetUserId, title, message, fromName)
    local notifData = {
        title = title,
        message = message,
        from = fromName or "Admin",
        timestamp = os.time(),
        read = false,
    }
    
    if targetUserId == "all" then
        local onlinePlayers = Firebase.GetData(ONLINE_PATH)
        if onlinePlayers then
            for userId, _ in pairs(onlinePlayers) do
                Firebase.PushData(NOTIF_PATH .. "/" .. userId, notifData)
            end
            return true
        end
        return false
    else
        return Firebase.PushData(NOTIF_PATH .. "/" .. targetUserId, notifData)
    end
end

function Firebase.GetNotifications(userId)
    return Firebase.GetData(NOTIF_PATH .. "/" .. userId)
end

function Firebase.DeleteNotification(userId, notifId)
    return Firebase.DeleteData(NOTIF_PATH .. "/" .. userId .. "/" .. notifId)
end

function Firebase.MarkNotificationRead(userId, notifId)
    return Firebase.SetData(NOTIF_PATH .. "/" .. userId .. "/" .. notifId .. "/read", true)
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
function Firebase.SendChat(fromUserId, fromName, message, target, targetName, mapName)
    local chatData = {
        from = fromUserId and "player" or "admin",
        fromName = fromName or "Unknown",
        fromUserId = fromUserId or nil,
        message = message,
        target = target or "all",
        targetName = targetName or "All Players",
        mapName = mapName or "Unknown",
        timestamp = os.time(),
        replyTo = nil,
        replyToName = nil,
    }
    
    local chatId = os.time() .. "_" .. math.random(1000, 9999)
    return Firebase.SetData(CHAT_PATH .. "/" .. chatId, chatData)
end

function Firebase.SendChatWithReply(fromUserId, fromName, message, target, targetName, mapName, replyToId, replyToName)
    local chatData = {
        from = fromUserId and "player" or "admin",
        fromName = fromName or "Unknown",
        fromUserId = fromUserId or nil,
        message = message,
        target = target or "all",
        targetName = targetName or "All Players",
        mapName = mapName or "Unknown",
        timestamp = os.time(),
        replyTo = replyToId or nil,
        replyToName = replyToName or nil,
    }
    
    local chatId = os.time() .. "_" .. math.random(1000, 9999)
    return Firebase.SetData(CHAT_PATH .. "/" .. chatId, chatData)
end

function Firebase.GetChats()
    return Firebase.GetData(CHAT_PATH)
end

function Firebase.DeleteChat(chatId)
    return Firebase.DeleteData(CHAT_PATH .. "/" .. chatId)
end

return Firebase