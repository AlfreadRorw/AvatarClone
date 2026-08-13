-- ================================================
-- PHONE ID VIEWER - Modular Loader
-- by AlfreadRorw
-- ================================================

local BASE_URL = "https://raw.githubusercontent.com/AlfreadRorw/AvatarClone/main/"

local function Load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path, true))()
    end)
    if not ok then
        warn("[PhoneIDViewer] Failed: " .. path .. " | " .. tostring(result))
    end
    return ok and result or nil
end

-- Services
local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    SoundService = game:GetService("SoundService"),
    TeleportService = game:GetService("TeleportService"),
    CoreGui = game:GetService("CoreGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
}
_G.Services = Services

local LocalPlayer = Services.Players.LocalPlayer
_G.LocalPlayer = LocalPlayer

-- Load pondasi dulu (sebelum key system, karena key system butuh Firebase & helpers)
local Config = Load("Config.lua")
_G.Config = Config

local Theme = Load("Core/Theme.lua")
_G.T = Theme

local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

local Storage = Load("Core/Storage.lua")
_G.Storage = Storage

local Firebase = Load("Firebase.lua")
_G.Firebase = Firebase

-- Key system: load dulu (openPhone butuh requireValidKey tersedia)
Load("KeyGateUI.lua")
Load("KeySystem.lua")

-- ================= LOAD SEMUA MODUL DARI AWAL =================
-- Floating icon SELALU muncul begitu join, tidak menunggu key.
-- Key baru dicek pas player TAP floating icon (lihat pembungkus
-- openPhone di bagian bawah file ini).
local Phone = Load("Core/Phone.lua")
_G.Phone = Phone

local Icons = Load("Core/Icons.lua")
_G.Icons = Icons

Load("Core/BuildIcons.lua")

local AppList = {
    "Applications/Players.lua",
    "Applications/Clone.lua",
    "Applications/Body.lua",
    "Applications/Accessory.lua",
    "Applications/Preset.lua",
    "Applications/Favorites.lua",
    "Applications/Items.lua",
    "Applications/Teleport.lua",
    "Applications/Size.lua",
    "Applications/Volume.lua",
    "Applications/Friends.lua",
    "Applications/Server.lua",
    "Applications/Bundle.lua",
    "Applications/AvatarItems.lua",
    "Applications/Lookup.lua",
    "Applications/ServerJoiner.lua",
    "Applications/WhoOnline.lua",
    "Applications/Messages.lua",
    "Applications/Command.lua",
    "Applications/Settings.lua",
}

for _, path in ipairs(AppList) do
    Load(path)
end

Load("Core/FloatingIcon.lua")

-- ================= GATE DI TITIK BUKA PHONE =================
-- Core/Phone.lua sudah mendefinisikan _G.openPhone() versi "polos" (langsung
-- buka tanpa cek apapun). Kita bungkus di sini supaya SETIAP kali floating
-- icon di-tap, key dicek dulu lewat requireValidKey(). Karena KeySystem
-- punya sessionUnlocked + cek expiresAt di Firebase, popup key HANYA akan
-- muncul kalau memang belum pernah valid di sesi ini / key sudah expired —
-- bukan nanya berkali-kali.
local rawOpenPhone = _G.openPhone
_G.openPhone = function()
    requireValidKey(function(granted)
        if not granted then return end
        rawOpenPhone()
    end)
end

print("[PhoneIDViewer] All modules loaded!")