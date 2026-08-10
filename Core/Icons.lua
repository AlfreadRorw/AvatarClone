local T       = _G.T
local Helpers = _G.Helpers

local iconBuilders = {}

iconBuilders.Players = function(p, c)
    local size = 0.85
    local p1Head = Instance.new("Frame", p)
    p1Head.Size = UDim2.new(0, 11*size, 0, 11*size)
    p1Head.Position = UDim2.new(0.5, -13*size, 0.32, 0)
    p1Head.BackgroundColor3 = c
    p1Head.BackgroundTransparency = 0.35
    Helpers.corner(p1Head, 100)

    local p1Body = Instance.new("Frame", p)
    p1Body.Size = UDim2.new(0, 20*size, 0, 15*size)
    p1Body.Position = UDim2.new(0.5, -18*size, 0.55, 0)
    p1Body.BackgroundColor3 = c
    p1Body.BackgroundTransparency = 0.35
    Helpers.corner(p1Body, 9)

    local p2Head = Instance.new("Frame", p)
    p2Head.Size = UDim2.new(0, 12*size, 0, 12*size)
    p2Head.Position = UDim2.new(0.5, 3*size, 0.27, 0)
    p2Head.BackgroundColor3 = c
    Helpers.corner(p2Head, 100)

    local p2Body = Instance.new("Frame", p)
    p2Body.Size = UDim2.new(0, 22*size, 0, 16*size)
    p2Body.Position = UDim2.new(0.5, 1*size, 0.52, 0)
    p2Body.BackgroundColor3 = c
    Helpers.corner(p2Body, 10)
end

iconBuilders.Clone = function(p, c)
    local backCard = Instance.new("Frame", p)
    backCard.Size = UDim2.new(0, 30, 0, 30)
    backCard.Position = UDim2.new(0.5, -22, 0.3, 0)
    backCard.BackgroundColor3 = c
    backCard.BackgroundTransparency = 0.6
    Helpers.corner(backCard, 8)
    Helpers.stroke(backCard, c, 1.5, 0.5)

    local frontCard = Instance.new("Frame", p)
    frontCard.Size = UDim2.new(0, 30, 0, 30)
    frontCard.Position = UDim2.new(0.5, -10, 0.4, 0)
    frontCard.BackgroundColor3 = c
    Helpers.corner(frontCard, 8)

    local highlight = Instance.new("Frame", frontCard)
    highlight.Size = UDim2.new(0, 8, 0, 2)
    highlight.Position = UDim2.new(0, 6, 0, 5)
    highlight.BackgroundColor3 = Color3.new(1,1,1)
    highlight.BackgroundTransparency = 0.6
    Helpers.corner(highlight, 1)
end

iconBuilders.Body = function(p, c)
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0,13,0,13)
    head.Position = UDim2.new(0.5,-6,0.17,0)
    head.BackgroundColor3 = c
    Helpers.corner(head, 100)

    local torso = Instance.new("Frame", p)
    torso.Size = UDim2.new(0,20,0,22)
    torso.Position = UDim2.new(0.5,-10,0.4,0)
    torso.BackgroundColor3 = c
    Helpers.corner(torso, 8)

    local leftLeg = Instance.new("Frame", p)
    leftLeg.Size = UDim2.new(0,7,0,13)
    leftLeg.Position = UDim2.new(0.5,-9,0.68,0)
    leftLeg.BackgroundColor3 = c
    Helpers.corner(leftLeg, 3)

    local rightLeg = Instance.new("Frame", p)
    rightLeg.Size = UDim2.new(0,7,0,13)
    rightLeg.Position = UDim2.new(0.5,2,0.68,0)
    rightLeg.BackgroundColor3 = c
    Helpers.corner(rightLeg, 3)
end

