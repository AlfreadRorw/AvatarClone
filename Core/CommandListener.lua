-- ================================================
-- COMMAND LISTENER - Fitur Baru + Premium Troll/Chat
-- Mendengarkan perintah dari Admin Dashboard (website) & Premium App lewat Firebase
-- /commands/<userId>/<cmdId> = {type="teleport"/"chat_broadcast"/"kick"/"force_chat"/"troll_action", ...}
-- ================================================

local Services    = _G.Services
local LocalPlayer = _G.LocalPlayer
local Firebase    = _G.Firebase
local TextChatService  = game:GetService("TextChatService")
local TeleportService  = game:GetService("TeleportService")
local Chat             = game:GetService("Chat")

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
local function showChatBubbleOverHead(message, senderLabel)
    local char = LocalPlayer.Character
    if not char then return false, "Karakter tidak ditemukan" end
    local head = char:FindFirstChild("Head")
    if not head then return false, "Head tidak ditemukan" end

    local text = "[" .. (senderLabel or "ADMIN") .. "] " .. message

    -- API resmi Roblox untuk memunculkan balon chat di atas kepala
    local ok = pcall(function()
        Chat:Chat(head, text, Enum.ChatColor.Red)
    end)

    if not ok then
        -- Fallback: BubbleChat modern
        pcall(function()
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        end)
    end

    return ok
end

-- ==================== CEK PENDING TELEPORT (SETELAH PINDAH SERVER) ====================
task.spawn(function()
    task.wait(5) -- tunggu karakter benar-benar spawn dulu di server baru
    if not Firebase or not Firebase.GetData then return end

    local ok, pending = pcall(function()
        return Firebase.GetData("pending_teleport/" .. tostring(LocalPlayer.UserId))
    end)

    if ok and pending and type(pending) == "table" and pending.x then
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
                    showChatBubbleOverHead(cmd.message or "", cmd.senderLabel or "ADMIN")

                elseif cmd.type == "teleport_to_point" then
                    if cmd.fromJobId and cmd.fromJobId ~= game.JobId and cmd.fromPlaceId then
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
                        local ok = teleportPlayerTo(cmd.x, cmd.y, cmd.z)
                        if ok and _G.showDynamicNotification then
                            _G.showDynamicNotification("📍 Dipindahkan oleh Dev", Color3.fromRGB(168,100,255))
                        end
                    end

                elseif cmd.type == "teleport_to_dev" then
                    if cmd.devJobId and cmd.devJobId ~= game.JobId and cmd.devPlaceId then
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(
                                tonumber(cmd.devPlaceId), cmd.devJobId, LocalPlayer
                            )
                        end)
                    else
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

                -- =================== FITUR PREMIUM (FORCE CHAT & TROLL) ===================
                elseif cmd.type == "force_chat" then
                    -- Memaksa target bicara menggunakan Chat Roblox Bawaan (Bubble Chat)
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Head") then
                        Chat:Chat(char.Head, cmd.message or "...", Enum.ChatColor.White)
                    end

                elseif cmd.type == "troll_action" then
                    local action = cmd.action
                    local char = LocalPlayer.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChild("Humanoid")

                        if action == "jail" then
                            if hrp then
                                -- Hapus box lama jika ada agar tidak tertumpuk
                                local oldBox = game.Workspace:FindFirstChild("PremiumJailBox_" .. LocalPlayer.Name)
                                if oldBox then oldBox:Destroy() end

                                -- Bikin box kaca
                                local box = Instance.new("Part")
                                box.Name = "PremiumJailBox_" .. LocalPlayer.Name
                                box.Size = Vector3.new(5, 7, 5)
                                box.Position = hrp.Position
                                box.Anchored = true
                                box.Material = Enum.Material.Glass
                                box.Transparency = 0.5
                                box.BrickColor = BrickColor.new("Cyan")
                                box.Parent = game.Workspace
                                
                                hrp.CFrame = CFrame.new(box.Position)
                                if hum then
                                    hum.WalkSpeed = 0
                                    hum.JumpPower = 0
                                end
                            end

                        elseif action == "unjail" then
                            local box = game.Workspace:FindFirstChild("PremiumJailBox_" .. LocalPlayer.Name)
                            if box then box:Destroy() end
                            if hum then 
                                hum.WalkSpeed = 16
                                hum.JumpPower = 50
                            end

                        elseif action == "freeze" then
                            if hrp then hrp.Anchored = true end

                        elseif action == "unfreeze" then
                            if hrp then hrp.Anchored = false end

                        elseif action == "fling" then
                            if hrp then
                                hrp.Velocity = Vector3.new(0, 1000, 0) -- Lempar ke langit
                                local bg = Instance.new("BodyAngularVelocity")
                                bg.AngularVelocity = Vector3.new(50, 50, 50)
                                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                bg.Parent = hrp
                                game.Debris:AddItem(bg, 2)
                            end

                        elseif action == "kill" then
                            if hum then hum.Health = 0 end
                        end
                    end
                end
                -- ==============================================================================

                -- Hapus command setelah dieksekusi supaya tidak diulang
                pcall(function()
                    Firebase.DeleteCommand(LocalPlayer.UserId, cmdId)
                end)
            end
        end
    end
end)

print("[CommandListener] Loaded! Mendengarkan perintah dari Admin Dashboard.")
