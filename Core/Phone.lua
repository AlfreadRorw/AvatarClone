-- ================= STATE =================
-- (lock screen dihapus, diganti key system di Loader)
_G.PhoneState = {
    selectedPlayer = nil,
    isLocked = false,  -- selalu false, sudah dihandle key system
    isCloning = false,
    toolEquipped = true,
}

-- ================= PHONE FUNCTIONS =================
-- showPass/hidePass/unlock tetap ada sebagai stub
-- supaya kode lama yang memanggilnya tidak error
function _G.showPass() end
function _G.hidePass() end
function _G.unlock()
    _G.PhoneState.isLocked = false
    _G.goHome()
end

function _G.openPhone()
    if phone.Visible then return end
    phone.Visible = true
    phone.Size = UDim2.new(0, 0, 0, 0)
    Helpers.tween(phone, {Size = PHONE_SIZE}, 0.32, Enum.EasingStyle.Back)
    -- Langsung goHome, tidak ada lock screen lagi
    _G.goHome()
end

function _G.closePhone()
    if not phone.Visible then return end
    Helpers.tween(phone, {Size = UDim2.new(0, 0, 0, 0)}, 0.22)
    task.delay(0.22, function() phone.Visible = false end)
end