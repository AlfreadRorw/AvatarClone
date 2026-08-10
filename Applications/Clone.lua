local T           = _G.T
local Helpers     = _G.Helpers
local Storage     = _G.Storage
local Config      = _G.Config
local RS          = game:GetService("ReplicatedStorage")

local function getItems(p)
    local c = p.Character
    if not c then return {} end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return {} end
    local ok, d = pcall(function() return h:GetAppliedDescription() end)
    if not ok then return {} end
    local items = {}
    local bodies = {
        {"Head",d.Head},{"Torso",d.Torso},{"LeftArm",d.LeftArm},
        {"RightArm",d.RightArm},{"LeftLeg",d.LeftLeg},{"RightLeg",d.RightLeg},
        {"Shirt",d.Shirt},{"Pants",d.Pants},{"Face",d.Face},{"GraphicTShirt",d.GraphicTShirt}
    }
    for _, b in ipairs(bodies) do
        if b[2] and b[2] ~= "" and b[2] ~= "0" then
            table.insert(items, {Label=b[1], Value=tostring(b[2]), Type="BODY"})
        end
    end
    local ok2, accs = pcall(function() return d:GetAccessories(true) end)
    if ok2 and accs then
        for _, a in ipairs(accs) do
            table.insert(items, {Label=a.AccessoryType.Name, Value=tostring(a.AssetId), Type="ACC"})
        end
    end
    return items
end

local function fireHat(ids)
    if #ids == 0 then return end
    local remote = RS
    for _, part in ipairs(Config.REMOTE_PATH:split(".")) do
        remote = remote:FindFirstChild(part)
        if not remote then return end
    end
    pcall(function() remote:FireServer("hat", {"hat", table.unpack(ids)}) end)
end

