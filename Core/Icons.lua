-- Core/Icons.lua
local T = _G.T
local Helpers = _G.Helpers

local iconBuilders = {}

iconBuilders.Players = function(p, c)
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0, 20, 0, 20)
    head.Position = UDim2.new(0.5, -10, 0.2, 0)
    head.BackgroundColor3 = c
    Helpers.corner(head, 100)
    
    local body = Instance.new("Frame", p)
    body.Size = UDim2.new(0, 34, 0, 20)
    body.Position = UDim2.new(0.5, -17, 0.58, 0)
    body.BackgroundColor3 = c
    Helpers.corner(body, 12)
end

iconBuilders.Clone = function(p, c)
    local back = Instance.new("Frame", p)
    back.Size = UDim2.new(0, 34, 0, 34)
    back.Position = UDim2.new(0.5, -22, 0.22, 0)
    back.BackgroundColor3 = c
    back.BackgroundTransparency = 0.6
    Helpers.corner(back, 8)
    Helpers.stroke(back, c, 2, 0.4)
    
    local front = Instance.new("Frame", p)
    front.Size = UDim2.new(0, 34, 0, 34)
    front.Position = UDim2.new(0.5, -12, 0.35, 0)
    front.BackgroundColor3 = c
    Helpers.corner(front, 8)
    Helpers.stroke(front, Color3.new(0, 0, 0), 1, 0.4)
end

iconBuilders.Preset = function(p, c)
    local box = Instance.new("Frame", p)
    box.Size = UDim2.new(0, 38, 0, 30)
    box.Position = UDim2.new(0.5, -19, 0.45, 0)
    box.BackgroundColor3 = c
    Helpers.corner(box, 6)
    
    local lid = Instance.new("Frame", p)
    lid.Size = UDim2.new(0, 16, 0, 8)
    lid.Position = UDim2.new(0.5, -19, 0.35, 0)
    lid.BackgroundColor3 = c
    Helpers.corner(lid, 4)
end

iconBuilders.Favs = function(p, c)
    local h = Instance.new("Frame", p)
    h.Size = UDim2.new(0, 36, 0, 8)
    h.Position = UDim2.new(0.5, -18, 0.5, -4)
    h.BackgroundColor3 = c
    Helpers.corner(h, 4)
    
    local v = Instance.new("Frame", p)
    v.Size = UDim2.new(0, 8, 0, 36)
    v.Position = UDim2.new(0.5, -4, 0.5, -18)
    v.BackgroundColor3 = c
    Helpers.corner(v, 4)
end

iconBuilders.Volume = function(p, c)
    local s = Instance.new("Frame", p)
    s.Size = UDim2.new(0, 30, 0, 20)
    s.Position = UDim2.new(0.5, -15, 0.3, 0)
    s.BackgroundColor3 = c
    Helpers.corner(s, 4)
end

iconBuilders.Items = function(p, c)
    local b = Instance.new("Frame", p)
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(0.5, -14, 0.25, 0)
    b.BackgroundColor3 = c
    Helpers.corner(b, 6)
    
    local t = Instance.new("TextLabel", b)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = "ID"
    t.TextColor3 = T.OnAccent or Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 14
end

iconBuilders.Profile = function(p, c)
    local h = Instance.new("Frame", p)
    h.Size = UDim2.new(0, 22, 0, 22)
    h.Position = UDim2.new(0.5, -11, 0.15, 0)
    h.BackgroundColor3 = c
    Helpers.corner(h, 100)
    
    local b = Instance.new("Frame", p)
    b.Size = UDim2.new(0, 32, 0, 18)
    b.Position = UDim2.new(0.5, -16, 0.6, 0)
    b.BackgroundColor3 = c
    Helpers.corner(b, 8)
end

iconBuilders.Reset = function(p, c)
    local a = Instance.new("Frame", p)
    a.Size = UDim2.new(0, 30, 0, 30)
    a.Position = UDim2.new(0.5, -15, 0.2, 0)
    a.BackgroundColor3 = c
    Helpers.corner(a, 100)
    
    local t = Instance.new("TextLabel", a)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = "R"
    t.TextColor3 = T.OnAccent or Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 20
end

iconBuilders.Size = function(p, c)
    local r = Instance.new("Frame", p)
    r.Size = UDim2.new(0, 26, 0, 26)
    r.Position = UDim2.new(0.5, -13, 0.2, 0)
    r.BackgroundColor3 = c
    Helpers.corner(r, 100)
    
    local t = Instance.new("TextLabel", r)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = "S"
    t.TextColor3 = T.OnAccent or Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 16
end

iconBuilders.Friends = function(p, c)
    for i = 1, 2 do
        local head = Instance.new("Frame", p)
        head.Size = UDim2.new(0, 14, 0, 14)
        head.Position = UDim2.new(0.5, -18 + (i-1) * 22, 0.3, 0)
        head.BackgroundColor3 = c
        Helpers.corner(head, 100)
        
        local body = Instance.new("Frame", p)
        body.Size = UDim2.new(0, 28, 0, 16)
        body.Position = UDim2.new(0.5, -20 + (i-1) * 22, 0.6, 0)
        body.BackgroundColor3 = c
        Helpers.corner(body, 8)
    end
end

