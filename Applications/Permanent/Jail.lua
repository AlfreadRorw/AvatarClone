-- ================================================
-- PERMANENT/JAIL.LUA - Jail & Toggle Effects
-- ================================================

local Services = _G.Services
local LocalPlayer = _G.LocalPlayer
local Firebase = _G.Firebase
local Helpers = _G.Helpers or {}

local function openJailApp(contentArea)
    local State = _G.PremiumState
    
    local P = {
        bgCard2 = Color3.fromRGB(26, 26, 34),
        accent = Color3.fromRGB(168, 110, 255),
        green = Color3.fromRGB(80, 220, 150),
        red = Color3.fromRGB(255, 90, 100),
        orange = Color3.fromRGB(230, 126, 34),
        blue = Color3.fromRGB(52, 152, 219),
        textMain = Color3.fromRGB(240, 240, 245),
        textSub = Color3.fromRGB(150, 150, 165),
        border = Color3.fromRGB(45, 45, 58),
    }

    local COMMAND_COOLDOWN = 0.5
    local lastCommandTime = 0

    local function sendTroll(action)
        if not State.selectedTargetId then
            _G.showDynamicNotification("Pilih target dulu!", P.red)
            return
        end
        if os.clock() - lastCommandTime < COMMAND_COOLDOWN then return end
        lastCommandTime = os.clock()
        
        pcall(function()
            Firebase.PushCommand(State.selectedTargetId, {
                type = "troll_action",
                action = action,
                timestamp = os.time(),
            })
        end)
    end

    local function addToggle(title, desc, actionOn, actionOff, color)
        local card = Instance.new("Frame", contentArea)
        card.Size = UDim2.new(0.95, 0, 0, 64)
        card.BackgroundColor3 = P.bgCard2
        Helpers.corner(card, 12)
        Helpers.stroke(card, P.border, 1, 0.4)

        local tLbl = Instance.new("TextLabel", card)
        tLbl.Size = UDim2.new(1, -80, 0, 20)
        tLbl.Position = UDim2.new(0, 12, 0, 6)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = title
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 12
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.TextColor3 = P.textMain

        local dLbl = Instance.new("TextLabel", card)
        dLbl.Size = UDim2.new(1, -80, 0, 30)
        dLbl.Position = UDim2.new(0, 12, 0, 26)
        dLbl.BackgroundTransparency = 1
        dLbl.Text = desc
        dLbl.Font = Enum.Font.Gotham
        dLbl.TextSize = 9
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.TextWrapped = true
        dLbl.TextColor3 = P.textSub

        local isOn = false
        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, 64, 0, 32)
        btn.Position = UDim2.new(1, -74, 0.5, -16)
        btn.BackgroundColor3 = color
        btn.Text = "OFF"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        Helpers.corner(btn, 8)
        if Helpers.pressFX then Helpers.pressFX(btn) end

        btn.MouseButton1Click:Connect(function()
            isOn = not isOn
            btn.Text = isOn and "ON" or "OFF"
            btn.BackgroundColor3 = isOn and P.green or color
            sendTroll(isOn and actionOn or actionOff)
        end)
    end

    -- Jail toggles
    addToggle("Jail", "Kurung target dalam kotak", "jail", "unjail", P.orange)
    addToggle("Freeze", "Bekukan target", "freeze", "unfreeze", P.blue)
    addToggle("Blind", "Gelapkan layar target", "blind", "unblind", Color3.fromRGB(44, 62, 80))
    addToggle("Blur", "Blur pandangan target", "blur", "unblur", Color3.fromRGB(142, 68, 173))

    -- Instant actions
    local instantLbl = Instance.new("TextLabel", contentArea)
    instantLbl.Size = UDim2.new(0.95, 0, 0, 22)
    instantLbl.BackgroundTransparency = 1
    instantLbl.Text = "INSTANT ACTIONS:"
    instantLbl.TextColor3 = P.accent
    instantLbl.Font = Enum.Font.GothamBold
    instantLbl.TextSize = 10
    instantLbl.TextXAlignment = Enum.TextXAlignment.Left

    local instantGrid = Instance.new("Frame", contentArea)
    instantGrid.Size = UDim2.new(0.95, 0, 0, 0)
    instantGrid.AutomaticSize = Enum.AutomaticSize.Y
    instantGrid.BackgroundTransparency = 1

    local gridLayout = Instance.new("UIGridLayout", instantGrid)
    gridLayout.CellSize = UDim2.new(0.48, 0, 0, 38)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)

    local function addInstant(name, action, color)
        local btn = Instance.new("TextButton", instantGrid)
        btn.BackgroundColor3 = color
        btn.Text = name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        Helpers.corner(btn, 8)
        if Helpers.pressFX then Helpers.pressFX(btn) end
        btn.MouseButton1Click:Connect(function()
            sendTroll(action)
        end)
    end

    addInstant("Kill", "kill", Color3.fromRGB(231, 76, 60))
    addInstant("Fling", "fling", Color3.fromRGB(155, 89, 182))
    addInstant("Noclip", "noclip", Color3.fromRGB(149, 165, 166))
    addInstant("Remove Limbs", "nolimbs", Color3.fromRGB(192, 57, 43))
end

_G.PremiumSubApps = _G.PremiumSubApps or {}
_G.PremiumSubApps["Jail"] = {
    name = "Jail",
    iconName = "Jail",
    loadFunc = openJailApp,
}

print("[Permanent/Jail] Loaded!")