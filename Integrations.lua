local _, GT = ...
local M, UI = GT.Model, GT.UI
local white = "Interface\\Buttons\\WHITE8X8"

local function colorText(text, color)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(color[1] * 255), math.floor(color[2] * 255), math.floor(color[3] * 255), text)
end

function GT:AddTooltip(tooltip, item)
    if not self.ready or not item or not item.itemID then return end
    local record = self:Record(item)
    local tags = M.GetTags(self.db, record)
    tooltip:AddLine(" ")
    if #tags > 0 then
        local labels = {}
        for _, tag in ipairs(tags) do table.insert(labels, colorText(tag.name, tag.color)) end
        tooltip:AddLine("GearTags: " .. table.concat(labels, " • "), 0.85, 0.85, 0.85, true)
    else
        tooltip:AddLine("GearTags: Untagged", 0.60, 0.64, 0.70)
    end
    if record and record.locked then tooltip:AddLine("Kilitli — satışta ek kontrol", 1, 0.78, 0.20, true) end
    if record and record.note and record.note ~= "" then tooltip:AddLine("Not: " .. record.note, 0.91, 0.87, 0.72, true) end
    if not item.isEquipment then tooltip:AddLine("Etiket / kilit bu eşya türünün tüm kopyalarına uygulanır.", 0.55, 0.59, 0.65, true) end
    if not item.key then tooltip:AddLine("Eşya kimliği yükleniyor…", 1, 0.55, 0.25)
    else tooltip:AddLine("Alt + Sağ Tık: etiketleri düzenle", 0.55, 0.59, 0.65) end
    tooltip:Show()
end

function GT:CreateNativeOverlay(button)
    if InCombatLockdown() then return nil end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 5)
    overlay:EnableMouse(false)
    overlay.shade = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.shade:SetAllPoints()
    overlay.shade:SetColorTexture(0, 0, 0, 1)
    overlay.glow = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    overlay.glow:SetPoint("TOPLEFT", -2, 2)
    overlay.glow:SetPoint("BOTTOMRIGHT", 2, -2)
    overlay.glow:SetBackdrop({ edgeFile = white, edgeSize = 2 })
    overlay.glow:EnableMouse(false)
    overlay.badges = {}
    for index = 1, 2 do
        local badge = overlay:CreateTexture(nil, "OVERLAY", nil, 3)
        badge:SetSize(10, 4)
        badge:SetPoint("BOTTOMLEFT", 3 + (index - 1) * 12, 3)
        overlay.badges[index] = badge
    end
    overlay.lock = overlay:CreateTexture(nil, "OVERLAY", nil, 4)
    overlay.lock:SetSize(14, 14)
    overlay.lock:SetPoint("TOPRIGHT", 1, 1)
    overlay.lock:SetTexture("Interface\\PetBattles\\PetBattle-Lock")
    overlay.lock:SetVertexColor(1, 0.80, 0.23)

    -- A local mouse overlay handles Alt+Right-click and vendor locks. We do not
    -- replace UseContainerItem, PickupContainerItem or Blizzard click globals.
    local gate = CreateFrame("Button", nil, overlay)
    gate:SetAllPoints(button)
    gate:SetFrameLevel(overlay:GetFrameLevel() + 2)
    gate:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    gate:RegisterForDrag("LeftButton")
    gate:SetScript("OnEnter", function()
        GameTooltip:SetOwner(gate, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(button:GetParent():GetID(), button:GetID())
        GameTooltip:Show()
    end)
    gate:SetScript("OnLeave", function() GameTooltip:Hide() end)
    gate:SetScript("OnClick", function(_, mouseButton)
        if InCombatLockdown() then return end
        local item = GT:ReadSlot(button:GetParent():GetID(), button:GetID())
        if item.bag ~= overlay.bag or item.slot ~= overlay.slot or item.itemID ~= overlay.itemID or item.key ~= overlay.itemKey then
            GT:QueueRefresh(); return
        end
        if IsAltKeyDown() and mouseButton == "RightButton" and item.itemID then GT:OpenEditor(item); return end
        local decision = M.VendorDecision(item, GT:Record(item), MerchantFrame and MerchantFrame:IsShown(), GetCursorInfo() ~= nil)
        if decision == "locked" then GT:ShowLockDialog(item); return end
        if decision == "unresolved" then GT:Print("Eşyanın kimliği yükleniyor; tekrar dene."); return end
        if decision == "cursor" then GT:Print("Önce imleçteki eşyayı bırak veya Esc'ye bas."); return end
        local original = button:GetScript("OnClick")
        if original then original(button, mouseButton) end
        GT:QueueRefresh()
    end)
    gate:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        local item = GT:ReadSlot(button:GetParent():GetID(), button:GetID())
        if item.bag ~= overlay.bag or item.slot ~= overlay.slot or item.itemID ~= overlay.itemID or item.key ~= overlay.itemKey then
            GT:QueueRefresh(); return
        end
        local decision = M.VendorDecision(item, GT:Record(item), MerchantFrame and MerchantFrame:IsShown(), GetCursorInfo() ~= nil)
        if decision == "locked" then GT:ShowLockDialog(item)
        elseif decision == "allow" then C_Container.PickupContainerItem(item.bag, item.slot) end
    end)
    gate:SetScript("OnReceiveDrag", function()
        GT:Print("İmleçteki eşyayı boş bir çanta yuvasına bırak.")
    end)
    gate:Hide()
    overlay.gate = gate
    button.GearTagsOverlay = overlay
    return overlay
