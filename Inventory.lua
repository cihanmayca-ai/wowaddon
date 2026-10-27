local _, GT = ...
local M = GT.Model

function GT:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd9b25fGearTags:|r " .. tostring(message))
end

function GT:GetGUID(bag, slot)
    if not C_Item or not C_Item.GetItemGUID or not ItemLocation then return nil end
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not C_Item.DoesItemExist(location) then return nil end
    local guid = C_Item.GetItemGUID(location)
    return guid ~= "" and guid or nil
end

function GT:ReadSlot(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    local item = { bag = bag, slot = slot }
    if not info then return item end
    item.itemID = info.itemID or C_Container.GetContainerItemID(bag, slot)
    if not item.itemID then return item end
    item.link = info.hyperlink or C_Container.GetContainerItemLink(bag, slot)
    item.icon = info.iconFileID
    item.count = info.stackCount or 1
    item.quality = info.quality or 1
    item.busy = info.isLocked
    local getInstant = C_Item.GetItemInfoInstant
    local _, _, _, equipLoc, _, classID = getInstant(item.itemID)
    item.identityPending = classID == nil
    item.isEquipment = (classID == 2 or classID == 4) and equipLoc and equipLoc ~= ""
    item.guid = item.isEquipment and self:GetGUID(bag, slot) or nil
    local name = C_Item.GetItemInfo(item.link or item.itemID)
    item.name = name or ("Eşya #" .. tostring(item.itemID))
    self.loadRequested = self.loadRequested or {}
    if not name and C_Item.RequestLoadItemDataByID and not self.loadRequested[item.itemID] then
        self.loadRequested[item.itemID] = true
        C_Item.RequestLoadItemDataByID(item.itemID)
    end
    item.key = M.Identity(item)
    return item
end

function GT:ScanBags()
    local items, occupied, capacity = {}, 0, 0
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag)
        capacity = capacity + slots
        for slot = 1, slots do
            local item = self:ReadSlot(bag, slot)
            table.insert(items, item)
            if item.itemID then occupied = occupied + 1 end
        end
    end
    self.items, self.occupied, self.capacity = items, occupied, capacity
    return items
end

function GT:Record(item, create)
    return M.GetRecord(self.character, item and item.key, create)
end

function GT:Matches(item)
    return M.Matches(self.db, item, self:Record(item), self.filter, self.query)
end

function GT:FindItem(key)
    if not key then return nil end
    for _, item in ipairs(self.items or {}) do
        if item.key == key then
            local fresh = self:ReadSlot(item.bag, item.slot)
            if fresh.key == key then return fresh end
        end
    end
    -- The item may have moved since BAG_UPDATE_DELAYED last fired.
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = self:ReadSlot(bag, slot)
            if item.key == key then return item end
        end
    end
end

function GT:Refresh()
    if not self.ready then return end
    self:ScanBags()
    if self.window and self.window:IsShown() then self:RefreshWindow() end
    if self.UpdateNativeBags then self:UpdateNativeBags() end
end

function GT:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    C_Timer.After(0, function()
        self.refreshQueued = nil
        self:Refresh()
    end)
end

function GT:SelectFilter(id)
    if id ~= "all" and id ~= "locked" and id ~= "untagged" and id ~= "custom" and not self.db.tags[id] then id = "all" end
    self.filter = id
    if self.window then self.window.scroll:SetVerticalScroll(0) end
    self:Refresh()
end

function GT:FilterInfo()
    if self.db.tags[self.filter] then
        local tag = self.db.tags[self.filter]
        return tag.name, tag.color, tag.icon
    end
    local definitions = {
        all = { "All", { 0.82, 0.68, 0.38 }, "Interface\\Icons\\INV_Misc_Bag_08" },
        custom = { "Custom", { 0.13, 0.84, 0.77 }, "Interface\\Icons\\INV_Misc_Rune_01" },
        untagged = { "Untagged", { 0.65, 0.69, 0.75 }, "Interface\\Icons\\INV_Misc_QuestionMark" },
        locked = { "Locked", { 1, 0.78, 0.20 }, "Interface\\Icons\\INV_Misc_Key_03" },
    }
    local def = definitions[self.filter] or definitions.all
    return def[1], def[2], def[3]
end

function GT:BagAction(button, mouseButton, isDrag)
    if InCombatLockdown() then
        self:Print("Çanta işlemlerini savaş bittikten sonra yapabilirsin.")
        return
    end
    local item = self:ReadSlot(button.bag, button.slot)
    -- Never apply a click to a different item after filtering, moving or selling.
    if button.itemID ~= item.itemID or button.itemKey ~= item.key then
        self:QueueRefresh()
        return
    end
    if item.busy then return end
    if IsAltKeyDown() and mouseButton == "RightButton" and not isDrag and item.itemID then
        self:OpenEditor(item)
        return
    end
    local merchantOpen = MerchantFrame and MerchantFrame:IsShown()
    local decision = M.VendorDecision(item, self:Record(item), merchantOpen, GetCursorInfo() ~= nil)
    if decision == "locked" then self:ShowLockDialog(item); return end
    if decision == "unresolved" then self:Print("Eşyanın kimliği yükleniyor; tekrar dene."); return end
    if decision == "cursor" then
        self:Print("Satıcı açıkken önce imleçteki eşyayı normal çantaya bırak veya Esc'ye bas.")
        return
    end
    if isDrag then
        C_Container.PickupContainerItem(item.bag, item.slot)
    elseif IsModifiedClick() and item.itemID then
        ContainerFrameItemButton_OnModifiedClick(button, mouseButton)
    else
        -- Use Blizzard's normal flow for refund warnings, buyback, banking,
        -- trade and other client-specific bag handling.
        ContainerFrameItemButton_OnClick(button, mouseButton)
    end
    self:QueueRefresh()
end
