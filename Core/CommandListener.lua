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
local TextChatService = game:GetService("TextChatService")

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

-- ==================== BROADCAST KE CHAT PUBLIK ROBLOX ====================
-- Pesan dari admin akan MUNCUL DI CHAT BAWAAN ROBLOX yang bisa dilihat
-- semua pemain di sekitar (bukan cuma si target), sesuai permintaan.
local function broadcastToRobloxChat(message, senderLabel)
    local text = "[" .. (senderLabel or "ADMIN") .. "] " .. message

    -- Modern TextChatService (game baru)
    local ok1 = pcall(function()
        local generalChannel = TextChatService.TextChannels and
            TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            generalChannel:DisplaySystemMessage(text)
            return true
        end
        return false
    end)

    if ok1 then return true end

    -- Fallback: legacy ChatService lewat event bawaan (kalau game masih pakai legacy chat)
    local ok2 = pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = text,
            Color = Color3.fromRGB(255, 200, 50),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
        })
    end)

    return ok2
end

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
                    -- Pesan admin di-broadcast ke chat publik game, terlihat semua pemain
                    broadcastToRobloxChat(cmd.message or "", cmd.senderLabel or "ADMIN")

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
