-- ================================================
-- PHONE ID VIEWER - Modular Loader (Fast Version)
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

-- ==================== LOAD CORE DULU ====================
local Config = Load("Config.lua")
_G.Config = Config

local Theme = Load("Core/Theme.lua")
_G.T = Theme

local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

-- ==================== TAMPILKAN LOADING NOTIFICATION ====================
Load("Core/LoadingNotif.lua")
_G.showLoadingNotification()

-- ==================== LOAD SEMUA MODUL SECARA PARALEL ====================
-- Gunakan task.spawn agar tidak blocking
task.spawn(function()
    local Storage = Load("Core/Storage.lua")
    _G.Storage = Storage
end)

task.spawn(function()
    local Firebase = Load("Firebase.lua")
    _G.Firebase = Firebase
end)

task.spawn(function()
    local Phone = Load("Core/Phone.lua")
    _G.Phone = Phone
end)

task.spawn(function()
    local Icons = Load("Core/Icons.lua")
    _G.Icons = Icons
end)

-- ==================== LOAD APPLICATIONS PARALEL ====================
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

-- Load aplikasi secara paralel
for _, path in ipairs(AppList) do
    task.spawn(function()
        Load(path)
    end)
end

-- ==================== SIMULASI PROGRESS (CEPAT) ====================
task.spawn(function()
    local totalSteps = 25
    local steps = {
        "Storage", "Firebase", "Phone GUI", "Icons",
        "Players", "Clone", "Body", "Accessory", "Preset",
        "Favorites", "Items", "Teleport", "Size", "Volume",
        "Friends", "Server", "Bundle", "AvatarItems", "Lookup",
        "ServerJoiner", "WhoOnline", "Messages", "Command",
        "Settings", "Floating Icon"
    }
    
    -- Update progress cepat (0.15 detik per step)
    for i, stepName in ipairs(steps) do
        _G.updateLoadingProgress(i, totalSteps, stepName)
        task.wait(0.15) -- Cepat, total ~3.75 detik
    end
    
    -- Tunggu sebentar untuk memastikan semua loaded
    task.wait(0.5)
    
    -- Load FloatingIcon
    Load("Core/FloatingIcon.lua")
    
    -- Selesai
    _G.finishLoading()
    
    print("[PhoneIDViewer] All modules loaded!")
end)