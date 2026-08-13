local HttpService = game:GetService("HttpService")

local Firebase = {}

-- Konfigurasi Firebase (sudah diisi)
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

function Firebase.Init(cfg)
    if cfg then config = cfg end
end

function Firebase.GetData(path)
    local url = config.databaseURL .. path .. ".json?t=" .. tostring(os.time())
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" }
        })
    end)
    if success and result.Success then
        local data = HttpService:JSONDecode(result.Body)
        return data
    else
        warn("[Firebase] GET failed:", result and result.StatusMessage or "Unknown error")
        return nil
    end
end

function Firebase.SetData(path, data)
    local url = config.databaseURL .. path .. ".json?t=" .. tostring(os.time())
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
    return success and result.Success
end

function Firebase.DeleteData(path)
    local url = config.databaseURL .. path .. ".json?t=" .. tostring(os.time())
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "DELETE",
            Headers = { ["Content-Type"] = "application/json" }
        })
    end)
    return success and result.Success
end

-- Validasi key: cek keberadaan dan masa berlaku
function Firebase.ValidateKey(key)
    if not key or key == "" then return false end
    local data = Firebase.GetData(KEYS_PATH .. "/" .. key)
    if not data then return false end
    local expires = tonumber(data.expires)
    if not expires then return false end
    if expires > os.time() then
        return true
    else
        Firebase.DeleteData(KEYS_PATH .. "/" .. key) -- hapus key kadaluwarsa
        return false
    end
end

-- Generate key (untuk dipakai di website, bukan di game)
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
    if Firebase.SetData(KEYS_PATH .. "/" .. key, data) then
        return key, expires
    end
    return nil, nil
end

Firebase.Init()
return Firebase