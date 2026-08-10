local Players   = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Config = {
    -- Tool
    TOOL_NAME       = "Phone",
    PASSCODE        = "2006",
    CLONE_BATCH_SIZE = 5,
    CLONE_DELAY     = 6,
    REMOTE_PATH     = "Remotes.Command.CommandEvent",

    -- Dev
    IS_DEV = (LocalPlayer.Name:lower() == "alfreadr0rw"),

    -- Telegram
    TELEGRAM_ENABLED = true,
    TELEGRAM_TOKEN   = "8934376819:AAHsmldpVfV4LRPdhOXEy8hjA9wqMXmWWl4",
    TELEGRAM_CHAT_ID = "5789407694",

    -- Firebase
    FIREBASE_URL = "https://phone-id-viewer-default-rtdb.asia-southeast1.firebasedatabase.app",
    FIREBASE_KEY = "AIzaSyCGYiMvdt8v4DP96dUny8xFDRD6w3T1c80",

    -- Map lock
    ALLOWED_PLACE_IDS = {
        133943904733338,
        7041939546,
    },

    -- Targets (ESP)
    TARGETS = {
        {username = "AlfreadR0rw",       text = "DEV",    color = Color3.fromRGB(255, 200, 50)},
        {username = "matchapii04",        text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "akbarfbrynn",        text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "BLAZEBUBz",          text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "LexxSugar7",         text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Dap_Mahatir",        text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Jv4n00X",            text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Hx8shve3",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Chinatsu0263",       text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "dimasbani_9",        text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "IronHuijsen",        text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "KooJagoo",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "rstuaj1",            text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "mouri01045",         text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "stevalone7",         text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "ziroadalahpokoknya", text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "AlbernTheGreat7",    text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "SweetyCoconut3",     text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "neoo290904",         text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "pororo_iki",         text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "syahidhc",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "cyaa_floiyrine",     text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "DzyanV2",            text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "ManSpicy",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Oruzukii",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "jeyocal",            text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "yellbubb",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "Xetan01",            text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
        {username = "xkillabe",           text = "MEMBER", color = Color3.fromRGB(80, 150, 255)},
    },
}

-- Global state
_G.PhoneState = {
    selectedPlayer   = nil,
    isLocked         = true,
    passEntry        = "",
    isCloning        = false,
    lastAutoLockTime = tick(),
    globalVolumeLevel = 1,
    openedConversation = nil,
    favSelectedTab   = "Players",
    avatarItemsSelectedTab = "Favorites",
    playerLookupData = {},
    appSettings      = nil, -- diisi oleh Storage
}

return Config