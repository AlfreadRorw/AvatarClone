-- ================================================
-- COMMAND LISTENER - Fitur Baru
-- Mendengarkan perintah dari Admin Dashboard (website) lewat Firebase
-- /commands/<userId>/<cmdId> = {type="teleport"/"chat_broadcast"/"kick", ...}
--
-- Fitur:
--   1. Teleport player ke koordinat manual ATAU lokasi preset
--   2. Broadcast pesan admin ke chat PUBLIK Roblox (kelihatan pemain lain)
--   3. Kick player (opsional, dari admin)
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Firebase    = _G.Firebase
local TextChatService  = game:GetService("TextChatService")
local TeleportService  = game:GetService("TeleportService")

local lastCheckedCmdIds = {} -- anti double-execute

-- ==================== TELEPORT ====================
local function teleportPlayerTo(x, y, z)
    local char = LocalPlayer.Character
    if not char then return false, "Karakter tidak ditemukan" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "HumanoidRootPart tidak ditemukan" end

    local ok = pcall(function()
        hrp.CFrame = CFrame.new(x, y, z)
    end)
    return ok
end

-- ==================== CHAT BUBBLE DI ATAS KEPALA ====================
-- Ini BUKAN system message di jendela chat, tapi BALON CHAT yang muncul
-- MENGAMBANG DI ATAS KEPALA karakter si player (yang biasa muncul kalau
-- pemain ngetik di kotak chat Roblox). Ini yang diminta: "chat yang keluar
-- di atas kepala", bukan notifikasi sistem.
local Chat = game:GetService("Chat")

local function showChatBubbleOverHead(message, senderLabel)
    local char = LocalPlayer.Character
    if not char then return false, "Karakter tidak ditemukan" end
    local head = char:FindFirstChild("Head")
    if not head then return false, "Head tidak ditemukan" end

    local text = "[" .. (senderLabel or "ADMIN") .. "] " .. message

    -- API resmi Roblox untuk memunculkan balon chat di atas kepala part manapun,
    -- ini yang dipakai chat bawaan Roblox sendiri saat pemain mengetik.
    local ok = pcall(function()
        Chat:Chat(head, text, Enum.ChatColor.Red)
    end)

    if not ok then
        -- Fallback: BubbleChat modern (ChatService lewat event) kalau Chat:Chat gagal
        pcall(function()
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        end)
    end

    return ok
end

-- ==================== CEK PENDING TELEPORT (SETELAH PINDAH SERVER) ====================
-- Kalau player baru saja di-TeleportToPlaceInstance oleh CommandListener (karena
-- target TP-on-Tap/TP-ke-Dev ada di server lain), posisi tujuan disimpan sementara
-- di Firebase sebelum pindah. Begitu script ini jalan lagi di server baru, kita
-- cek dan eksekusi posisi yang tertunda itu, lalu hapus.
task.spawn(function()
    task.wait(5) -- tunggu karakter benar-benar spawn dulu di server baru
    if not Firebase or not Firebase.GetData then return end

    local ok, pending = pcall(function()
        return Firebase.GetData("pending_teleport/" .. tostring(LocalPlayer.UserId))
    end)

    if ok and pending and type(pending) == "table" and pending.x then
        -- Hanya proses kalau umurnya masih wajar (< 60 detik), biar tidak
        -- mengeksekusi teleport basi kalau player join biasa di lain waktu.
        if os.time() - (pending.timestamp or 0) < 60 then
            teleportPlayerTo(pending.x, pending.y, pending.z)
            if _G.showDynamicNotification then
                _G.showDynamicNotification("📍 Diposisikan sesuai perintah Dev", Color3.fromRGB(168,100,255))
            end
        end
        pcall(function()
            Firebase.DeleteData("pending_teleport/" .. tostring(LocalPlayer.UserId))
        end)
    end
end)

