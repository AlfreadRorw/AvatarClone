local HttpService = game:GetService("HttpService")

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

local function loadJSON(file)
    local data = {}
    pcall(function()
        if isfile and isfile(file) then
            data = HttpService:JSONDecode(readfile(file))
        end
    end)
    return type(data) == "table" and data or {}
end

local function saveJSON(file, data)
    pcall(function()
        if writefile then
            writefile(file, HttpService:JSONEncode(data))
        end
    end)
end

Storage.presets = loadJSON(FILES.PRESET)
Storage.favItems = loadJSON(FILES.FAV_ITEMS)
Storage.favEmotes = loadJSON(FILES.FAV_EMOTES)
Storage.favBundles = loadJSON(FILES.FAV_BUNDLES)
Storage.teleportLocations = loadJSON(FILES.TELEPORT)
Storage.appSettings = loadJSON(FILES.SETTINGS)

local favPlayerIds = loadJSON(FILES.FAV)
Storage.favSet = {}
for _, id in ipairs(favPlayerIds) do
    Storage.favSet[tostring(id)] = true
end

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
}

for k, v in pairs(defaults) do
    if Storage.appSettings[k] == nil then
        Storage.appSettings[k] = v
    end
end

function Storage.persistFav()
    local ids = {}
    for k in pairs(Storage.favSet) do
        table.insert(ids, tonumber(k))
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