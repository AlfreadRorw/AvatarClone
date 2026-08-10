local T       = _G.T
local Helpers = _G.Helpers

local function openBodyApp()
    local appContent = _G.appContent
    local state      = _G.PhoneState
    local getItems   = _G.getItems

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

    local items  = getItems(state.selectedPlayer)
    local shown  = 0

    for _, it in ipairs(items) do
        if it.Type == "BODY" then
            shown = shown + 1
            local row = Instance.new("Frame", appContent)
            row.Size = UDim2.new(1,0,0,52)
            row.BackgroundColor3 = T.Card2
            row.LayoutOrder = shown
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

    if shown == 0 then
        local n = Instance.new("TextLabel", appContent)
        n.Size = UDim2.new(1,0,0,40)
        n.BackgroundTransparency = 1
        n.Text = "No body items."
        n.TextColor3 = T.Text2
        n.Font = Enum.Font.Gotham
        n.TextSize = 12
    end
end

_G.openBodyApp = openBodyApp
return openBodyApp