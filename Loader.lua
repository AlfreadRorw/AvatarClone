-- ================================================
-- PHONE ID VIEWER - Modular Loader (FIXED)
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

-- ==================== SERVICES ====================
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

-- ==================== LOAD ORDER (PENTING!) ====================
-- 1. Config dulu
local Config = Load("Config.lua")
_G.Config = Config

-- 2. Theme
local Theme = Load("Core/Theme.lua")
_G.T = Theme

-- 3. Helpers
local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

-- 4. Storage (SEBELUM Firebase dan Phone)
local Storage = Load("Core/Storage.lua")
_G.Storage = Storage

-- 5. Firebase (SEBELUM Phone)
local Firebase = Load("Firebase.lua")
_G.Firebase = Firebase

-- 6. Phone (SETELAH Storage dan Firebase tersedia)
local Phone = Load("Core/Phone.lua")
_G.Phone = Phone

-- 7. Icons
local Icons = Load("Core/Icons.lua")
_G.Icons = Icons

-- 8. BuildIcons (SETELAH Phone dan Icons)
Load("Core/BuildIcons.lua")

-- 9. Applications (SETELAH BuildIcons)
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

-- 10. FloatingIcon (TERAKHIR)
Load("Core/FloatingIcon.lua")

print("[PhoneIDViewer] All modules loaded successfully!")
print("[PhoneIDViewer] Phone:", _G.Phone and "OK" or "FAILED")
print("[PhoneIDViewer] Firebase:", _G.Firebase and "OK" or "FAILED")
print("[PhoneIDViewer] Storage:", _G.Storage and "OK" or "FAILED")