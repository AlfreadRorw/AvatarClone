-- ================================================
-- ICON PREM - Semua Icon Builders (Hitam Putih, No Emoji)
-- ================================================

_G.PremiumIcons = _G.PremiumIcons or {}

local Helpers = _G.Helpers or {}

-- Target (Crosshair)
_G.PremiumIcons.Target = function(p, c)
    local ring = Instance.new("Frame", p)
    ring.Size = UDim2.new(0, 28, 0, 28)
    ring.Position = UDim2.new(0.5, -14, 0.5, -14)
    ring.BackgroundTransparency = 1
    Helpers.stroke(ring, c, 2.5, 0)
    Helpers.corner(ring, 100)
    
    local dot = Instance.new("Frame", p)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    dot.BackgroundColor3 = c
    Helpers.corner(dot, 100)
end

-- Chat (Bubble)
_G.PremiumIcons.Chat = function(p, c)
    local bubble = Instance.new("Frame", p)
    bubble.Size = UDim2.new(0, 28, 0, 20)
    bubble.Position = UDim2.new(0.5, -14, 0.4, -10)
    bubble.BackgroundColor3 = c
    Helpers.corner(bubble, 10)
    
    local tail = Instance.new("Frame", p)
    tail.Size = UDim2.new(0, 8, 0, 8)
    tail.Position = UDim2.new(0.35, -6, 0.55, 2)
    tail.BackgroundColor3 = c
    tail.Rotation = 45
    Helpers.corner(tail, 2)
    
    for i = 1, 3 do
        local dot = Instance.new("Frame", p)
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.Position = UDim2.new(0.5, -9 + (i-1) * 7, 0.4, -2)
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        Helpers.corner(dot, 100)
    end
end

-- Jail (Bars)
_G.PremiumIcons.Jail = function(p, c)
    for i = 1, 4 do
        local bar = Instance.new("Frame", p)
        bar.Size = UDim2.new(0, 3, 0, 30)
        bar.Position = UDim2.new(0.35, -6 + (i-1) * 5, 0.5, -15)
        bar.BackgroundColor3 = c
        Helpers.corner(bar, 1.5)
    end
    
    local top = Instance.new("Frame", p)
    top.Size = UDim2.new(0, 24, 0, 3)
    top.Position = UDim2.new(0.5, -12, 0.2, 0)
    top.BackgroundColor3 = c
    Helpers.corner(top, 1.5)
    
    local bottom = Instance.new("Frame", p)
    bottom.Size = UDim2.new(0, 24, 0, 3)
    bottom.Position = UDim2.new(0.5, -12, 0.7, 0)
    bottom.BackgroundColor3 = c
    Helpers.corner(bottom, 1.5)
end

-- Teleport (Portal)
_G.PremiumIcons.Teleport = function(p, c)
    local outer = Instance.new("Frame", p)
    outer.Size = UDim2.new(0, 26, 0, 26)
    outer.Position = UDim2.new(0.5, -13, 0.5, -13)
    outer.BackgroundTransparency = 1
    Helpers.stroke(outer, c, 2.5, 0)
    Helpers.corner(outer, 100)
    
    local inner = Instance.new("Frame", p)
    inner.Size = UDim2.new(0, 10, 0, 10)
    inner.Position = UDim2.new(0.5, -5, 0.5, -5)
    inner.BackgroundColor3 = c
    Helpers.corner(inner, 100)
end

-- Bling (Diamond)
_G.PremiumIcons.Bling = function(p, c)
    local diamond = Instance.new("Frame", p)
    diamond.Size = UDim2.new(0, 20, 0, 20)
    diamond.Position = UDim2.new(0.5, -10, 0.35, 0)
    diamond.BackgroundColor3 = c
    diamond.Rotation = 45
    Helpers.corner(diamond, 4)
    
    local bottom = Instance.new("Frame", p)
    bottom.Size = UDim2.new(0, 14, 0, 14)
    bottom.Position = UDim2.new(0.5, -7, 0.55, 0)
    bottom.BackgroundColor3 = c
    bottom.Rotation = 45
    Helpers.corner(bottom, 3)
end

