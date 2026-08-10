local T           = _G.T
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")

local Helpers = {}

function Helpers.corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = o
    return c
end

function Helpers.stroke(o, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or T.Border
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.Parent = o
    return s
end

function Helpers.gradient(o, seq, rot)
    local g = Instance.new("UIGradient")
    g.Color = seq
    g.Rotation = rot or 90
    g.Parent = o
    return g
end

function Helpers.tween(o, p, tm, st)
    TweenService:Create(o, TweenInfo.new(
        tm or 0.25,
        st or Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ), p):Play()
end

function Helpers.pressFX(b)
    local orig = b.Size
    b.MouseButton1Down:Connect(function()
        Helpers.tween(b, {
            Size = UDim2.new(
                orig.X.Scale * 0.94, orig.X.Offset * 0.94,
                orig.Y.Scale * 0.9,  orig.Y.Offset * 0.9
            )
        }, 0.06)
    end)
    b.MouseButton1Up:Connect(function()
        Helpers.tween(b, {Size = orig}, 0.12, Enum.EasingStyle.Back)
    end)
    b.MouseLeave:Connect(function()
        Helpers.tween(b, {Size = orig}, 0.12, Enum.EasingStyle.Back)
    end)
end

function Helpers.copyToClipboard(txt)
    pcall(function() setclipboard(txt) end)
    pcall(function() toclipboard(txt) end)
end

function Helpers.buildToggle(parent, initial, onChange)
    local track = Instance.new("Frame", parent)
    track.Size = UDim2.new(0, 46, 0, 26)
    track.BackgroundColor3 = initial and T.Accent or Color3.fromRGB(180, 180, 180)
    Helpers.corner(track, 100)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = initial
        and UDim2.new(1, -24, 0.5, -11)
        or  UDim2.new(0, 2,   0.5, -11)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Helpers.corner(knob, 100)

    local btn = Instance.new("TextButton", track)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    local state = initial

    btn.MouseButton1Click:Connect(function()
        state = not state
        Helpers.tween(track, {
            BackgroundColor3 = state and T.Accent or Color3.fromRGB(180, 180, 180)
        }, 0.15)
        Helpers.tween(knob, {
            Position = state
                and UDim2.new(1, -24, 0.5, -11)
                or  UDim2.new(0, 2,   0.5, -11)
        }, 0.18, Enum.EasingStyle.Back)
        onChange(state)
    end)

    return track
end

-- Dynamic notification queue
local iid = 0
local notifyQueue = {}
local isNotifying = false

local function processNotify()
    if #notifyQueue == 0 then isNotifying = false return end
    isNotifying = true
    local info = table.remove(notifyQueue, 1)

    local di  = _G.PhoneDI
    local dil = _G.PhoneDIL
    local dis = _G.PhoneDIS
    if not di or not dil then
        isNotifying = false
        return
    end

    iid = iid + 1
    local my = iid
    dil.Text = info.text
    dil.TextColor3 = Color3.new(1, 1, 1)
    dil.TextTransparency = 0
    dis.Color = info.color or Color3.new(1, 1, 1)

    local textWidth = math.min(240, 12 * #info.text + 40)
    Helpers.tween(di, {
        Size = UDim2.new(0, textWidth, 0, 32),
        Position = UDim2.new(0.5, -textWidth / 2, 0, 2)
    }, 0.25, Enum.EasingStyle.Back)

    task.delay(1.8, function()
        if iid ~= my then return end
        Helpers.tween(di, {
            Size = UDim2.new(0, 90, 0, 24),
            Position = UDim2.new(0.5, -45, 0, 4)
        }, 0.25)
        task.delay(0.3, function()
            if iid == my then
                dil.Text = ""
                processNotify()
            end
        end)
    end)
end

function Helpers.showDynamicNotification(text, color)
    local appSettings = _G.PhoneState and _G.PhoneState.appSettings
    if appSettings and not appSettings.toastEnabled then return end
    table.insert(notifyQueue, {text = text, color = color})
    if not isNotifying then processNotify() end
end

-- Volume
function Helpers.applyVolumeEverywhere(vol)
    _G.PhoneState.globalVolumeLevel = vol
    pcall(function() game:GetService("SoundService").MasterVolume = vol end)
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Sound") then
            pcall(function() obj.Volume = vol end)
        end
    end
end

game.DescendantAdded:Connect(function(obj)
    if obj:IsA("Sound") then
        task.wait()
        pcall(function()
            obj.Volume = _G.PhoneState.globalVolumeLevel
        end)
    end
end)

_G.Helpers = Helpers
return Helpers