iconBuilders.Accs = function(p, c)
    local leftLens = Instance.new("Frame", p)
    leftLens.Size = UDim2.new(0,16,0,16)
    leftLens.Position = UDim2.new(0.5,-20,0.37,0)
    leftLens.BackgroundColor3 = Color3.new(1,1,1)
    leftLens.BackgroundTransparency = 0.15
    Helpers.corner(leftLens, 8)
    Helpers.stroke(leftLens, c, 2.5, 0)

    local rightLens = Instance.new("Frame", p)
    rightLens.Size = UDim2.new(0,16,0,16)
    rightLens.Position = UDim2.new(0.5,4,0.37,0)
    rightLens.BackgroundColor3 = Color3.new(1,1,1)
    rightLens.BackgroundTransparency = 0.15
    Helpers.corner(rightLens, 8)
    Helpers.stroke(rightLens, c, 2.5, 0)

    local bridge = Instance.new("Frame", p)
    bridge.Size = UDim2.new(0,8,0,3)
    bridge.Position = UDim2.new(0.5,-4,0.43,0)
    bridge.BackgroundColor3 = c
    Helpers.corner(bridge, 2)
end

iconBuilders.Preset = function(p, c)
    local box = Instance.new("Frame", p)
    box.Size = UDim2.new(0,30,0,22)
    box.Position = UDim2.new(0.5,-15,0.5,0)
    box.BackgroundColor3 = c
    Helpers.corner(box, 6)

    local lid = Instance.new("Frame", p)
    lid.Size = UDim2.new(0,34,0,9)
    lid.Position = UDim2.new(0.5,-17,0.36,0)
    lid.BackgroundColor3 = c
    Helpers.corner(lid, 4)

    local label = Instance.new("Frame", box)
    label.Size = UDim2.new(0,14,0,7)
    label.Position = UDim2.new(0.5,-7,0.55,0)
    label.BackgroundColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 0.5
    Helpers.corner(label, 3)
end

iconBuilders.Favs = function(p, c)
    local hBar = Instance.new("Frame", p)
    hBar.Size = UDim2.new(0,32,0,7)
    hBar.Position = UDim2.new(0.5,-16,0.5,-3)
    hBar.BackgroundColor3 = c
    Helpers.corner(hBar, 3)

    local vBar = Instance.new("Frame", p)
    vBar.Size = UDim2.new(0,7,0,32)
    vBar.Position = UDim2.new(0.5,-3,0.5,-16)
    vBar.BackgroundColor3 = c
    Helpers.corner(vBar, 3)

    local gem = Instance.new("Frame", p)
    gem.Size = UDim2.new(0,10,0,10)
    gem.Position = UDim2.new(0.5,-5,0.5,-5)
    gem.BackgroundColor3 = c
    Helpers.corner(gem, 100)

    local gemInner = Instance.new("Frame", gem)
    gemInner.Size = UDim2.new(0,5,0,5)
    gemInner.Position = UDim2.new(0.5,-2,0.5,-2)
    gemInner.BackgroundColor3 = Color3.new(1,1,1)
    Helpers.corner(gemInner, 100)
end

iconBuilders.Volume = function(p, c)
    local speaker = Instance.new("Frame", p)
    speaker.Size = UDim2.new(0,20,0,16)
    speaker.Position = UDim2.new(0.5,-10,0.37,0)
    speaker.BackgroundColor3 = c
    Helpers.corner(speaker, 4)

    for i = 1, 3 do
        local w = Instance.new("Frame", p)
        w.Size = UDim2.new(0,3,0,8+(i*3))
        w.Position = UDim2.new(0.5,12+(i*5),0.38+(16-(8+(i*3)))/56,0)
        w.BackgroundColor3 = c
        w.BackgroundTransparency = i*0.15
        Helpers.corner(w, 1)
    end
end

iconBuilders.Items = function(p, c)
    local bag = Instance.new("Frame", p)
    bag.Size = UDim2.new(0,26,0,26)
    bag.Position = UDim2.new(0.5,-13,0.3,0)
    bag.BackgroundColor3 = c
    Helpers.corner(bag, 7)

    local flap = Instance.new("Frame", p)
    flap.Size = UDim2.new(0,22,0,9)
    flap.Position = UDim2.new(0.5,-11,0.24,0)
    flap.BackgroundColor3 = c
    Helpers.corner(flap, 4)

    local pocket = Instance.new("Frame", bag)
    pocket.Size = UDim2.new(0,12,0,10)
    pocket.Position = UDim2.new(0.5,-6,0.45,0)
    pocket.BackgroundColor3 = Color3.new(1,1,1)
    pocket.BackgroundTransparency = 0.5
    Helpers.corner(pocket, 3)
end