-- Fly (Wings)
_G.PremiumIcons.Fly = function(p, c)
    local leftWing = Instance.new("Frame", p)
    leftWing.Size = UDim2.new(0, 14, 0, 20)
    leftWing.Position = UDim2.new(0.3, -7, 0.5, -10)
    leftWing.BackgroundColor3 = c
    leftWing.Rotation = 25
    Helpers.corner(leftWing, 8)
    
    local rightWing = Instance.new("Frame", p)
    rightWing.Size = UDim2.new(0, 14, 0, 20)
    rightWing.Position = UDim2.new(0.7, -7, 0.5, -10)
    rightWing.BackgroundColor3 = c
    rightWing.Rotation = -25
    Helpers.corner(rightWing, 8)
    
    local body = Instance.new("Frame", p)
    body.Size = UDim2.new(0, 8, 0, 24)
    body.Position = UDim2.new(0.5, -4, 0.5, -12)
    body.BackgroundColor3 = c
    Helpers.corner(body, 4)
end

-- Movement (Arrow)
_G.PremiumIcons.Movement = function(p, c)
    local arrow = Instance.new("Frame", p)
    arrow.Size = UDim2.new(0, 16, 0, 4)
    arrow.Position = UDim2.new(0.4, -8, 0.55, -2)
    arrow.BackgroundColor3 = c
    Helpers.corner(arrow, 2)
    
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0, 8, 0, 8)
    head.Position = UDim2.new(0.65, -4, 0.55, -4)
    head.BackgroundColor3 = c
    head.Rotation = 45
    Helpers.corner(head, 2)
end

-- Jumpscare (Ghost)
_G.PremiumIcons.Jumpscare = function(p, c)
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0, 22, 0, 22)
    head.Position = UDim2.new(0.5, -11, 0.35, 0)
    head.BackgroundColor3 = c
    Helpers.corner(head, 10)
    
    local body = Instance.new("Frame", p)
    body.Size = UDim2.new(0, 26, 0, 16)
    body.Position = UDim2.new(0.5, -13, 0.6, 0)
    body.BackgroundColor3 = c
    Helpers.corner(body, 6)
    
    local leftEye = Instance.new("Frame", p)
    leftEye.Size = UDim2.new(0, 4, 0, 4)
    leftEye.Position = UDim2.new(0.4, -2, 0.42, -2)
    leftEye.BackgroundColor3 = Color3.new(1, 1, 1)
    Helpers.corner(leftEye, 100)
    
    local rightEye = Instance.new("Frame", p)
    rightEye.Size = UDim2.new(0, 4, 0, 4)
    rightEye.Position = UDim2.new(0.6, -2, 0.42, -2)
    rightEye.BackgroundColor3 = Color3.new(1, 1, 1)
    Helpers.corner(rightEye, 100)
end

-- Aura (Glow)
_G.PremiumIcons.Aura = function(p, c)
    local outer = Instance.new("Frame", p)
    outer.Size = UDim2.new(0, 28, 0, 28)
    outer.Position = UDim2.new(0.5, -14, 0.5, -14)
    outer.BackgroundTransparency = 0.8
    Helpers.stroke(outer, c, 2, 0)
    Helpers.corner(outer, 100)
    
    local mid = Instance.new("Frame", p)
    mid.Size = UDim2.new(0, 18, 0, 18)
    mid.Position = UDim2.new(0.5, -9, 0.5, -9)
    mid.BackgroundTransparency = 0.6
    Helpers.stroke(mid, c, 2, 0)
    Helpers.corner(mid, 100)
    
    local core = Instance.new("Frame", p)
    core.Size = UDim2.new(0, 8, 0, 8)
    core.Position = UDim2.new(0.5, -4, 0.5, -4)
    core.BackgroundColor3 = c
    Helpers.corner(core, 100)
end

-- Sky (Sun)
_G.PremiumIcons.Sky = function(p, c)
    local sun = Instance.new("Frame", p)
    sun.Size = UDim2.new(0, 18, 0, 18)
    sun.Position = UDim2.new(0.5, -9, 0.45, -9)
    sun.BackgroundColor3 = c
    Helpers.corner(sun, 100)
    
    for i = 0, 7 do
        local angle = math.rad(i * 45)
        local ray = Instance.new("Frame", p)
        ray.Size = UDim2.new(0, 4, 0, 2)
        ray.Position = UDim2.new(0.5 + math.cos(angle) * 0.3, -2, 0.45 + math.sin(angle) * 0.35, -1)
        ray.BackgroundColor3 = c
        ray.Rotation = math.deg(angle)
        Helpers.corner(ray, 1)
    end
end

-- Dex (List)
_G.PremiumIcons.Dex = function(p, c)
    for i = 1, 4 do
        local line = Instance.new("Frame", p)
        line.Size = UDim2.new(0, 26, 0, 3)
        line.Position = UDim2.new(0.5, -13, 0.25 + (i-1) * 0.15, -1.5)
        line.BackgroundColor3 = c
        Helpers.corner(line, 1.5)
    end
end

print("[IconPrem/Premium] Semua icon loaded!")