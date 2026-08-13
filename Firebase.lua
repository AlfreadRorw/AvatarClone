-- Firebase.lua
-- Wrapper Firebase Realtime Database untuk PhoneIDViewer
-- Taruh di root repo sejajar dengan Loader.lua

local HttpService = game:GetService("HttpService")
local Config = _G.Config or {}

-- ================= CONFIG =================
local FIREBASE_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app"
local FIREBASE_KEY = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80"

-- ================= CORE REQUEST =================
-- Delta (executor mobile) menyediakan fungsi global `request` (gaya UNC),
-- bukan `http_request`. Kita coba semua kemungkinan secara berurutan dan
-- LOG penyebab gagalnya secara jelas ke console (bukan diam-diam nil),
-- supaya kalau masih error, penyebabnya kelihatan di Roblox Console.
local function firebaseRequest(method, path, body)
    local url = FIREBASE_URL .. path .. ".json?auth=" .. FIREBASE_KEY
    local bodyStr = body and HttpService:JSONEncode(body) or nil

    local lastErr = nil

    local function tryMethod(name, fn)
        local ok, result = pcall(fn)
        if ok and result then
            return result
        end
        lastErr = name .. ": " .. tostring(result)
        return nil
    end

    local result = nil

    -- Method 1: request (UNC standar — Delta, Fluxus, sebagian besar executor mobile)
    if not result and request then
        result = tryMethod("request", function()
            return request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = bodyStr,
            })
        end)
    end

    -- Method 2: http_request (Krnl, beberapa versi Delta lama)
    if not result and http_request then
        result = tryMethod("http_request", function()
            return http_request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = bodyStr,
            })
        end)
    end

    -- Method 3: syn.request (Synapse X / Script-Ware)
    if not result and syn and syn.request then
        result = tryMethod("syn.request", function()
            return syn.request({
                Url     = url,
                Method  = method,
                Headers = {["Content-Type"] = "application/json"},
                Body    = bodyStr,
            })
        end)
    end

    -- Method 4: fallback GET-only lewat HttpGet (tidak butuh executor khusus,
    -- tapi cuma bisa GET, tidak bisa PUT/POST/PATCH/DELETE)
    if not result and method == "GET" then
        result = tryMethod("game:HttpGet", function()
            return { Body = game:HttpGet(url, true) }
        end)
    end

    if not result then
        warn("[Firebase] Semua metode HTTP gagal untuk " .. method .. " " .. path .. " | " .. tostring(lastErr))
        return nil, lastErr or "Tidak ada HTTP method yang tersedia di executor ini."
    end

    if result.Body and result.Body ~= "" and result.Body ~= "null" then
        local dok, data = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if dok then return data end
        warn("[Firebase] Gagal parse JSON dari " .. path .. " | Body: " .. tostring(result.Body):sub(1, 200))
        return nil, "Gagal membaca respons server."
    end

    -- Body kosong/null artinya path memang belum ada isinya (bukan error)
    return nil
end

-- ================= PUBLIC API =================
local Firebase = {}

function Firebase.get(path)
    local data, err = firebaseRequest("GET", path, nil)
    return data, err
end

function Firebase.set(path, data)
    local _, err = firebaseRequest("PUT", path, data)
    return err
end

function Firebase.push(path, data)
    local _, err = firebaseRequest("POST", path, data)
    return err
end

function Firebase.update(path, data)
    local _, err = firebaseRequest("PATCH", path, data)
    return err
end

function Firebase.delete(path)
    local _, err = firebaseRequest("DELETE", path, nil)
    return err
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