end

function GT:UpdateNativeFrame(frame)
    if not self.ready or not frame then return end
    local bag = frame:GetID()
    if not frame:GetName() then return end
    local enabled = bag and bag >= 0 and bag <= 4 and self.character.settings.nativeOverlay
    local _, color = self:FilterInfo()
    local filtering = self.filter ~= "all" or self.query ~= ""
    for index = 1, frame.size or 36 do
        local button = _G[frame:GetName() .. "Item" .. index]
        if button then
            local overlay = button.GearTagsOverlay
            if enabled and button:IsShown() then
                overlay = overlay or self:CreateNativeOverlay(button)
                if overlay then
                    local item = self:ReadSlot(bag, button:GetID())
                    overlay.bag, overlay.slot, overlay.itemID, overlay.itemKey = bag, button:GetID(), item.itemID, item.key
                    local record, matches = self:Record(item), self:Matches(item)
                    local tags = M.GetTags(self.db, record)
                    overlay.shade:SetAlpha(1 - self.character.settings.dimAlpha)
                    overlay.shade:SetShown(item.itemID ~= nil and not matches and filtering)
                    overlay.glow:SetBackdropBorderColor(color[1], color[2], color[3], 1)
                    overlay.glow:SetShown(matches and filtering)
                    overlay.lock:SetShown(record and record.locked or false)
                    for badgeIndex, badge in ipairs(overlay.badges) do
                        local tag = tags[badgeIndex]
                        if tag then badge:SetColorTexture(tag.color[1], tag.color[2], tag.color[3], 1); badge:Show()
                        else badge:Hide() end
                    end
                    local merchant = MerchantFrame and MerchantFrame:IsShown()
                    local decision = M.VendorDecision(item, record, merchant, false)
                    local guarded = merchant and (decision == "locked" or decision == "unresolved")
                    overlay.gate:SetShown(not InCombatLockdown() and item.itemID ~= nil and (IsAltKeyDown() or guarded))
                    overlay:Show()
                end
            elseif overlay then overlay.gate:Hide(); overlay:Hide() end
        end
    end
end

function GT:UpdateNativeBags()
    for index = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = _G["ContainerFrame" .. index]
        if frame and frame:IsShown() then self:UpdateNativeFrame(frame) end
    end
end

function GT:SyncAutoOpen()
    if not self.ready or not self.character.settings.autoOpen then return end
    local bagShown = false
    for index = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = _G["ContainerFrame" .. index]
        if frame and frame:IsShown() and frame:GetID() >= 0 and frame:GetID() <= 4 then bagShown = true; break end
    end
    if bagShown then
        self:BuildWindow()
        if not self.window:IsShown() then self.autoOpened = true; self.window:Show() end
    elseif self.autoOpened and self.window then
        self.window:Hide()
        self.autoOpened = nil
    end
end

function GT:QueueBagSync()
    if self.bagSyncQueued then return end
    self.bagSyncQueued = true
    C_Timer.After(0, function()
        self.bagSyncQueued = nil
        self:UpdateNativeBags()
        self:SyncAutoOpen()
    end)
end

function GT:InstallIntegrations()
    if self.integrationsInstalled then return end
    self.integrationsInstalled = true
    hooksecurefunc(GameTooltip, "SetBagItem", function(tooltip, bag, slot)
        if GT.ready and bag and slot then GT:AddTooltip(tooltip, GT:ReadSlot(bag, slot)) end
    end)
    hooksecurefunc(GameTooltip, "SetInventoryItem", function(tooltip, unit, slot)
        if not GT.ready or unit ~= "player" or not ItemLocation then return end
        local itemID = GetInventoryItemID(unit, slot)
        if not itemID then return end
        local location = ItemLocation:CreateFromEquipmentSlot(slot)
        local guid = C_Item.GetItemGUID(location)
        local key = guid and guid ~= "" and "guid:" .. guid or nil
        if M.GetRecord(GT.character, key) then
            GT:AddTooltip(tooltip, { itemID = itemID, isEquipment = true, key = key })
        end
    end)
    if type(ContainerFrame_Update) == "function" then
        hooksecurefunc("ContainerFrame_Update", function(frame) GT:UpdateNativeFrame(frame) end)
    end
    -- Keyboard toggles can show/hide the native frames directly without waiting
    -- for a container event. Observe the actual native frame lifecycle as well.
    for _, name in ipairs({ "ContainerFrame_OnShow", "ContainerFrame_OnHide" }) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function() GT:QueueBagSync() end)
        end
    end
end

function GT:BuildMinimapButton()
    if not Minimap or self.minimapButton then return end
    local button = CreateFrame("Button", "GearTagsMinimapButton", Minimap, "BackdropTemplate")
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("CENTER", Minimap, "CENTER", -77, -48)
    button:SetBackdrop({ bgFile = white, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
    button:SetBackdropColor(0.06, 0.07, 0.09, 1)
    button:SetBackdropBorderColor(0.84, 0.69, 0.36, 1)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            GT:BuildWindow(); GT.window:Show(); GT:ToggleSettings()
        else GT:ToggleWindow() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("GearTags", 1, 0.82, 0.4)
        GameTooltip:AddLine("Sol tık: envanter  •  Sağ tık: ayarlar", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetShown(not self.character.settings.hideMinimap)
    self.minimapButton = button
end