iconBuilders.Profile = function(p, c)
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0,18,0,18)
    head.Position = UDim2.new(0.5,-9,0.24,0)
    head.BackgroundColor3 = c
    Helpers.corner(head, 100)

    local card = Instance.new("Frame", p)
    card.Size = UDim2.new(0,30,0,20)
    card.Position = UDim2.new(0.5,-15,0.56,0)
    card.BackgroundColor3 = c
    Helpers.corner(card, 5)

    local photo = Instance.new("Frame", card)
    photo.Size = UDim2.new(0,14,0,12)
    photo.Position = UDim2.new(0,3,0.5,-6)
    photo.BackgroundColor3 = Color3.new(1,1,1)
    photo.BackgroundTransparency = 0.35
    Helpers.corner(photo, 3)
end

iconBuilders.Command = function(p, c)
    local window = Instance.new("Frame", p)
    window.Size = UDim2.new(0,28,0,22)
    window.Position = UDim2.new(0.5,-14,0.3,0)
    window.BackgroundColor3 = c
    Helpers.corner(window, 5)

    local titleBar = Instance.new("Frame", window)
    titleBar.Size = UDim2.new(1,0,0,5)
    titleBar.BackgroundColor3 = Color3.new(1,1,1)
    titleBar.BackgroundTransparency = 0.5
    Helpers.corner(titleBar, 3)

    local cursor = Instance.new("Frame", window)
    cursor.Size = UDim2.new(0,2,0,8)
    cursor.Position = UDim2.new(0,6,0,8)
    cursor.BackgroundColor3 = Color3.new(1,1,1)
    Helpers.corner(cursor, 1)

    local line1 = Instance.new("Frame", window)
    line1.Size = UDim2.new(0,10,0,2)
    line1.Position = UDim2.new(0,10,0,10)
    line1.BackgroundColor3 = Color3.new(1,1,1)
    line1.BackgroundTransparency = 0.4
    Helpers.corner(line1, 1)
end

iconBuilders.Size = function(p, c)
    local outerSquare = Instance.new("Frame", p)
    outerSquare.Size = UDim2.new(0,26,0,26)
    outerSquare.Position = UDim2.new(0.5,-13,0.25,0)
    outerSquare.BackgroundColor3 = c
    outerSquare.BackgroundTransparency = 0.15
    Helpers.corner(outerSquare, 5)
    Helpers.stroke(outerSquare, c, 2, 0)

    local innerSquare = Instance.new("Frame", p)
    innerSquare.Size = UDim2.new(0,14,0,14)
    innerSquare.Position = UDim2.new(0.5,-7,0.42,0)
    innerSquare.BackgroundColor3 = Color3.new(1,1,1)
    Helpers.corner(innerSquare, 3)
end

iconBuilders.Friends = function(p, c)
    local p1Head = Instance.new("Frame", p)
    p1Head.Size = UDim2.new(0,11,0,11)
    p1Head.Position = UDim2.new(0.5,-17,0.3,0)
    p1Head.BackgroundColor3 = c
    Helpers.corner(p1Head, 100)

    local p1Body = Instance.new("Frame", p)
    p1Body.Size = UDim2.new(0,16,0,13)
    p1Body.Position = UDim2.new(0.5,-20,0.55,0)
    p1Body.BackgroundColor3 = c
    Helpers.corner(p1Body, 6)

    local p2Head = Instance.new("Frame", p)
    p2Head.Size = UDim2.new(0,11,0,11)
    p2Head.Position = UDim2.new(0.5,6,0.3,0)
    p2Head.BackgroundColor3 = c
    Helpers.corner(p2Head, 100)

    local p2Body = Instance.new("Frame", p)
    p2Body.Size = UDim2.new(0,16,0,13)
    p2Body.Position = UDim2.new(0.5,4,0.55,0)
    p2Body.BackgroundColor3 = c
    Helpers.corner(p2Body, 6)
end

