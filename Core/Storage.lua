-- ================================================
-- STORAGE - Safe JSON with Backup
-- ================================================

local HttpService = game:GetService("HttpService")
local Config = _G.Config or {}
local DEBUG = Config.DEBUG or false

local function log(...)
    if DEBUG then
        print("[Storage]", ...)
    end
end

local Storage = {
    presets = {},
    favSet = {},
    favItems = {},
    favEmotes = {},
    favBundles = {},
    teleportLocations = {},
    appSettings = {},
}

local FILES = {
    PRESET = "PhoneIDViewer_Presets.json",
    FAV = "PhoneIDViewer_FavPlayers.json",
    FAV_ITEMS = "PhoneIDViewer_FavItems.json",
    FAV_EMOTES = "PhoneIDViewer_FavEmotes.json",
    FAV_BUNDLES = "PhoneIDViewer_FavBundles.json",
    TELEPORT = "PhoneIDViewer_Teleports.json",
    SETTINGS = "PhoneIDViewer_Settings.json",
}

local function hasFilesystem()
    return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
end

local function loadJSON(file)
    if not hasFilesystem() then
        return {}
    end
    
    if not isfile(file) then
        return {}
    end
    
    local ok, content = pcall(function()
        return readfile(file)
    end)
    
    if not ok then
        log("Read failed:", file, content)
        return {}
    end
    
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if not decodeOk then
        -- Corrupt file: backup and reset
        log("JSON decode failed:", file, data)
        pcall(function()
            writefile(file .. ".corrupt", content)
        end)
        pcall(function()
            delfile(file)
        end)
        return {}
    end
    
    return type(data) == "table" and data or {}
end

local function saveJSON(file, data)
    if not hasFilesystem() then
        return false
    end
    
    local ok, err = pcall(function()
        writefile(file, HttpService:JSONEncode(data))
    end)
    
    if not ok then
        log("Write failed:", file, err)
        return false
    end
    
    return true
end

-- Load all
Storage.presets = loadJSON(FILES.PRESET)
Storage.favItems = loadJSON(FILES.FAV_ITEMS)
Storage.favEmotes = loadJSON(FILES.FAV_EMOTES)
Storage.favBundles = loadJSON(FILES.FAV_BUNDLES)
Storage.teleportLocations = loadJSON(FILES.TELEPORT)
Storage.appSettings = loadJSON(FILES.SETTINGS)

-- Convert fav players to set
local favPlayerIds = loadJSON(FILES.FAV)
Storage.favSet = {}
for _, id in ipairs(favPlayerIds) do
    local numericId = tonumber(id)
    if numericId then
        Storage.favSet[tostring(numericId)] = true
    end
end

-- Defaults
local defaults = {
    wallpaperUrl = "",
    themeIndex = 1,
    glowEnabled = true,
    toastEnabled = true,
    buttonSounds = false,
    buttonSoundUrl = "",
    backgroundMusicUrl = "",
    autoLockSeconds = 0,
    clockFormat = "24",
    passcode = "2006",
    phoneOpacity = 1,
    bgColor = Color3.fromRGB(255, 255, 255),
    bgGradient = true,
    savedKey = "",
}

for k, v in pairs(defaults) do
    if Storage.appSettings[k] == nil then
        Storage.appSettings[k] = v
    end
end

Storage.persistSettings()

function Storage.persistFav()
    local ids = {}
    for k in pairs(Storage.favSet) do
        local numericId = tonumber(k)
        if numericId then
            table.insert(ids, numericId)
        end
    end
    saveJSON(FILES.FAV, ids)
end

function Storage.persistFavItems()
    saveJSON(FILES.FAV_ITEMS, Storage.favItems)
end

function Storage.persistFavEmotes()
    saveJSON(FILES.FAV_EMOTES, Storage.favEmotes)
end

function Storage.persistFavBundles()
    saveJSON(FILES.FAV_BUNDLES, Storage.favBundles)
end

function Storage.persistPresets()
    saveJSON(FILES.PRESET, Storage.presets)
end

function Storage.persistTeleportLocations()
    saveJSON(FILES.TELEPORT, Storage.teleportLocations)
end

function Storage.persistSettings()
    saveJSON(FILES.SETTINGS, Storage.appSettings)
end

return Storage