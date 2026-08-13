-- Firebase.lua
-- Wrapper Firebase Realtime Database untuk PhoneIDViewer
-- Taruh di root repo sejajar dengan Loader.lua

local HttpService = game:GetService("HttpService")
local Config = _G.Config or {}

-- ================= CONFIG =================
local FIREBASE_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app"
local FIREBASE_KEY = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80"

-- ================= CORE REQUEST =================
local function firebaseRequest(method, path, body)
    local url = FIREBASE_URL .. path .. ".json?auth=" .. FIREBASE_KEY
    local ok, result = pcall(function()
        -- Method 1: syn.request (Synapse / fluxus)
        if syn and syn.request then
            return syn.request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = body and HttpService:JSONEncode(body) or nil,
            })
        end
        -- Method 2: http_request (Delta / Krnl)
        if http_request then
            return http_request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = body and HttpService:JSONEncode(body) or nil,
            })
        end
        -- Method 3: request (generic)
        if request then
            return request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = body and HttpService:JSONEncode(body) or nil,
            })
        end
        -- Method 4: fallback GET-only lewat HttpGet
        if method == "GET" then
            return { Body = game:HttpGet(url, true) }
        end
        error("Tidak ada HTTP method yang tersedia")
    end)

    if ok and result and result.Body and result.Body ~= "" and result.Body ~= "null" then
        local dok, data = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if dok then return data end
    end
    return nil
end

-- ================= PUBLIC API =================
local Firebase = {}

function Firebase.get(path)
    return firebaseRequest("GET", path, nil)
end

function Firebase.set(path, data)
    firebaseRequest("PUT", path, data)
end

function Firebase.push(path, data)
    firebaseRequest("POST", path, data)
end

function Firebase.update(path, data)
    firebaseRequest("PATCH", path, data)
end

function Firebase.delete(path)
    firebaseRequest("DELETE", path, nil)
end

-- ================= GLOBAL SHORTCUTS =================
-- Supaya kode lama yang pakai firebaseGet/Set/Delete langsung (tanpa prefix)
-- tetap bisa jalan tanpa diubah
firebaseGet    = Firebase.get
firebaseSet    = Firebase.set
firebasePush   = Firebase.push
firebaseUpdate = Firebase.update
firebaseDelete = Firebase.delete

-- Export juga ke _G supaya module lain bisa akses lewat _G.Firebase
_G.Firebase       = Firebase
_G.firebaseGet    = Firebase.get
_G.firebaseSet    = Firebase.set
_G.firebasePush   = Firebase.push
_G.firebaseUpdate = Firebase.update
_G.firebaseDelete = Firebase.delete

print("[PhoneIDViewer] Firebase loaded — " .. FIREBASE_URL)

return Firebase