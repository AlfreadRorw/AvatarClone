local T       = _G.T
local Helpers = _G.Helpers
local Storage = _G.Storage

local function openItemsApp()
    local appContent = _G.appContent
    local state      = _G.PhoneState
    local getItems   = _G.getItems
    local fireHat    = _G.fireHat

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

    local items = getItems(state.selectedPlayer)
    if #items == 0 then
        local n = Instance.new("TextLabel", appContent)
        n.Size = UDim2.new(1,0,0,40)
        n.BackgroundTransparency = 1
        n.Text = "No items."
        n.TextColor3 = T.Text2
        n.Font = Enum.Font.Gotham
        n.TextSize = 12
        return
    end

    local favItems = Storage.favItems

    for i, it in ipairs(items) do
        local row = Instance.new("Frame", appContent)
        row.Size = UDim2.new(1,0,0,52)
        row.BackgroundColor3 = T.Card2
        row.LayoutOrder = i
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
        nameLbl.Size = UDim2.new(1,-185,0,18)
        nameLbl.Position = UDim2.new(0,52,0,6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = it.Label
        nameLbl.TextColor3 = T.Text
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local idLbl = Instance.new("TextLabel", row)
        idLbl.Size = UDim2.new(1,-185,0,16)
        idLbl.Position = UDim2.new(0,52,0,24)
        idLbl.BackgroundTransparency = 1
        idLbl.Text = it.Value
        idLbl.TextColor3 = T.Green
        idLbl.Font = Enum.Font.Code
        idLbl.TextSize = 10
        idLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- Wear
        local wearBtn = Instance.new("TextButton", row)
        wearBtn.Size = UDim2.new(0,54,0,28)
        wearBtn.Position = UDim2.new(1,-130,0.5,-14)
        wearBtn.BackgroundColor3 = T.Green
        wearBtn.Text = "Wear"
        wearBtn.TextColor3 = T.OnAccent
        wearBtn.Font = Enum.Font.GothamBold
        wearBtn.TextSize = 10
        wearBtn.AutoButtonColor = false
        Helpers.corner(wearBtn, 6)
        Helpers.pressFX(wearBtn)
        wearBtn.MouseButton1Click:Connect(function()
            fireHat({it.Value})
            Helpers.showDynamicNotification("Wearing "..it.Value, T.Green)
        end)

        -- Fav
        local favBtn = Instance.new("TextButton", row)
        favBtn.Size = UDim2.new(0,54,0,28)
        favBtn.Position = UDim2.new(1,-70,0.5,-14)
        favBtn.BackgroundColor3 = T.Accent
        favBtn.Text = "Fav"
        favBtn.TextColor3 = T.OnAccent
        favBtn.Font = Enum.Font.GothamBold
        favBtn.TextSize = 10
        favBtn.AutoButtonColor = false
        Helpers.corner(favBtn, 6)
        Helpers.pressFX(favBtn)
        favBtn.MouseButton1Click:Connect(function()
            for _, fav in ipairs(favItems) do
                if tostring(fav.id) == it.Value then
                    Helpers.showDynamicNotification("Already in favorites", T.Red)
                    return
                end
            end
            table.insert(favItems, {
                id    = it.Value,
                label = it.Label,
                date  = os.date("%d/%m/%Y %H:%M")
            })
            Storage.persistFavItems()
            Helpers.showDynamicNotification("Added to fav items", T.Green)
        end)
    end
end

_G.openItemsApp = openItemsApp
return openItemsApp