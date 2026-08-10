local HttpService = game:GetService("HttpService")
local Helpers     = _G.Helpers

local PRESET_FILE        = "PhoneIDViewer_Presets.json"
local FAV_FILE           = "PhoneIDViewer_FavPlayers.json"
local FAV_ITEMS_FILE     = "PhoneIDViewer_FavItems.json"
local SETTINGS_FILE      = "PhoneIDViewer_Settings.json"
local TELEPORT_FILE      = "PhoneIDViewer_Teleports.json"
local FAV_BUNDLES_FILE   = "PhoneIDViewer_FavBundles.json"
local FAV_AVATAR_FILE    = "PhoneIDViewer_FavAvatarItems.json"

local function saveJSON(f, d)
    pcall(function()
        if writefile then writefile(f, HttpService:JSONEncode(d)) end
    end)
end

local function loadJSON(f)
    local d = {}
    pcall(function()
        if isfile and isfile(f) then
            d = HttpService:JSONDecode(readfile(f))
        end
    end)
    return d
end

-- Load data
local presets       = loadJSON(PRESET_FILE)  or {}
local favPlayerIds  = loadJSON(FAV_FILE)      or {}
local favItems      = loadJSON(FAV_ITEMS_FILE) or {}
local teleportLocs  = loadJSON(TELEPORT_FILE) or {}
local favBundles    = loadJSON(FAV_BUNDLES_FILE) or {}
local favAvatarItems = loadJSON(FAV_AVATAR_FILE) or {}
local appSettings   = loadJSON(SETTINGS_FILE) or {}

if type(favItems)       ~= "table" then favItems = {} end
if type(teleportLocs)   ~= "table" then teleportLocs = {} end
if type(favBundles)     ~= "table" then favBundles = {} end
if type(favAvatarItems) ~= "table" then favAvatarItems = {} end

-- Defaults
local defaults = {
    themeIndex          = 1,
    glowEnabled         = true,
    toastEnabled        = true,
    buttonSounds        = false,
    buttonSoundUrl      = "",
    backgroundMusicUrl  = "",
    autoLockSeconds     = 0,
    clockFormat         = "24",
    passcode            = "2006",
    phoneOpacity        = 1,
    bgColor             = Color3.fromRGB(255, 255, 255),
    bgGradient          = true,
    espEnabled          = true,
    espHideSelf         = true,
}
for k, v in pairs(defaults) do
    if appSettings[k] == nil then appSettings[k] = v end
end

-- FavSet
local favSet = {}
for _, id in ipairs(favPlayerIds) do favSet[tostring(id)] = true end

-- Persist functions
local Storage = {
    presets        = presets,
    favItems       = favItems,
    teleportLocs   = teleportLocs,
    favBundles     = favBundles,
    favAvatarItems = favAvatarItems,
    appSettings    = appSettings,
    favSet         = favSet,
}

function Storage.persistFav()
    local a = {}
    for k in pairs(favSet) do table.insert(a, tonumber(k)) end
    saveJSON(FAV_FILE, a)
end
function Storage.persistFavItems()   saveJSON(FAV_ITEMS_FILE, favItems) end
function Storage.persistTeleport()   saveJSON(TELEPORT_FILE, teleportLocs) end
function Storage.persistSettings()  saveJSON(SETTINGS_FILE, appSettings) end
function Storage.persistPresets()   saveJSON(PRESET_FILE, presets) end
function Storage.persistBundles()   saveJSON(FAV_BUNDLES_FILE, favBundles) end
function Storage.persistAvatarItems() saveJSON(FAV_AVATAR_FILE, favAvatarItems) end

-- Background music
local bgMusicSound = nil
function Storage.updateBackgroundMusic()
    if bgMusicSound then
        bgMusicSound:Stop()
        bgMusicSound:Destroy()
        bgMusicSound = nil
    end
    if appSettings.backgroundMusicUrl and appSettings.backgroundMusicUrl ~= "" then
        bgMusicSound = Instance.new("Sound", game:GetService("SoundService"))
        bgMusicSound.SoundId = appSettings.backgroundMusicUrl
        bgMusicSound.Looped = true
        bgMusicSound.Volume = 0.3
        bgMusicSound:Play()
    end
end
Storage.updateBackgroundMusic()

-- Expose ke global
_G.Storage = Storage
_G.PhoneState.appSettings = appSettings

return Storage