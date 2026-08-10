-- ================================================
-- PHONE ID VIEWER - Main Loader
-- by AlfreadRorw
-- ================================================

local BASE_URL = "https://raw.githubusercontent.com/AlfreadRorw/AvatarClone/main/"

local function Load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(BASE_URL .. path, true))()
    end)
    if not ok then
        warn("[PhoneIDViewer] Failed to load: " .. path)
        warn("Error: " .. tostring(result))
    end
    return ok and result or nil
end

-- ================================================
-- SERVICES
-- ================================================
local Services = {
    Players          = game:GetService("Players"),
    TweenService     = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService      = game:GetService("HttpService"),
    Workspace        = game:GetService("Workspace"),
    RunService       = game:GetService("RunService"),
    ReplicatedStorage= game:GetService("ReplicatedStorage"),
    SoundService     = game:GetService("SoundService"),
    TeleportService  = game:GetService("TeleportService"),
    CoreGui          = game:GetService("CoreGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
}

local LocalPlayer = Services.Players.LocalPlayer

-- ================================================
-- LOAD ORDER
-- ================================================

-- 1. Config (harus pertama)
local Config = Load("Config.lua")

-- 2. Core modules
local Theme    = Load("Core/Theme.lua")
local Helpers  = Load("Core/Helpers.lua")
local Storage  = Load("Core/Storage.lua")
local Firebase = Load("Firebase.lua")

-- 3. Phone GUI (frame, lock, home)
local Phone = Load("Core/Phone.lua")

-- 4. Icon builders
local Icons = Load("Core/Icons.lua")

-- 5. Applications
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

-- 6. Build home icons (setelah semua app loaded)
Load("Core/BuildIcons.lua")

-- 7. Floating icon + drag
Load("Core/FloatingIcon.lua")

print("[PhoneIDViewer] All modules loaded!")