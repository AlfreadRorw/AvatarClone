-- ================================================================
-- KEY SYSTEM (LICENSE GATE) — CloneBunker / PhoneIDViewer
-- Pastikan Firebase helpers (firebaseGet/Set/Delete) & LocalPlayer
-- sudah di-load sebelum file ini.
-- ================================================================

local KEY_CHECK_ROOT = "/keys"
local USER_KEY_ROOT  = "/user_keys"

-- Sekali gate ini lolos dalam sesi berjalan ini, jangan tampilkan lagi
-- walaupun requireValidKey() dipanggil ulang (misal tiap buka phone).
local sessionUnlocked = false

local DURATION_SECONDS = {
    ["3d"]  = 3  * 24 * 60 * 60,
    ["7d"]  = 7  * 24 * 60 * 60,
    ["30d"] = 30 * 24 * 60 * 60,
}

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

    -- pcall gagal total (network/firebase error) -> coba sekali lagi sebelum nyerah
    if not ok then
        task.wait(0.6)
        ok, keyData = pcall(firebaseGet, KEY_CHECK_ROOT .. "/" .. code)
    end

    if not ok then
        return false, "Gagal terhubung ke server. Cek koneksi lalu coba lagi."
    end

    if not keyData or type(keyData) ~= "table" then
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

    sessionUnlocked = true
    return true, "Key berhasil diaktifkan! Selamat menikmati.", expiresAt
end

-- ================= ENTRY POINT =================
-- Aman dipanggil berkali-kali (misal tiap buka phone): setelah pernah
-- lolos sekali di sesi ini, panggilan berikutnya langsung onDone(true)
-- tanpa nampilin popup lagi.
function requireValidKey(onDone)
    if sessionUnlocked then
        onDone(true)
        return
    end

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
            sessionUnlocked = true
            print("[PhoneIDViewer] Key aktif, sisa: " .. formatTimeLeft(expiresAt))
            onDone(true)
            return
        end

        showKeyGateUI(function()
            sessionUnlocked = true
            onDone(true)
        end)
    end)
end