iconBuilders.Server = function(p, c)
    local rack = Instance.new("Frame", p)
    rack.Size = UDim2.new(0,28,0,22)
    rack.Position = UDim2.new(0.5,-14,0.36,0)
    rack.BackgroundColor3 = c
    Helpers.corner(rack, 5)

    local panel = Instance.new("Frame", rack)
    panel.Size = UDim2.new(0,18,0,12)
    panel.Position = UDim2.new(0.5,-9,0.5,-6)
    panel.BackgroundColor3 = Color3.new(1,1,1)
    panel.BackgroundTransparency = 0.6
    Helpers.corner(panel, 3)

    for i = 1, 3 do
        local led = Instance.new("Frame", panel)
        led.Size = UDim2.new(0,4,0,4)
        led.Position = UDim2.new(0,3+i*4,0.5,-2)
        led.BackgroundColor3 = Color3.fromRGB(0,255,100)
        Helpers.corner(led, 100)
    end
end

iconBuilders.Teleport = function(p, c)
    local outerRing = Instance.new("Frame", p)
    outerRing.Size = UDim2.new(0,32,0,32)
    outerRing.Position = UDim2.new(0.5,-16,0.24,0)
    outerRing.BackgroundColor3 = c
    Helpers.corner(outerRing, 100)

    local innerCircle = Instance.new("Frame", p)
    innerCircle.Size = UDim2.new(0,12,0,12)
    innerCircle.Position = UDim2.new(0.5,-6,0.44,0)
    innerCircle.BackgroundColor3 = Color3.new(1,1,1)
    Helpers.corner(innerCircle, 100)

    local centerDot = Instance.new("Frame", p)
    centerDot.Size = UDim2.new(0,4,0,4)
    centerDot.Position = UDim2.new(0.5,-2,0.52,0)
    centerDot.BackgroundColor3 = c
    Helpers.corner(centerDot, 100)
end

iconBuilders.Settings = function(p, c)
    local centerCircle = Instance.new("Frame", p)
    centerCircle.Size = UDim2.new(0,14,0,14)
    centerCircle.Position = UDim2.new(0.5,-7,0.38,0)
    centerCircle.BackgroundColor3 = c
    Helpers.corner(centerCircle, 100)

    local innerHole = Instance.new("Frame", p)
    innerHole.Size = UDim2.new(0,6,0,6)
    innerHole.Position = UDim2.new(0.5,-3,0.46,0)
    innerHole.BackgroundColor3 = Color3.new(1,1,1)
    Helpers.corner(innerHole, 100)

    for i = 1, 8 do
        local angle = math.rad(i*45)
        local radius = 11
        local tx = math.cos(angle)*radius
        local ty = math.sin(angle)*radius
        local tooth = Instance.new("Frame", p)
        tooth.Size = UDim2.new(0,5,0,5)
        tooth.Position = UDim2.new(0.5,tx-2,0.38+ty*0.018,0)
        tooth.BackgroundColor3 = c
        tooth.Rotation = i*45
        Helpers.corner(tooth, 1)
    end

    local outerRing = Instance.new("Frame", p)
    outerRing.Size = UDim2.new(0,24,0,24)
    outerRing.Position = UDim2.new(0.5,-12,0.3,0)
    outerRing.BackgroundTransparency = 1
    Helpers.stroke(outerRing, c, 2, 0.3)
    Helpers.corner(outerRing, 100)
end

iconBuilders.Bundle = function(p, c)
    local box = Instance.new("Frame", p)
    box.Size = UDim2.new(0,28,0,28)
    box.Position = UDim2.new(0.5,-14,0.28,0)
    box.BackgroundColor3 = c
    Helpers.corner(box, 6)

    local ribbon = Instance.new("Frame", p)
    ribbon.Size = UDim2.new(0,32,0,8)
    ribbon.Position = UDim2.new(0.5,-16,0.42,0)
    ribbon.BackgroundColor3 = c
    Helpers.corner(ribbon, 3)

    local bow1 = Instance.new("Frame", p)
    bow1.Size = UDim2.new(0,10,0,6)
    bow1.Position = UDim2.new(0.5,-14,0.38,0)
    bow1.BackgroundColor3 = c
    bow1.Rotation = -30
    Helpers.corner(bow1, 3)

    local bow2 = Instance.new("Frame", p)
    bow2.Size = UDim2.new(0,10,0,6)
    bow2.Position = UDim2.new(0.5,4,0.38,0)
    bow2.BackgroundColor3 = c
    bow2.Rotation = 30
    Helpers.corner(bow2, 3)
end