iconBuilders.Server = function(p, c)
    local r = Instance.new("Frame", p)
    r.Size = UDim2.new(0, 34, 0, 24)
    r.Position = UDim2.new(0.5, -17, 0.35, 0)
    r.BackgroundColor3 = c
    Helpers.corner(r, 6)
    
    for i = 1, 3 do
        local d = Instance.new("Frame", p)
        d.Size = UDim2.new(0, 6, 0, 6)
        d.Position = UDim2.new(0.5 - 9 + 6 * i, 0, 0.55, 0)
        d.BackgroundColor3 = T.BG or Color3.fromRGB(255, 255, 255)
        Helpers.corner(d, 100)
    end
end

iconBuilders.Teleport = function(p, c)
    local r = Instance.new("Frame", p)
    r.Size = UDim2.new(0, 30, 0, 30)
    r.Position = UDim2.new(0.5, -15, 0.3, 0)
    r.BackgroundColor3 = c
    Helpers.corner(r, 100)
    
    local t = Instance.new("TextLabel", r)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = "TP"
    t.TextColor3 = T.OnAccent or Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 14
end

iconBuilders.Settings = function(p, c)
    local g = Instance.new("Frame", p)
    g.Size = UDim2.new(0, 30, 0, 30)
    g.Position = UDim2.new(0.5, -15, 0.2, 0)
    g.BackgroundColor3 = c
    Helpers.corner(g, 100)
    
    local s = Instance.new("TextLabel", g)
    s.Size = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.Text = "⚙"
    s.TextColor3 = T.OnAccent or Color3.new(1, 1, 1)
    s.Font = Enum.Font.GothamBlack
    s.TextSize = 22
end

iconBuilders.Command = function(p, c)
    local window = Instance.new("Frame", p)
    window.Size = UDim2.new(0, 28, 0, 22)
    window.Position = UDim2.new(0.5, -14, 0.3, 0)
    window.BackgroundColor3 = c
    Helpers.corner(window, 5)
    
    local cursor = Instance.new("Frame", window)
    cursor.Size = UDim2.new(0, 2, 0, 8)
    cursor.Position = UDim2.new(0, 6, 0, 8)
    cursor.BackgroundColor3 = Color3.new(1, 1, 1)
    Helpers.corner(cursor, 1)
end

iconBuilders.Bundle = function(p, c)
    local box = Instance.new("Frame", p)
    box.Size = UDim2.new(0, 28, 0, 28)
    box.Position = UDim2.new(0.5, -14, 0.28, 0)
    box.BackgroundColor3 = c
    Helpers.corner(box, 6)
    
    local ribbon = Instance.new("Frame", p)
    ribbon.Size = UDim2.new(0, 32, 0, 8)
    ribbon.Position = UDim2.new(0.5, -16, 0.42, 0)
    ribbon.BackgroundColor3 = c
    Helpers.corner(ribbon, 3)
end

iconBuilders.Lookup = function(p, c)
    local circle = Instance.new("Frame", p)
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = UDim2.new(0.5, -13, 0.26, 0)
    circle.BackgroundTransparency = 1
    Helpers.stroke(circle, c, 3, 0)
    Helpers.corner(circle, 100)
    
    local handle = Instance.new("Frame", p)
    handle.Size = UDim2.new(0, 3, 0, 12)
    handle.Position = UDim2.new(0.5, 5, 0.5, 3)
    handle.BackgroundColor3 = c
    handle.Rotation = 45
    Helpers.corner(handle, 2)
end

iconBuilders.ServerJoiner = function(p, c)
    local rack = Instance.new("Frame", p)
    rack.Size = UDim2.new(0, 22, 0, 18)
    rack.Position = UDim2.new(0.5, -11, 0.32, 0)
    rack.BackgroundColor3 = c
    Helpers.corner(rack, 5)
    
    for i = 1, 2 do
        local light = Instance.new("Frame", p)
        light.Size = UDim2.new(0, 4, 0, 4)
        light.Position = UDim2.new(0.5 - 5 + i * 5, 0, 0.5, -2)
        light.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        Helpers.corner(light, 100)
    end
end

iconBuilders.WhoOnline = function(p, c)
    local ring = Instance.new("Frame", p)
    ring.Size = UDim2.new(0, 28, 0, 28)
    ring.Position = UDim2.new(0.5, -14, 0.22, 0)
    ring.BackgroundTransparency = 1
    Helpers.stroke(ring, c, 2.5, 0)
    Helpers.corner(ring, 100)
    
    local dot = Instance.new("Frame", p)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 0.38, 0)
    dot.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
    Helpers.corner(dot, 100)
end

iconBuilders.Message = function(p, c)
    -- Lingkaran hijau WA
    local bg = Instance.new("Frame", p)
    bg.Size = UDim2.new(0, 26, 0, 26)
    bg.Position = UDim2.new(0.5, -13, 0.28, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    Helpers.corner(bg, 100)
    
    -- Ikon telepon putih
    local phone = Instance.new("Frame", bg)
    phone.Size = UDim2.new(0, 12, 0, 7)
    phone.Position = UDim2.new(0.5, -6, 0.5, -3)
    phone.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Helpers.corner(phone, 4)
    
    local handle = Instance.new("Frame", bg)
    handle.Size = UDim2.new(0, 4, 0, 4)
    handle.Position = UDim2.new(0.5, -2, 0.5, 3)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Rotation = 45
    Helpers.corner(handle, 2)
end

return iconBuilders