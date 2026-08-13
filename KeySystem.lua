-- ================================================================
-- KEY SYSTEM (LICENSE GATE) — CloneBunker / PhoneIDViewer
-- Pastikan Firebase helpers (firebaseGet/Set/Delete) & LocalPlayer
-- sudah di-load sebelum file ini.
-- ================================================================

local KEY_CHECK_ROOT = "/keys"
local USER_KEY_ROOT  = "/user_keys"

local DURATION_SECONDS = {
    ["3d"]  = 3  * 24 * 60 * 60,
    ["7d"]  = 7  * 24 * 60 * 60,
    ["30d"] = 30 * 24 * 60 * 60,
}

-- ================= VALIDASI / BIND KEY =================
local function tryActivateKey(code)
    code = tostring(code or ""):upper():gsub("%s+", "")
    if code == "" then
        return false, "Key tidak boleh kosong."
    end

    local keyData = firebaseGet(KEY_CHECK_ROOT .. "/" .. code)
    if not keyData or type(keyData) ~= "table" then
        return false, "Key tidak ditemukan. Cek kembali kode kamu."
    end

    local now = os.time()

    if keyData.used then
        if tostring(keyData.boundUserId) == tostring(LocalPlayer.UserId) then
            if keyData.expiresAt and now > keyData.expiresAt then
                return false, "Key kamu sudah expired. Silakan beli key baru."
            end
            return true, "Key valid, selamat datang kembali!", keyData.expiresAt
        else
            return false, "Key ini sudah dipakai oleh pemain lain."
        end
    end

    local durationSecs = DURATION_SECONDS[keyData.duration] or (7 * 24 * 60 * 60)
    local expiresAt    = now + durationSecs

    firebaseSet(KEY_CHECK_ROOT .. "/" .. code, {
        duration      = keyData.duration,
        durationDays  = keyData.durationDays,
        durationLabel = keyData.durationLabel,
        createdAt     = keyData.createdAt,
        used          = true,
        boundUserId   = LocalPlayer.UserId,
        boundUsername = LocalPlayer.Name,
        activatedAt   = now,
        expiresAt     = expiresAt,
    })

    firebaseSet(USER_KEY_ROOT .. "/" .. tostring(LocalPlayer.UserId), {
        code          = code,
        expiresAt     = expiresAt,
        durationLabel = keyData.durationLabel,
    })

    return true, "Key berhasil diaktifkan! Selamat menikmati.", expiresAt
end

-- ================= CEK KEY AKTIF (AUTO-LOGIN) =================
local function checkExistingAccess()
    local userKey = firebaseGet(USER_KEY_ROOT .. "/" .. tostring(LocalPlayer.UserId))
    if userKey and type(userKey) == "table" and userKey.code then
        local keyData = firebaseGet(KEY_CHECK_ROOT .. "/" .. userKey.code)
        if keyData and type(keyData) == "table" and keyData.expiresAt then
            if os.time() <= keyData.expiresAt then
                return true, keyData.expiresAt
            end
        end
    end
    return false, nil
end

-- ================= FORMAT SISA WAKTU =================
local function formatTimeLeft(expiresAt)
    local diff = expiresAt - os.time()
    if diff <= 0 then return "Expired" end
    local days  = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    if days > 0 then
        return string.format("%dh %djam lagi", days, hours)
    else
        local mins = math.floor((diff % 3600) / 60)
        return string.format("%djam %dmenit lagi", hours, mins)
    end
end

-- ================= HELPER AMBIL LOCAL PLAYER SAFELY =================
local function getLocalPlayer()
    return _G.LocalPlayer
        or (game:GetService("Players") and game:GetService("Players").LocalPlayer)
        or nil
end

-- ================= CEK KEY AKTIF (AUTO-LOGIN) =================
local function checkExistingAccess()
    local lp = getLocalPlayer()
    if not lp then
        warn("[KeySystem] LocalPlayer nil saat checkExistingAccess")
        return false, nil
    end

    local ok, userKey = pcall(firebaseGet, USER_KEY_ROOT .. "/" .. tostring(lp.UserId))
    if not ok or not userKey or type(userKey) ~= "table" or not userKey.code then
        return false, nil
    end

    local ok2, keyData = pcall(firebaseGet, KEY_CHECK_ROOT .. "/" .. userKey.code)
    if ok2 and keyData and type(keyData) == "table" and keyData.expiresAt then
        if os.time() <= keyData.expiresAt then
            return true, keyData.expiresAt
        end
    end
    return false, nil
end

-- ================= VALIDASI / BIND KEY =================
local function tryActivateKey(code)
    local lp = getLocalPlayer()
    if not lp then
        return false, "Player tidak ditemukan, coba restart."
    end

    code = tostring(code or ""):upper():gsub("%s+", "")
    if code == "" then
        return false, "Key tidak boleh kosong."
    end

    local ok, keyData = pcall(firebaseGet, KEY_CHECK_ROOT .. "/" .. code)
    if not ok or not keyData or type(keyData) ~= "table" then
        return false, "Key tidak ditemukan. Cek kembali kode kamu."
    end

    local now = os.time()

    if keyData.used then
        if tostring(keyData.boundUserId) == tostring(lp.UserId) then
            if keyData.expiresAt and now > keyData.expiresAt then
                return false, "Key kamu sudah expired. Silakan beli key baru."
            end
            return true, "Key valid, selamat datang kembali!", keyData.expiresAt
        else
            return false, "Key ini sudah dipakai oleh pemain lain."
        end
    end

    local durationSecs = DURATION_SECONDS[keyData.duration] or (7 * 24 * 60 * 60)
    local expiresAt    = now + durationSecs

    pcall(firebaseSet, KEY_CHECK_ROOT .. "/" .. code, {
        duration      = keyData.duration,
        durationDays  = keyData.durationDays,
        durationLabel = keyData.durationLabel,
        createdAt     = keyData.createdAt,
        used          = true,
        boundUserId   = lp.UserId,
        boundUsername = lp.Name,
        activatedAt   = now,
        expiresAt     = expiresAt,
    })

    pcall(firebaseSet, USER_KEY_ROOT .. "/" .. tostring(lp.UserId), {
        code          = code,
        expiresAt     = expiresAt,
        durationLabel = keyData.durationLabel,
    })

    return true, "Key berhasil diaktifkan! Selamat menikmati.", expiresAt
end

-- ================= ENTRY POINT =================
function requireValidKey(onDone)
    task.spawn(function()
        -- Tunggu LocalPlayer ready (penting kalau script jalan sangat awal)
        local lp = getLocalPlayer()
        local waited = 0
        while not lp and waited < 10 do
            task.wait(0.5)
            waited = waited + 0.5
            lp = getLocalPlayer()
        end

        if not lp then
            warn("[KeySystem] LocalPlayer tidak tersedia setelah 10 detik")
            -- Tetap tampilkan gate, biar user bisa coba
        end

        local hasAccess, expiresAt = checkExistingAccess()
        if hasAccess then
            print("[PhoneIDViewer] Key aktif, sisa: " .. formatTimeLeft(expiresAt))
            onDone(true)
            return
        end

        showKeyGateUI(function()
            onDone(true)
        end)
    end)
end