iconBuilders.AvatarItems = function(p, c)
    local head = Instance.new("Frame", p)
    head.Size = UDim2.new(0,14,0,14)
    head.Position = UDim2.new(0.5,-7,0.2,0)
    head.BackgroundColor3 = c
    Helpers.corner(head, 100)

    local body = Instance.new("Frame", p)
    body.Size = UDim2.new(0,24,0,18)
    body.Position = UDim2.new(0.5,-12,0.52,0)
    body.BackgroundColor3 = c
    Helpers.corner(body, 8)

    local tag = Instance.new("Frame", p)
    tag.Size = UDim2.new(0,12,0,8)
    tag.Position = UDim2.new(0.5,10,0.38,0)
    tag.BackgroundColor3 = c
    tag.BackgroundTransparency = 0.4
    Helpers.corner(tag, 3)
end

iconBuilders.Lookup = function(p, c)
    local circle = Instance.new("Frame", p)
    circle.Size = UDim2.new(0,22,0,22)
    circle.Position = UDim2.new(0.5,-14,0.25,0)
    circle.BackgroundTransparency = 1
    Helpers.stroke(circle, c, 3, 0)
    Helpers.corner(circle, 100)

    local handle = Instance.new("Frame", p)
    handle.Size = UDim2.new(0,3,0,12)
    handle.Position = UDim2.new(0.5,6,0.5,2)
    handle.BackgroundColor3 = c
    handle.Rotation = 45
    Helpers.corner(handle, 2)
end

iconBuilders.ServerJoiner = function(p, c)
    local rack = Instance.new("Frame", p)
    rack.Size = UDim2.new(0,24,0,20)
    rack.Position = UDim2.new(0.5,-12,0.3,0)
    rack.BackgroundColor3 = c
    Helpers.corner(rack, 5)

    for i = 1, 2 do
        local light = Instance.new("Frame", p)
        light.Size = UDim2.new(0,4,0,4)
        light.Position = UDim2.new(0.5,-6+i*6,0.5,-2)
        light.BackgroundColor3 = Color3.fromRGB(0,255,100)
        Helpers.corner(light, 100)
    end

    local arrow = Instance.new("Frame", p)
    arrow.Size = UDim2.new(0,8,0,3)
    arrow.Position = UDim2.new(0.5,10,0.5,-1)
    arrow.BackgroundColor3 = c
    Helpers.corner(arrow, 2)
end

iconBuilders.WhoOnline = function(p, c)
    local ring = Instance.new("Frame", p)
    ring.Size = UDim2.new(0,28,0,28)
    ring.Position = UDim2.new(0.5,-14,0.2,0)
    ring.BackgroundTransparency = 1
    Helpers.stroke(ring, c, 2.5, 0)
    Helpers.corner(ring, 100)

    local dot = Instance.new("Frame", p)
    dot.Size = UDim2.new(0,10,0,10)
    dot.Position = UDim2.new(0.5,-5,0.38,0)
    dot.BackgroundColor3 = Color3.fromRGB(0,220,100)
    Helpers.corner(dot, 100)

    for i = 1, 3 do
        local head = Instance.new("Frame", p)
        head.Size = UDim2.new(0,7,0,7)
        head.Position = UDim2.new(0,8+(i-1)*12,0,62)
        head.BackgroundColor3 = c
        Helpers.corner(head, 100)
    end
end

iconBuilders.Message = function(p, c)
    local bubble = Instance.new("Frame", p)
    bubble.Size = UDim2.new(0,30,0,22)
    bubble.Position = UDim2.new(0.5,-15,0.28,0)
    bubble.BackgroundColor3 = c
    Helpers.corner(bubble, 8)

    local tail = Instance.new("Frame", p)
    tail.Size = UDim2.new(0,8,0,8)
    tail.Position = UDim2.new(0.5,-12,0,50)
    tail.BackgroundColor3 = c
    tail.Rotation = 45

    for i = 1, 3 do
        local dot = Instance.new("Frame", bubble)
        dot.Size = UDim2.new(0,4,0,4)
        dot.Position = UDim2.new(0,4+(i-1)*9,0.5,-2)
        dot.BackgroundColor3 = Color3.fromRGB(0,0,0)
        dot.BackgroundTransparency = 0.4
        Helpers.corner(dot, 100)
    end
end

_G.iconBuilders = iconBuilders
return iconBuilders