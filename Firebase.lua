-- ================================================
-- FIREBASE - With Key Binding System
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

local function getUrl(path)
    local baseUrl = config.databaseURL
    if not baseUrl:match("/$") then
        baseUrl = baseUrl .. "/"
    end
    return baseUrl .. path .. ".json?t=" .. tostring(os.time())
end

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
        end
    end
    return nil
end

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
    
    return success and result and result.Success
end

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

-- ==================== VALIDASI KEY ====================
-- Sekarang key terikat ke UserId player
-- Key hanya bisa dipakai 1 kali (dihapus setelah dipakai)
function Firebase.ValidateKey(key, userId)
    if not key or key == "" then 
        return false, "Key kosong"
    end
    
    key = key:upper():gsub("%s", "")
    
    local data = Firebase.GetData(KEYS_PATH .. "/" .. key)
    
    if not data then
        return false, "Gagal terhubung ke server"
    end
    
    if type(data) ~= "table" then
        return false, "Key tidak ditemukan"
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return false, "Key tidak valid"
    end
    
    local now = os.time()
    if expires <= now then
        Firebase.DeleteData(KEYS_PATH .. "/" .. key)
        return false, "Key sudah kedaluwarsa"
    end
    
    -- Cek apakah key sudah terikat ke player lain
    if data.usedBy and data.usedBy ~= tostring(userId) then
        return false, "Key sudah digunakan player lain"
    end
    
    -- Jika key belum terikat, ikat ke player ini
    if not data.usedBy then
        data.usedBy = tostring(userId)
        data.usedAt = now
        Firebase.SetData(KEYS_PATH .. "/" .. key, data)
    end
    
    local remaining = expires - now
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    
    return true, string.format("Berlaku %d jam %d menit", hours, minutes)
end

-- ==================== CEK KEY TERSIMPAN ====================
-- Cek apakah player sudah punya key yang masih valid
function Firebase.CheckSavedKey(userId, savedKey)
    if not savedKey or savedKey == "" then
        return false, "Tidak ada key tersimpan"
    end
    
    local data = Firebase.GetData(KEYS_PATH .. "/" .. savedKey)
    
    if not data or type(data) ~= "table" then
        return false, "Key tidak ditemukan"
    end
    
    -- Pastikan key terikat ke player ini
    if data.usedBy ~= tostring(userId) then
        return false, "Key tidak terikat ke player ini"
    end
    
    local expires = tonumber(data.expires)
    if not expires then
        return false, "Key tidak valid"
    end
    
    if expires > os.time() then
        local remaining = expires - os.time()
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        return true, string.format("Berlaku %d jam %d menit", hours, minutes)
    else
        -- Hapus key expired
        Firebase.DeleteData(KEYS_PATH .. "/" .. savedKey)
        return false, "Key sudah kedaluwarsa"
    end
end

-- ==================== GENERATE KEY (untuk website) ====================
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
        duration = durationHours or 24,
        usedBy = false,  -- Belum dipakai
        usedAt = false
    }
    
    if Firebase.SetData(KEYS_PATH .. "/" .. key, data) then
        return key, expires
    end
    return nil, nil
end

return Firebase