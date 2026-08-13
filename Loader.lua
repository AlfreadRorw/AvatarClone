-- ================================================
-- PHONE ID VIEWER - Modular Loader
-- with Loading Progress
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

-- ==================== LOADING NOTIFICATION (MUNCUL PERTAMA) ====================
local Config = Load("Config.lua")
_G.Config = Config

local Theme = Load("Core/Theme.lua")
_G.T = Theme

local Helpers = Load("Core/Helpers.lua")
_G.Helpers = Helpers

-- Tampilkan loading notification
Load("Core/LoadingNotif.lua")
_G.showLoadingNotification()

-- ==================== LOAD CORE MODULES ====================
local totalSteps = 26 -- Total semua modul yang akan dimuat
local currentStep = 0

local function updateProgress(stepName)
    currentStep = currentStep + 1
    _G.updateLoadingProgress(currentStep, totalSteps, stepName)
end

updateProgress("Storage")
local Storage = Load("Core/Storage.lua")
_G.Storage = Storage

updateProgress("Firebase")
local Firebase = Load("Firebase.lua")
_G.Firebase = Firebase

updateProgress("Phone GUI")
local Phone = Load("Core/Phone.lua")
_G.Phone = Phone

updateProgress("Icons")
local Icons = Load("Core/Icons.lua")
_G.Icons = Icons

updateProgress("Build Icons")
Load("Core/BuildIcons.lua")

-- ==================== LOAD APPLICATIONS ====================
local AppList = {
    {path = "Applications/Players.lua", name = "Players"},
    {path = "Applications/Clone.lua", name = "Clone"},
    {path = "Applications/Body.lua", name = "Body"},
    {path = "Applications/Accessory.lua", name = "Accessory"},
    {path = "Applications/Preset.lua", name = "Preset"},
    {path = "Applications/Favorites.lua", name = "Favorites"},
    {path = "Applications/Items.lua", name = "Items"},
    {path = "Applications/Teleport.lua", name = "Teleport"},
    {path = "Applications/Size.lua", name = "Size"},
    {path = "Applications/Volume.lua", name = "Volume"},
    {path = "Applications/Friends.lua", name = "Friends"},
    {path = "Applications/Server.lua", name = "Server"},
    {path = "Applications/Bundle.lua", name = "Bundle"},
    {path = "Applications/AvatarItems.lua", name = "AvatarItems"},
    {path = "Applications/Lookup.lua", name = "Lookup"},
    {path = "Applications/ServerJoiner.lua", name = "ServerJoiner"},
    {path = "Applications/WhoOnline.lua", name = "WhoOnline"},
    {path = "Applications/Messages.lua", name = "Messages"},
    {path = "Applications/Command.lua", name = "Command"},
    {path = "Applications/Settings.lua", name = "Settings"},
}

for _, app in ipairs(AppList) do
    updateProgress(app.name)
    Load(app.path)
end

-- ==================== FLOATING ICON (TERAKHIR) ====================
updateProgress("Floating Icon")
Load("Core/FloatingIcon.lua")

-- ==================== SELESAI ====================
updateProgress("Selesai")
_G.finishLoading()

print("[PhoneIDViewer] All modules loaded!")