-- Firebase.lua
-- Firebase Realtime Database + Key System + Online Tracker + Messages

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local HttpService = Services.HttpService

-- ================= FIREBASE CONFIG =================
local FIREBASE_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app"

-- ================= FIREBASE FUNCTIONS =================
local Firebase = {}

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
    
    return nil
end

function Firebase.set(path, data)
    firebaseRequest("PUT", path, data)
end

function Firebase.get(path)
    return firebaseRequest("GET", path, nil)
end

function Firebase.delete(path)
    firebaseRequest("DELETE", path, nil)
end

-- ================= KEY SYSTEM =================
-- Struktur Firebase:
-- /keys/{key} = {userId, expiresAt, valid, createdAt}

local sessionUnlocked = false
local sessionExpiresAt = 0
local activeKeyPopup = nil

-- Check key dari Firebase
function Firebase.checkKey(key)
    local keyData = Firebase.get("/keys/" .. key)
    
    if keyData and type(keyData) == "table" then
        local expiresAt = keyData.expiresAt or 0
        local isValid = keyData.valid == true
        
        -- Cek apakah key masih valid (belum expired)
        if isValid and expiresAt > os.time() then
            -- Key valid - tandai sebagai terpakai
            Firebase.set("/keys/" .. key .. "/used", true)
            Firebase.set("/keys/" .. key .. "/usedBy", {
                username = LocalPlayer.Name,
                userId = LocalPlayer.UserId,
                usedAt = os.time()
            })
            return true, expiresAt
        elseif isValid and expiresAt <= os.time() then
            -- Key expired
            Firebase.set("/keys/" .. key .. "/valid", false)
            return false, 0, "expired"
        else
            return false, 0, "invalid"
        end
    end
    
    return false, 0, "notfound"
end

-- Check session lokal
function Firebase.checkSession()
    if sessionUnlocked and sessionExpiresAt > os.time() then
        return true, sessionExpiresAt
    end
    return false, 0
end

-- Require valid key
function requireValidKey(callback)
    -- Cek session dulu
    local sessionValid, sessionExpiry = Firebase.checkSession()
    if sessionValid then
        callback(true, sessionExpiry)
        return
    end
    
    -- Session tidak valid - tampilkan popup
    showKeyPopup(callback)
end

-- Format time remaining
local function formatTimeRemaining(expiresAt)
    local remaining = expiresAt - os.time()
    
    if remaining <= 0 then
        return "Expired"
    end
    
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    
    if days > 0 then
        return string.format("%d hari %d jam", days, hours)
    elseif hours > 0 then
        return string.format("%d jam %d menit", hours, minutes)
    elseif minutes > 0 then
        return string.format("%d menit", minutes)
    else
        return string.format("%d detik", remaining)
    end
end

