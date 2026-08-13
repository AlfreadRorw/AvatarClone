-- Firebase.lua
-- Firebase Realtime Database untuk Online Tracker & Messages

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local HttpService = Services.HttpService

-- ================= FIREBASE CONFIG =================
local FIREBASE_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app"

-- ================= FIREBASE FUNCTIONS =================
local Firebase = {}

-- Request helper
local function firebaseRequest(method, path, body)
    local url = FIREBASE_URL .. path .. ".json"
    local ok, result = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = url,
                Method = method,
                Headers = {["Content-Type"] = "application/json"},
                Body = body and HttpService:JSONEncode(body) or nil
            })
        elseif http_request then
            return http_request({
                Url = url,
                Method = method,
                Headers = {["Content-Type"] = "application/json"},
                Body = body and HttpService:JSONEncode(body) or nil
            })
        else
            return {Body = game:HttpGet(url)}
        end
    end)
    
    if ok and result and result.Body and result.Body ~= "" and result.Body ~= "null" then
        local dok, data = pcall(function() return HttpService:JSONDecode(result.Body) end)
        if dok then return data end
    end
    
    -- Fallback ke file lokal
    local localFile = "PhoneIDViewer_Firebase.json"
    local localData = {}
    pcall(function()
        if isfile and isfile(localFile) then
            localData = HttpService:JSONDecode(readfile(localFile))
        end
    end)
    return localData
end

function Firebase.set(path, data)
    firebaseRequest("PUT", path, data)
    
    -- Simpan juga ke lokal (fallback)
    pcall(function()
        local localFile = "PhoneIDViewer_Firebase.json"
        local allData = {}
        if isfile and isfile(localFile) then
            allData = HttpService:JSONDecode(readfile(localFile))
        end
        
        -- Parse path
        local keys = {}
        for key in path:gmatch("[^/]+") do
            table.insert(keys, key)
        end
        
        local current = allData
        for i = 1, #keys - 1 do
            if not current[keys[i]] then current[keys[i]] = {} end
            current = current[keys[i]]
        end
        current[keys[#keys]] = data
        
        if writefile then
            writefile(localFile, HttpService:JSONEncode(allData))
        end
    end)
end

function Firebase.get(path)
    return firebaseRequest("GET", path, nil)
end

function Firebase.delete(path)
    firebaseRequest("DELETE", path, nil)
    
    -- Hapus juga dari lokal
    pcall(function()
        local localFile = "PhoneIDViewer_Firebase.json"
        local allData = {}
        if isfile and isfile(localFile) then
            allData = HttpService:JSONDecode(readfile(localFile))
        end
        
        local keys = {}
        for key in path:gmatch("[^/]+") do
            table.insert(keys, key)
        end
        
        if #keys == 1 then
            allData[keys[1]] = nil
        else
            local current = allData
            for i = 1, #keys - 1 do
                if not current[keys[i]] then return end
                current = current[keys[i]]
            end
            current[keys[#keys]] = nil
        end
        
        if writefile then
            writefile(localFile, HttpService:JSONEncode(allData))
        end
    end)
end

-- ================= ONLINE TRACKER =================
local myFirebaseKey = "user_" .. tostring(LocalPlayer.UserId)

function Firebase.goOnline()
    local placeName = "Unknown"
    pcall(function()
        placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    
    Firebase.set("/online_players/" .. myFirebaseKey, {
        username = LocalPlayer.Name,
        displayName = LocalPlayer.DisplayName,
        userId = LocalPlayer.UserId,
        jobId = game.JobId,
        placeId = game.PlaceId,
        placeName = placeName,
        timestamp = os.time(),
        online = true,
        isDev = (LocalPlayer.Name:lower() == "alfreadr0rw")
    })
end

function Firebase.goOffline()
    Firebase.delete("/online_players/" .. myFirebaseKey)
end

function Firebase.keepAlive()
    while true do
        task.wait(30)
        pcall(Firebase.goOnline)
    end
end

function Firebase.getOnlinePlayers()
    local data = Firebase.get("/online_players")
    local onlineList = {}
    
    if data and type(data) == "table" then
        local now = os.time()
        for key, player in pairs(data) do
            if type(player) == "table" and player.timestamp and (now - player.timestamp) < 120 then
                player.firebaseKey = key
                table.insert(onlineList, player)
            end
        end
    end
    
    return onlineList
end

-- ================= PULL REQUEST =================
function Firebase.sendPullRequest(targetUserId)
    Firebase.set("/pull_requests/user_" .. tostring(targetUserId), {
        jobId = game.JobId,
        placeId = game.PlaceId,
        devName = LocalPlayer.DisplayName,
        devUsername = LocalPlayer.Name,
        devUserId = LocalPlayer.UserId,
        message = "mengundang kamu ke servernya",
        timestamp = os.time()
    })
end

function Firebase.sendPullResponse(devUserId, accepted, responderName)
    Firebase.set("/pull_responses/user_" .. tostring(devUserId), {
        accepted = accepted,
        responderName = responderName,
        timestamp = os.time()
    })
end

function Firebase.getPullRequest()
    return Firebase.get("/pull_requests/user_" .. tostring(LocalPlayer.UserId))
end

function Firebase.deletePullRequest()
    Firebase.delete("/pull_requests/user_" .. tostring(LocalPlayer.UserId))
end

function Firebase.getPullResponse()
    return Firebase.get("/pull_responses/user_" .. tostring(LocalPlayer.UserId))
end

function Firebase.deletePullResponse()
    Firebase.delete("/pull_responses/user_" .. tostring(LocalPlayer.UserId))
end

-- ================= MESSAGES =================
function Firebase.getChatId(userIdA, userIdB)
    local a, b = tostring(userIdA), tostring(userIdB)
    if tonumber(a) > tonumber(b) then a, b = b, a end
    return a .. "_" .. b
end

function Firebase.sendMessage(toUserId, text)
    local chatId = Firebase.getChatId(LocalPlayer.UserId, toUserId)
    local msgId = "msg_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    
    Firebase.set("/chats/" .. chatId .. "/messages/" .. msgId, {
        id = msgId,
        from = LocalPlayer.Name,
        fromDisplay = LocalPlayer.DisplayName,
        fromId = LocalPlayer.UserId,
        toId = toUserId,
        text = text,
        timestamp = os.time(),
        read = false
    })
    
    Firebase.set("/message_notifs/" .. tostring(toUserId), {
        from = LocalPlayer.Name,
        fromDisplay = LocalPlayer.DisplayName,
        fromId = LocalPlayer.UserId,
        text = text,
        timestamp = os.time(),
        chatId = chatId
    })
end

function Firebase.getMessages(chatId)
    return Firebase.get("/chats/" .. chatId .. "/messages")
end

function Firebase.getNotif()
    return Firebase.get("/message_notifs/" .. tostring(LocalPlayer.UserId))
end

function Firebase.deleteNotif()
    Firebase.delete("/message_notifs/" .. tostring(LocalPlayer.UserId))
end

-- ================= INIT =================
task.spawn(function()
    task.wait(3)
    pcall(Firebase.goOnline)
    task.spawn(Firebase.keepAlive)
end)

game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
    pcall(Firebase.goOffline)
end)

-- Export
_G.Firebase = Firebase

print("[Firebase] Module ready!")