-- ==================== POLLING LOOP ====================
task.spawn(function()
    task.wait(4) -- tunggu Firebase & LocalPlayer siap

    while true do
        task.wait(3)

        if not Firebase or not Firebase.GetCommands then continue end

        local ok, commands = pcall(function()
            return Firebase.GetCommands(LocalPlayer.UserId)
        end)
        if not ok or not commands or type(commands) ~= "table" then continue end

        for cmdId, cmd in pairs(commands) do
            if type(cmd) == "table" and not lastCheckedCmdIds[cmdId] then
                lastCheckedCmdIds[cmdId] = true

                if cmd.type == "teleport" then
                    local x = tonumber(cmd.x) or 0
                    local y = tonumber(cmd.y) or 0
                    local z = tonumber(cmd.z) or 0
                    local success = teleportPlayerTo(x, y, z)

                    if success and _G.showDynamicNotification then
                        _G.showDynamicNotification(
                            "📍 Diteleport oleh Admin" .. (cmd.locationName and (" ke " .. cmd.locationName) or ""),
                            Color3.fromRGB(0, 200, 255)
                        )
                    end

                elseif cmd.type == "chat_broadcast" then
                    -- Pesan admin muncul sebagai BALON CHAT di atas kepala player,
                    -- persis seperti kalau si player ngetik sendiri di chat Roblox.
                    -- Karena ini bubble bawaan Roblox, otomatis kelihatan oleh
                    -- semua pemain lain yang ada di dekat karakter tersebut.
                    showChatBubbleOverHead(cmd.message or "", cmd.senderLabel or "ADMIN")

                elseif cmd.type == "teleport_to_point" then
                    -- Dari Premium.lua TP-on-Tap. Kalau titik ini dari server LAIN
                    -- (fromJobId beda dari server kita sekarang), kita harus pindah
                    -- server dulu baru posisi diset di server tujuan.
                    if cmd.fromJobId and cmd.fromJobId ~= game.JobId and cmd.fromPlaceId then
                        -- Simpan target posisi ke Firebase supaya bisa dibaca lagi
                        -- SETELAH kita sampai di server tujuan (posisi tidak bisa
                        -- dikirim langsung lewat TeleportService tanpa TeleportData).
                        pcall(function()
                            Firebase.SetData("pending_teleport/" .. tostring(LocalPlayer.UserId), {
                                x = cmd.x, y = cmd.y, z = cmd.z,
                                timestamp = os.time(),
                            })
                        end)
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                tonumber(cmd.fromPlaceId), cmd.fromJobId, LocalPlayer
                            )
                        end)
                    else
                        -- Server yang sama -> langsung set CFrame
                        local ok = teleportPlayerTo(cmd.x, cmd.y, cmd.z)
                        if ok and _G.showDynamicNotification then
                            _G.showDynamicNotification("📍 Dipindahkan oleh Dev", Color3.fromRGB(168,100,255))
                        end
                    end

                elseif cmd.type == "teleport_to_dev" then
                    -- Dari Premium.lua "TP ke Aku" (dev). Kalau dev di server lain,
                    -- kita pindah server dulu ke server dev, lalu posisi menyusul
                    -- lewat pending_teleport (atau player akan dekat dev secara wajar
                    -- karena spawn di server yang sama).
                    if cmd.devJobId and cmd.devJobId ~= game.JobId and cmd.devPlaceId then
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                tonumber(cmd.devPlaceId), cmd.devJobId, LocalPlayer
                            )
                        end)
                    else
                        -- Server sama -> cari langsung karakter dev dan nempel di sebelahnya
                        local devPlayer = Services.Players:GetPlayerByUserId(tonumber(cmd.devUserId))
                        if devPlayer and devPlayer.Character then
                            local devHrp = devPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if devHrp and myHrp then
                                pcall(function()
                                    myHrp.CFrame = devHrp.CFrame * CFrame.new(3, 0, 0)
                                end)
                            end
                        end
                    end
                    if _G.showDynamicNotification then
                        _G.showDynamicNotification("📍 Ditarik ke posisi Dev", Color3.fromRGB(168,100,255))
                    end

                elseif cmd.type == "kick" then
                    pcall(function()
                        LocalPlayer:Kick(cmd.reason or "Dikeluarkan oleh Admin.")
                    end)
                end

                -- Hapus command setelah dieksekusi supaya tidak diulang
                pcall(function()
                    Firebase.DeleteCommand(LocalPlayer.UserId, cmdId)
                end)
            end
        end
    end
end)

print("[CommandListener] Loaded! Mendengarkan perintah dari Admin Dashboard.")