-- Popup key
function showKeyPopup(callback)
    if activeKeyPopup then
        pcall(function() activeKeyPopup:Destroy() end)
    end
    
    local popupGui = Instance.new("ScreenGui")
    popupGui.Name = "KeyPopup"
    popupGui.ResetOnSpawn = false
    popupGui.IgnoreGuiInset = true
    popupGui.DisplayOrder = 99999
    popupGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    pcall(function() popupGui.Parent = game:GetService("CoreGui") end)
    if not popupGui.Parent then popupGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    activeKeyPopup = popupGui
    
    -- Backdrop
    local backdrop = Instance.new("Frame", popupGui)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.6
    backdrop.ZIndex = 10000
    
    -- Card
    local card = Instance.new("Frame", popupGui)
    card.Size = UDim2.new(0, 300, 0, 220)
    card.Position = UDim2.new(0.5, -150, 0.5, -110)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    card.ZIndex = 10001
    Helpers.corner(card, 16)
    Helpers.stroke(card, Color3.fromRGB(80, 150, 255), 2, 0)
    
    -- Gradient
    local cardGrad = Instance.new("UIGradient", card)
    cardGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 28, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 26))
    })
    cardGrad.Rotation = 135
    
    -- Title
    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "ENTER ACCESS KEY"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.ZIndex = 10002
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel", card)
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.new(0, 10, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Dapatkan key dari developer"
    subtitle.TextColor3 = Color3.fromRGB(120, 120, 130)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 9
    subtitle.ZIndex = 10002
    
    -- Key input
    local keyInput = Instance.new("TextBox", card)
    keyInput.Size = UDim2.new(1, -40, 0, 38)
    keyInput.Position = UDim2.new(0, 20, 0, 70)
    keyInput.PlaceholderText = "PHONE-XXXX-XXXX-XXXX"
    keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    keyInput.Text = ""
    keyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    keyInput.TextColor3 = Color3.new(1, 1, 1)
    keyInput.Font = Enum.Font.Code
    keyInput.TextSize = 14
    keyInput.ZIndex = 10002
    Helpers.corner(keyInput, 8)
    Helpers.stroke(keyInput, Color3.fromRGB(60, 60, 70), 1, 0)
    
    -- Error label
    local errorLbl = Instance.new("TextLabel", card)
    errorLbl.Size = UDim2.new(1, -20, 0, 18)
    errorLbl.Position = UDim2.new(0, 10, 0, 112)
    errorLbl.BackgroundTransparency = 1
    errorLbl.Text = ""
    errorLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    errorLbl.Font = Enum.Font.Gotham
    errorLbl.TextSize = 10
    errorLbl.ZIndex = 10002
    
    -- Submit button
    local submitBtn = Instance.new("TextButton", card)
    submitBtn.Size = UDim2.new(1, -40, 0, 36)
    submitBtn.Position = UDim2.new(0, 20, 0, 134)
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    submitBtn.Text = "ACTIVATE"
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.Font = Enum.Font.GothamBlack
    submitBtn.TextSize = 12
    submitBtn.AutoButtonColor = false
    submitBtn.ZIndex = 10002
    Helpers.corner(submitBtn, 8)
    Helpers.pressFX(submitBtn)
    
    -- Info expiry
    local expiryLbl = Instance.new("TextLabel", card)
    expiryLbl.Size = UDim2.new(1, -20, 0, 14)
    expiryLbl.Position = UDim2.new(0, 10, 0, 176)
    expiryLbl.BackgroundTransparency = 1
    expiryLbl.Text = "Key berlaku selama durasi yang ditentukan"
    expiryLbl.TextColor3 = Color3.fromRGB(80, 80, 90)
    expiryLbl.Font = Enum.Font.Gotham
    expiryLbl.TextSize = 8
    expiryLbl.ZIndex = 10002
    
    submitBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text:upper():gsub("%s+", "")
        
        if key == "" then
            errorLbl.Text = "❌ Key tidak boleh kosong!"
            return
        end
        
        submitBtn.Text = "Checking..."
        submitBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        submitBtn.Interactable = false
        
        task.spawn(function()
            task.wait(1)
            
            local valid, expiresAt, errorType = Firebase.checkKey(key)
            
            if valid then
                sessionUnlocked = true
                sessionExpiresAt = expiresAt
                
                pcall(function() popupGui:Destroy() end)
                activeKeyPopup = nil
                
                showDynamicNotification("✅ Key valid! Akses diberikan.", Color3.fromRGB(0, 200, 80))
                
                if callback then
                    callback(true, expiresAt)
                end
            else
                submitBtn.Text = "ACTIVATE"
                submitBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                submitBtn.Interactable = true
                
                if errorType == "expired" then
                    errorLbl.Text = "❌ Key sudah expired!"
                elseif errorType == "notfound" then
                    errorLbl.Text = "❌ Key tidak ditemukan!"
                else
                    errorLbl.Text = "❌ Key tidak valid!"
                end
                
                if callback then
                    callback(false)
                end
            end
        end)
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

print("[Firebase] Module ready with Key System!")