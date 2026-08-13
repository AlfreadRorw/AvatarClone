-- Firebase.lua - Fixed Version
local HttpService = game:GetService("HttpService")

local Firebase = {}

-- Konfigurasi Firebase
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

-- Fungsi untuk mendapatkan URL dengan timestamp (anti-cache)
local function getUrl(path)
    local baseUrl = config.databaseURL
    -- Pastikan URL berakhir dengan /
    if not baseUrl:match("/$") then
        baseUrl = baseUrl .. "/"
    end
    return baseUrl .. path .. ".json?t=" .. tostring(os.time()) .. "&auth=" .. config.apiKey
end

-- GET Data
function Firebase.GetData(path)
    local url = getUrl(path)
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            }
        })
    end)
    
    if success and result and result.Success then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if ok then
            return data
        else
            warn("[Firebase] JSON Decode Error:", data)
            return nil
        end
    else
        local errorMsg = "Unknown error"
        if result then
            errorMsg = result.StatusMessage or result.StatusCode or "Unknown"
        end
        warn("[Firebase] GET Failed:", errorMsg, "| URL:", url)
        return nil
    end
end

-- SET Data (PUT)
function Firebase.SetData(path, data)
    local url = getUrl(path)
    local jsonData = HttpService:JSONEncode(data)
    
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = jsonData
        })
    end)
    
    if success and result and result.Success then
        return true
    else
        warn("[Firebase] SET Failed:", result and result.StatusMessage or "Unknown")
        return false
    end
end

-- DELETE Data
function Firebase.DeleteData(path)
    local url = getUrl(path)
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "DELETE",
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    return success and result and result.Success
end

-- Validasi Key
function Firebase.ValidateKey(key)
    if not key or key == "" then 
        return false, "Key kosong"
    end
    
    -- Normalisasi key (uppercase, hapus spasi)
    key = key:upper():gsub("%s", "")
    
    local data = Firebase.GetData(KEYS_PATH .. "/" .. key)
    
    if not data then
        return false, "Gagal terhubung ke server"
    end
    
    -- Cek struktur data
    if type(data) ~= "table" then
        return false, "Key tidak ditemukan"
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return false, "Key tidak valid"
    end
    
    local now = os.time()
    if expires > now then
        local remaining = expires - now
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        return true, string.format("Berlaku %d jam %d menit", hours, minutes)
    else
        -- Key expired, hapus
        Firebase.DeleteData(KEYS_PATH .. "/" .. key)
        return false, "Key sudah kedaluwarsa"
    end
end

-- Generate Key (untuk website)
function Firebase.GenerateKey(durationHours)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local key = ""
    math.randomseed(os.time() + math.random(1, 999999))
    for i = 1, 8 do
        key = key .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    
    local expires = os.time() + (durationHours or 24) * 3600
    local data = {
        expires = expires,
        created = os.time(),
        duration = durationHours or 24
    }
    
    local success = Firebase.SetData(KEYS_PATH .. "/" .. key, data)
    if success then
        return key, expires
    else
        return nil, nil
    end
end

return Firebase