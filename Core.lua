local addonName, GT = ...
_G.GearTags = GT
GT.filter, GT.query = "all", ""

StaticPopupDialogs.GEARTAGS_UNLOCK = {
    text = "%s\n\nBu eşya kilitli. Kilidi kaldırmak satışı otomatik başlatmaz.\nSatmak için tekrar tıklaman gerekir.",
    button1 = "Kilidi kaldır", button2 = "Vazgeç", timeout = 0,
    whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnAccept = function(_, data)
        if not data or not data.key or not GT.ready then return end
        GT.Model.SetLock(GT.character, data.key, false)
        if GT.editor and GT.editor.itemKey == data.key then GT.editor.lock:SetChecked(false) end
        GT:Refresh()
        GT:Print("Kilit kaldırıldı. Eşya satılmadı.")
    end,
}

StaticPopupDialogs.GEARTAGS_DELETE_TAG = {
    text = "“%s” etiketi silinsin mi?\n\nTüm karakterlerde bu etiket kaldırılır. Eşyalar ve satış kilitleri korunur.",
    button1 = "Etiketi sil", button2 = "Vazgeç", timeout = 0,
    whileDead = true, hideOnEscape = true, preferredIndex = 3,
    OnAccept = function(_, data)
        if data and GT.ready and GT.Model.DeleteTag(GT.db, data.id) then
            GT.filter = "all"
            if GT.editor then GT.editor:Hide() end
            GT:Refresh()
        end
    end,
}

function GT:Initialize()
    if self.ready then return end
    local playerGUID = UnitGUID("player")
    if not playerGUID then return end
    if WOW_PROJECT_ID and WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        self:Print("Bu paket yalnızca Classic Era istemcisi içindir.")
        return
    end
    if not C_Container or not C_Container.GetContainerItemInfo or not C_Item
        or not C_Item.GetItemGUID or not C_Item.GetItemInfoInstant or not ItemLocation then
        self:Print("Gerekli Classic Era API'leri bulunamadı; istemci sürümünü kontrol et.")
        return
    end
    local db, character = self.Model.Init(GearTagsDB, playerGUID)
    if not db then self:Print(character); return end
    self.db, self.character, GearTagsDB = db, character, db
    self.ready = true
    self:InstallIntegrations()
    self:BuildMinimapButton()
    self:Refresh()
    local version, build, _, interface = GetBuildInfo()
    self:Print("v" .. self.version .. " hazır. Açmak için /gt  •  Etiketlemek için Alt + Sağ Tık")
    if interface ~= 11509 then
        self:Print("Paket hedefi 1.15.9 / 11509; senin istemcin " .. tostring(version) .. " (" .. tostring(build) .. ") / " .. tostring(interface) .. ".")
    end
end

SLASH_GEARTAGS1, SLASH_GEARTAGS2 = "/gt", "/geartags"
SlashCmdList.GEARTAGS = function(message)
    if not GT.ready then GT:Print("Addon henüz hazır değil; Classic Era istemcisinde /reload dene."); return end
    message = (message or ""):match("^%s*(.-)%s*$"):lower()
    if message == "help" or message == "yardim" then
        GT:Print("/gt: aç/kapat  •  /gt options: ayarlar  •  /gt minimap: minimap düğmesi  •  /gt resetpos: pencere konumu")
        GT:Print("Alt + Sağ Tık: etiketler/not/kilit. Normal çantalarda bu kısayol için Ayarlar > Normal çantalarda da işaretle açık olmalı.")
    elseif message == "options" or message == "ayarlar" then
        GT:BuildWindow(); GT.window:Show(); GT:ToggleSettings()
    elseif message == "minimap" then
        GT.character.settings.hideMinimap = not GT.character.settings.hideMinimap
        if GT.minimapButton then GT.minimapButton:SetShown(not GT.character.settings.hideMinimap) end
    elseif message == "resetpos" then
        GT.character.settings.position = nil
        GT:BuildWindow()
        GT.window:ClearAllPoints()
        GT.window:SetPoint("CENTER", UIParent, "CENTER", -60, 15)
        GT.window:Show()
    elseif message == "debug" then
        local version, build, _, interface = GetBuildInfo()
        GT:Print("Addon " .. GT.version .. " | İstemci " .. tostring(version) .. "." .. tostring(build) .. " | Interface " .. tostring(interface))
        GT:Print("Yuva " .. GT.occupied .. "/" .. GT.capacity .. " | Filtre " .. GT.filter .. " | Mod " .. GT.character.settings.mode .. " | Normal çanta katmanı " .. tostring(GT.character.settings.nativeOverlay))
    else GT:ToggleWindow() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= addonName then return end
        GT:Initialize()
    elseif event == "PLAYER_LOGIN" then
        GT:Initialize()
    elseif GT.ready then
        if event == "MODIFIER_STATE_CHANGED" then
            GT:UpdateNativeBags()
        elseif event == "BAG_OPEN" or event == "BAG_CLOSED" then
            GT:QueueRefresh()
            GT:QueueBagSync()
        elseif event == "MERCHANT_SHOW" then
            GT:Refresh()
        elseif event == "MERCHANT_CLOSED" then
            StaticPopup_Hide("GEARTAGS_UNLOCK")
            GT:QueueRefresh()
        else GT:QueueRefresh() end
    end
end)
for _, event in ipairs({
    "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "ITEM_LOCK_CHANGED", "GET_ITEM_INFO_RECEIVED",
    "ITEM_DATA_LOAD_RESULT", "MERCHANT_SHOW", "MERCHANT_CLOSED", "MODIFIER_STATE_CHANGED",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "BAG_OPEN", "BAG_CLOSED",
}) do events:RegisterEvent(event) end