local function cloneItems(target, cb)
    if not target then return end
    local items = getItems(target)
    if #items == 0 then return end
    local ids = {}
    for _, it in ipairs(items) do table.insert(ids, it.Value) end
    local batch = Config.CLONE_BATCH_SIZE
    local delay = Config.CLONE_DELAY
    local total = math.ceil(#ids / batch)
    local cur   = 0
    local function nextBatch()
        cur = cur + 1
        if cur > total then if cb then cb(true) end return end
        local s = (cur-1)*batch+1
        local e = math.min(cur*batch, #ids)
        local b = {}
        for i = s, e do table.insert(b, ids[i]) end
        fireHat(b)
        if cb then cb(nil, cur, total) end
        task.delay(delay, nextBatch)
    end
    nextBatch()
end

-- Expose globally so other apps can use
_G.getItems    = getItems
_G.fireHat     = fireHat
_G.cloneItems  = cloneItems

local function openCloneApp()
    local appContent = _G.appContent
    local state      = _G.PhoneState

    if not state.selectedPlayer then
        local h = Instance.new("TextLabel", appContent)
        h.Size = UDim2.new(1,0,0,60)
        h.BackgroundTransparency = 1
        h.Text = "Select a player first."
        h.TextColor3 = T.Text2
        h.Font = Enum.Font.Gotham
        h.TextSize = 12
        h.TextWrapped = true
        return
    end

    if state.isCloning then
        local w = Instance.new("TextLabel", appContent)
        w.Size = UDim2.new(1,0,0,40)
        w.BackgroundTransparency = 1
        w.Text = "Cloning in progress..."
        w.TextColor3 = T.Text2
        w.Font = Enum.Font.Gotham
        w.TextSize = 12
        return
    end

    local items = getItems(state.selectedPlayer)
    if #items == 0 then
        local n = Instance.new("TextLabel", appContent)
        n.Size = UDim2.new(1,0,0,40)
        n.BackgroundTransparency = 1
        n.Text = "No items to clone."
        n.TextColor3 = T.Text2
        n.Font = Enum.Font.Gotham
        n.TextSize = 12
        return
    end

    -- Profile card
    local pf = Instance.new("Frame", appContent)
    pf.Size = UDim2.new(1,0,0,60)
    pf.BackgroundColor3 = T.Card2
    Helpers.corner(pf, 10)
    Helpers.stroke(pf, T.Accent, 1.5, 0.3)

    local av = Instance.new("ImageLabel", pf)
    av.Size = UDim2.new(0,44,0,44)
    av.Position = UDim2.new(0,8,0.5,-22)
    av.BackgroundColor3 = T.BG
    av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="
        ..state.selectedPlayer.UserId.."&width=100&height=100&format=png"
    Helpers.corner(av, 100)

    local nl = Instance.new("TextLabel", pf)
    nl.Size = UDim2.new(1,-100,0,30)
    nl.Position = UDim2.new(0,56,0,14)
    nl.BackgroundTransparency = 1
    nl.Text = state.selectedPlayer.DisplayName
    nl.TextColor3 = T.Text
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 14
    nl.TextXAlignment = Enum.TextXAlignment.Left

    local ic = Instance.new("TextLabel", pf)
    ic.Size = UDim2.new(1,-100,0,20)
    ic.Position = UDim2.new(0,56,0,36)
    ic.BackgroundTransparency = 1
    ic.Text = #items.." items"
    ic.TextColor3 = T.Green
    ic.Font = Enum.Font.Gotham
    ic.TextSize = 11
    ic.TextXAlignment = Enum.TextXAlignment.Left

    -- Clone button
    local cloneBtn = Instance.new("TextButton", appContent)
    cloneBtn.Size = UDim2.new(1,0,0,46)
    cloneBtn.BackgroundColor3 = T.Accent
    cloneBtn.Text = "Clone Hat (5 IDs / 6s)"
    cloneBtn.TextColor3 = T.OnAccent
    cloneBtn.Font = Enum.Font.GothamBlack
    cloneBtn.TextSize = 14
    cloneBtn.AutoButtonColor = false
    Helpers.corner(cloneBtn, 10)
    Helpers.pressFX(cloneBtn)

    cloneBtn.MouseButton1Click:Connect(function()
        if state.isCloning then return end
        state.isCloning = true
        cloneBtn.Text = "Cloning..."
        cloneBtn.BackgroundColor3 = T.Gold

        local bar = Instance.new("Frame", appContent)
        bar.Size = UDim2.new(1,0,0,8)
        bar.BackgroundColor3 = T.Card2
        Helpers.corner(bar, 4)

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new(0,0,1,0)
        fill.BackgroundColor3 = T.Green
        Helpers.corner(fill, 4)

        cloneItems(state.selectedPlayer, function(done, batch, total)
            if done then
                state.isCloning = false
                cloneBtn.Text = "Clone Done"
                Helpers.tween(cloneBtn, {BackgroundColor3 = T.Green}, 0.3)
                pcall(function() fill:Destroy() end)
                Helpers.showDynamicNotification("Clone complete!", T.Green)
            else
                local r = batch/total
                Helpers.tween(fill, {Size=UDim2.new(r,0,1,0)}, 0.3)
                cloneBtn.Text = string.format("Cloning %d/%d", batch, total)
            end
        end)
    end)

    -- Item rows
    for i, it in ipairs(items) do
        local row = Instance.new("Frame", appContent)
        row.Size = UDim2.new(1,0,0,52)
        row.BackgroundColor3 = T.Card2
        row.LayoutOrder = i+10
        Helpers.corner(row, 10)
        Helpers.stroke(row, T.Border, 1, 0.3)

        local thumb = Instance.new("ImageLabel", row)
        thumb.Size = UDim2.new(0,42,0,42)
        thumb.Position = UDim2.new(0,5,0.5,-21)
        thumb.BackgroundColor3 = T.BG
        thumb.Image = "https://www.roblox.com/asset-thumbnail/image?assetId="
            ..it.Value.."&width=100&height=100&format=png"
        thumb.ScaleType = Enum.ScaleType.Fit
        Helpers.corner(thumb, 8)
        Helpers.stroke(thumb, T.Border, 1, 0.3)

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-130,0,18)
        nameLbl.Position = UDim2.new(0,52,0,6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = it.Label
        nameLbl.TextColor3 = T.Text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local idLbl = Instance.new("TextLabel", row)
        idLbl.Size = UDim2.new(1,-130,0,16)
        idLbl.Position = UDim2.new(0,52,0,24)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = it.Value
        idLbl.TextColor3 = T.Green
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 10
        idLbl.TextXAlignment = Enum.TextXAlignment.Left

        local copyBtn = Instance.new("TextButton", row)
        copyBtn.Size = UDim2.new(0,60,0,28)
        copyBtn.Position = UDim2.new(1,-66,0.5,-14)
        copyBtn.BackgroundColor3 = T.Accent
        copyBtn.Text = "Copy"
        copyBtn.TextColor3 = T.OnAccent
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 10
        copyBtn.AutoButtonColor = false
        Helpers.corner(copyBtn, 6)
        Helpers.pressFX(copyBtn)
        copyBtn.MouseButton1Click:Connect(function()
            Helpers.copyToClipboard(it.Value)
            Helpers.showDynamicNotification("Copied: "..it.Value, T.Green)
        end)
    end
end

_G.openCloneApp = openCloneApp
return openCloneApp