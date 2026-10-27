local _, GT = ...
local M = GT.Model
local UI = {}
GT.UI = UI
local unpack = unpack
local gold = { 0.83, 0.68, 0.38 }
local white = "Interface\\Buttons\\WHITE8X8"

function UI.Panel(parent, width, height, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true,
        tileSize = 32, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.055, 0.060, 0.074, 0.98)
    frame:SetBackdropBorderColor(unpack(gold))
    return frame
end

function UI.Label(parent, text, x, y, font, width)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    if width then label:SetWidth(width) end
    return label
end

function UI.Button(parent, text, width, height, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 26)
    button:SetBackdrop({ bgFile = white, edgeFile = white, edgeSize = 1 })
    button:SetBackdropColor(0.10, 0.12, 0.15, 0.95)
    button:SetBackdropBorderColor(0.33, 0.31, 0.26, 1)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    button.label = label
    button:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    button:SetScript("OnClick", callback)
    return button
end

function UI.Active(button, active, color)
    color = color or gold
    if active then
        button:SetBackdropBorderColor(color[1], color[2], color[3], 1)
        button:SetBackdropColor(color[1] * 0.23, color[2] * 0.23, color[3] * 0.23, 1)
    else
        button:SetBackdropBorderColor(0.30, 0.29, 0.26, 1)
        button:SetBackdropColor(0.10, 0.12, 0.15, 0.95)
    end
end

function UI.Check(parent, text, x, y, callback)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check:SetSize(26, 26)
    check.caption = UI.Label(check, text, 29, -7, "GameFontHighlightSmall")
    check:SetScript("OnClick", function(self) callback(self:GetChecked()) end)
    return check
end

function UI.Close(frame)
    local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    button:SetPoint("TOPRIGHT", -3, -3)
    button:SetScript("OnClick", function() frame:Hide() end)
    return button
end

function UI.Scroll(parent, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, y)
    scroll:SetSize(width, height)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width, 1)
    scroll:SetScrollChild(content)
    return scroll, content
end

function UI.EditBox(parent, width, height, limit)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, height or 26)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(limit or 100)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end

function GT:BuildWindow()
    if self.window then return end
    local frame = UI.Panel(UIParent, 800, 650, "GearTagsFrame")
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        GT.character.settings.position = { point, relativePoint, x, y }
    end)
    frame:SetScale(math.min(1, (UIParent:GetWidth() - 40) / 800, (UIParent:GetHeight() - 40) / 650))
    local position = self.character.settings.position
    if position then frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else frame:SetPoint("CENTER", UIParent, "CENTER", -60, 15) end
    UI.Close(frame)
    UI.Label(frame, "GearTags", 20, -18, "GameFontNormalLarge")
    UI.Label(frame, "CLASSIC ERA  ·  ENVANTER", 20, -42, "GameFontDisableSmall")
    local search = UI.EditBox(frame, 218, 26, 100)
    search:SetPoint("TOPRIGHT", -112, -20)
    search:SetScript("OnTextChanged", function(self)
        GT.query = self:GetText()
        if GT.ready then GT:Refresh() end
    end)
    UI.Label(frame, "Eşya / etiket / not ara", 473, -49, "GameFontDisableSmall")
    local settings = UI.Button(frame, "Ayarlar", 62, 26, function() GT:ToggleSettings() end)
    settings:SetPoint("TOPRIGHT", -40, -20)

    local sidebar = UI.Panel(frame, 190, 508)
    sidebar:SetPoint("TOPLEFT", 12, -70)
    UI.Label(sidebar, "FİLTRELER", 12, -14, "GameFontNormal")
    frame.sideScroll, frame.sideContent = UI.Scroll(sidebar, 8, -40, 151, 450)
    frame.sideRows = {}
    frame.newTag = UI.Button(frame, "+ Yeni etiket", 180, 28, function() GT:PromptNewTag() end)
    frame.newTag:SetPoint("TOPLEFT", 17, -583)

    frame.active = UI.Button(frame, "All  ×", 154, 28, function() GT:SelectFilter("all") end)
    frame.active:SetPoint("TOPLEFT", 220, -73)
    frame.highlight = UI.Button(frame, "Vurgula", 110, 28, function()
        GT.character.settings.mode = "highlight"; GT:Refresh()
    end)
    frame.highlight:SetPoint("TOPLEFT", 383, -73)
    frame.only = UI.Button(frame, "Yalnızca göster", 155, 28, function()
        GT.character.settings.mode = "only"; GT:Refresh()
    end)
    frame.only:SetPoint("TOPLEFT", 501, -73)
    frame.matchCount = UI.Label(frame, "", 222, -111, "GameFontDisableSmall", 525)
    frame.scroll, frame.content = UI.Scroll(frame, 222, -142, 536, 408)
    frame.buttons, frame.bagHosts = {}, {}
    for bag = 0, 4 do
        local host = CreateFrame("Frame", nil, frame.content)
        host:SetAllPoints(frame.content)
        host:SetID(bag)
        frame.bagHosts[bag] = host
    end
    frame.empty = UI.Label(frame.content, "Bu filtrede eşya yok.\nAlt + Sağ Tık ile eşyalara etiket ekleyebilirsin.", 10, -40, "GameFontHighlight", 485)
    frame.empty:Hide()
    frame.legend = UI.Label(frame, "", 222, -566, "GameFontHighlightSmall", 536)
    frame.footer = UI.Label(frame, "", 222, -590, "GameFontNormalSmall", 536)
    UI.Label(frame, "Alt + Sağ Tık: etiketler   •   Sol tık / sürükle: taşı   •   Sağ tık: kullan / sat", 20, -624, "GameFontDisableSmall", 750)
    frame.search = search
    frame:SetScript("OnShow", function() GT:Refresh() end)
    frame:SetScript("OnHide", function()
        GameTooltip:Hide()
        if GT.editor then GT.editor:Hide() end
        if GT.settingsPanel then GT.settingsPanel:Hide() end
    end)
    frame:Hide()
    table.insert(UISpecialFrames, "GearTagsFrame")
    self.window = frame
end

function GT:ToggleWindow()
    if not self.ready then return end
    self:BuildWindow()
    self.autoOpened = nil
    if self.window:IsShown() then self.window:Hide() else self.window:Show() end
end

function GT:BuildSidebar()
    local frame = self.window
    local rows = { { id = "all", name = "All", icon = "Interface\\Icons\\INV_Misc_Bag_08", color = gold } }
    for _, id in ipairs(self.db.order) do
        if not self.db.tags[id].custom then table.insert(rows, self.db.tags[id]) end
    end
    table.insert(rows, { id = "custom", name = "Custom", icon = "Interface\\Icons\\INV_Misc_Rune_01", color = GT.palette[7] })
    for _, id in ipairs(self.db.order) do
        local tag = self.db.tags[id]
        if tag.custom then table.insert(rows, tag) end
    end
    table.insert(rows, { id = "untagged", name = "Untagged", icon = "Interface\\Icons\\INV_Misc_QuestionMark", color = { 0.65, 0.69, 0.75 } })
    table.insert(rows, { id = "locked", name = "Locked", icon = "Interface\\Icons\\INV_Misc_Key_03", color = GT.palette[3] })
    for index, definition in ipairs(rows) do
        local button = frame.sideRows[index]
        if not button then
            button = UI.Button(frame.sideContent, "", 149, 34, function(self) GT:SelectFilter(self.filterID) end)
            button.label:ClearAllPoints()
            button.label:SetPoint("LEFT", 30, 0)
            button.label:SetWidth(100)
            button.label:SetJustifyH("LEFT")
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(22, 22)
            button.icon:SetPoint("LEFT", 5, 0)
            button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            frame.sideRows[index] = button
        end
        button:SetPoint("TOPLEFT", 0, -(index - 1) * 38)
        button.filterID = definition.id
        button.label:SetText((definition.custom and "  " or "") .. definition.name)
        button.icon:SetTexture(definition.icon)
        UI.Active(button, self.filter == definition.id, definition.color)
        button:Show()
    end
    for index = #rows + 1, #frame.sideRows do frame.sideRows[index]:Hide() end
    frame.sideContent:SetHeight(math.max(1, #rows * 38))
end

function GT:CreateItemButton(item)
    local frame = self.window
    local button = CreateFrame("Button", nil, frame.bagHosts[item.bag], "BackdropTemplate")
    button:SetSize(54, 54)
    button:SetID(item.slot)
    button.bag, button.slot = item.bag, item.slot
    button:SetBackdrop({ bgFile = white, edgeFile = white, edgeSize = 1 })
    button:SetBackdropColor(0.035, 0.042, 0.052, 1)
    button:SetBackdropBorderColor(0.23, 0.24, 0.27, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.countText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.countText:SetPoint("BOTTOMRIGHT", -4, 4)
    button.qualityBorder = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.qualityBorder:SetPoint("TOPLEFT", 1, -1)
    button.qualityBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    button.qualityBorder:SetBackdrop({ edgeFile = white, edgeSize = 1 })
    button.qualityBorder:EnableMouse(false)
    button.glow = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.glow:SetPoint("TOPLEFT", -3, 3)
    button.glow:SetPoint("BOTTOMRIGHT", 3, -3)
    button.glow:SetBackdrop({ edgeFile = white, edgeSize = 2 })
    button.glow:EnableMouse(false)
    button.glow:Hide()
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(false)
    button.badges = {}
    for index = 1, 2 do
        local badge = button:CreateTexture(nil, "OVERLAY", nil, 3)
        badge:SetSize(12, 5)
        badge:SetPoint("BOTTOMLEFT", 4 + (index - 1) * 14, 4)
        button.badges[index] = badge
    end
    button.more = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.more:SetPoint("BOTTOMLEFT", 4, 11)
    button.lock = button:CreateTexture(nil, "OVERLAY", nil, 4)
    button.lock:SetSize(17, 17)
    button.lock:SetPoint("TOPRIGHT", 1, 1)
    button.lock:SetTexture("Interface\\PetBattles\\PetBattle-Lock")
    button.lock:SetVertexColor(1, 0.80, 0.23)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function(self, mouseButton) GT:BagAction(self, mouseButton, false) end)
    button:SetScript("OnDragStart", function(self) GT:BagAction(self, "LeftButton", true) end)
    button:SetScript("OnReceiveDrag", function(self) GT:BagAction(self, "LeftButton", true) end)
    button:SetScript("OnEnter", function(self)
        if not C_Container.GetContainerItemID(self.bag, self.slot) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(self.bag, self.slot)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

function GT:RefreshWindow()
    local frame, settings = self.window, self.character.settings
    self:BuildSidebar()
    local filterName, color = self:FilterInfo()
    frame.active.label:SetText(filterName .. (self.filter ~= "all" and "  ×" or ""))
    UI.Active(frame.active, true, color)
    UI.Active(frame.highlight, settings.mode == "highlight")
    UI.Active(frame.only, settings.mode == "only")
    local visible, matching = 0, 0
    local filtering = self.filter ~= "all" or self.query ~= ""
    for _, button in pairs(frame.buttons) do button:Hide() end
    for _, item in ipairs(self.items) do
        local matches = self:Matches(item)
        if matches then matching = matching + 1 end
        if settings.mode ~= "only" or matches then
            local id = item.bag .. ":" .. item.slot
            local button = frame.buttons[id]
            if not button then button = self:CreateItemButton(item); frame.buttons[id] = button end
            button.itemKey, button.itemID = item.key, item.itemID
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame.content, "TOPLEFT", (visible % 8) * 65 + 4, -math.floor(visible / 8) * 65 - 5)
            button:SetAlpha(item.itemID and (matches and 1 or settings.dimAlpha) or 0.38)
            if item.itemID then button.icon:SetTexture(item.icon); button.icon:Show() else button.icon:Hide() end
            button.icon:SetDesaturated(item.busy or false)
            -- Blizzard's refund flow reads .count as a NUMBER.
            button.count = item.count or 1
            button.countText:SetText(item.count and item.count > 1 and item.count or "")
            local quality = ITEM_QUALITY_COLORS[item.quality or 1] or ITEM_QUALITY_COLORS[1]
            button.qualityBorder:SetBackdropBorderColor(quality.r, quality.g, quality.b, 1)
            button.qualityBorder:SetShown(item.itemID ~= nil)
            button.glow:SetBackdropBorderColor(color[1], color[2], color[3], 0.95)
            button.glow:SetShown(matches and filtering)
            local record = self:Record(item)
            local tags = M.GetTags(self.db, record)
            for index, badge in ipairs(button.badges) do
                local tag = tags[index]
                if tag then badge:SetColorTexture(tag.color[1], tag.color[2], tag.color[3], 1); badge:Show()
                else badge:Hide() end
            end
            button.more:SetText(#tags > 2 and ("+" .. (#tags - 2)) or "")
            button.lock:SetShown(record and record.locked or false)
            if item.itemID then
                local start, duration, enable = C_Container.GetContainerItemCooldown(item.bag, item.slot)
                if enable == 1 and duration > 0 then button.cooldown:SetCooldown(start, duration); button.cooldown:Show()
                else button.cooldown:Hide() end
            else button.cooldown:Hide() end
            button:Show()
            visible = visible + 1
        end
    end
    frame.content:SetHeight(math.max(408, math.ceil(visible / 8) * 65 + 10))
    frame.empty:SetShown(visible == 0)
    frame.matchCount:SetText(matching .. " eşya eşleşiyor  ·  " .. (settings.mode == "only" and "Sadece eşleşenler gösteriliyor" or "Eşyaların çantadaki yerleri korunur"))
    frame.legend:SetText("|cffbc57ff■|r PvE   |cff329aff■|r PvP   |cffffc733■|r Essential Gear   ·   Diğer etiketler: tooltip")
    frame.footer:SetText(self.occupied .. " / " .. self.capacity .. " yuva  ·  " .. (InCombatLockdown() and "Savaşta: eşya işlemleri kapalı" or "Etiketler ve kilitler ayrı tutulur"))
    if self.settingsPanel and self.settingsPanel:IsShown() then self:RefreshSettings() end
end

function GT:TextPrompt(title, initial, callback)
    if not self.prompt then
        local prompt = UI.Panel(UIParent, 340, 166, "GearTagsPrompt")
        prompt:SetFrameStrata("FULLSCREEN_DIALOG")
        prompt:SetClampedToScreen(true)
        prompt:SetPoint("CENTER")
        UI.Close(prompt)
        prompt.title = UI.Label(prompt, "", 16, -18, "GameFontNormal", 280)
        prompt.input = UI.EditBox(prompt, 290, 26, 48)
        prompt.input:SetPoint("TOPLEFT", 23, -48)
        prompt.error = UI.Label(prompt, "", 16, -81, "GameFontRedSmall", 302)
        local save = UI.Button(prompt, "Kaydet", 120, 28, function() GT:AcceptPrompt() end)
        save:SetPoint("BOTTOMLEFT", 18, 16)
        local cancel = UI.Button(prompt, "Vazgeç", 120, 28, function() prompt:Hide() end)
        cancel:SetPoint("BOTTOMRIGHT", -18, 16)
        prompt.input:SetScript("OnEnterPressed", function() GT:AcceptPrompt() end)
        prompt:SetScript("OnHide", function(self) self.input:ClearFocus() end)
        self.prompt = prompt
        table.insert(UISpecialFrames, "GearTagsPrompt")
    end
    local prompt = self.prompt
    prompt.callback = callback
    prompt.title:SetText(title)
    prompt.error:SetText("")
    prompt.input:SetText(initial or "")
    prompt:Show()
    prompt.input:SetFocus()
    prompt.input:HighlightText()
end

function GT:AcceptPrompt()
    local ok, message = self.prompt.callback(self.prompt.input:GetText())
    if ok then self.prompt:Hide(); self:Refresh()
    else self.prompt.error:SetText(message or "Kaydedilemedi.") end
end

function GT:PromptNewTag()
    self:TextPrompt("Yeni Custom etiketi", "", function(name)
        local id, message = M.CreateTag(GT.db, name)
        if not id then return false, message end
        GT.filter = id
        return true
    end)
end

function GT:BuildEditor()
    if self.editor then return end
    local editor = UI.Panel(UIParent, 354, 555, "GearTagsEditor")
    editor:SetFrameStrata("DIALOG")
    editor:SetClampedToScreen(true)
    editor:SetPoint("CENTER", UIParent, "CENTER", 230, 0)
    UI.Close(editor)
    UI.Label(editor, "Eşya etiketleri", 18, -20, "GameFontNormalLarge")
    editor.title = UI.Label(editor, "", 18, -54, "GameFontHighlight", 310)
    editor.scope = UI.Label(editor, "", 18, -83, "GameFontDisableSmall", 310)
    editor.scroll, editor.content = UI.Scroll(editor, 16, -119, 290, 225)
    editor.checks = {}
    editor.lock = UI.Check(editor, "Satış kilidi", 17, -353, function(checked)
        if checked then
            M.SetLock(GT.character, editor.itemKey, true)
        else
            editor.lock:SetChecked(true)
            GT:ShowUnlockDialog(editor.itemKey, editor.itemName)
        end
        GT:Refresh()
    end)
    UI.Label(editor, "Kilit, set etiketlerinden bağımsızdır.", 22, -385, "GameFontDisableSmall", 306)
    UI.Label(editor, "Kişisel not", 22, -412, "GameFontNormal")
    editor.note = UI.EditBox(editor, 300, 26, 300)
    editor.note:SetPoint("TOPLEFT", 26, -437)
    local save = UI.Button(editor, "Notu kaydet", 140, 27, function()
        if M.SetNote(GT.character, editor.itemKey, editor.note:GetText()) then
            editor.note:ClearFocus(); GT:Refresh(); GT:Print("Not kaydedildi.")
        else GT:Print("Not en fazla 300 bayt olmalı.") end
    end)
    save:SetPoint("TOPLEFT", 22, -478)
    local done = UI.Button(editor, "Tamam", 140, 27, function() editor:Hide() end)
    done:SetPoint("TOPRIGHT", -22, -478)
    UI.Label(editor, "Etiket ve kilit değişiklikleri hemen kaydedilir.", 22, -520, "GameFontDisableSmall", 310)
    editor:SetScript("OnHide", function(self) self.note:ClearFocus() end)
    editor:Hide()
    table.insert(UISpecialFrames, "GearTagsEditor")
    self.editor = editor
end

function GT:OpenEditor(item)
    if not item.key then self:Print("Eşyanın kimliği henüz yüklenmedi; biraz sonra tekrar dene."); return end
    self:BuildEditor()
    local editor = self.editor
    editor.itemKey, editor.itemName = item.key, item.name
    editor.title:SetText(item.link or item.name)
    editor.scope:SetText(item.isEquipment and "Bu ekipmana özel • yer değiştirince korunur" or "Bu eşya türünün tüm kopyaları / yığınları")
    local record = self:Record(item)
    for index, id in ipairs(self.db.order) do
        local tag = self.db.tags[id]
        local check = editor.checks[index]
        if not check then
            check = UI.Check(editor.content, "", 0, -(index - 1) * 30, function() end)
            check.caption:SetWidth(245)
            editor.checks[index] = check
            check:SetScript("OnClick", function(self)
                M.SetTag(GT.db, GT.character, editor.itemKey, self.tagID, self:GetChecked())
                GT:Refresh()
            end)
        end
        check.tagID = id
        check.caption:SetText(tag.name)
        check.caption:SetTextColor(tag.color[1], tag.color[2], tag.color[3])
        check:SetChecked(record and record.tags and record.tags[id] or false)
        check:Show()
    end
    for index = #self.db.order + 1, #editor.checks do editor.checks[index]:Hide() end
    editor.content:SetHeight(math.max(225, #self.db.order * 30))
    editor.scroll:SetVerticalScroll(0)
    editor.lock:SetChecked(record and record.locked or false)
    editor.note:SetText(record and record.note or "")
    editor:Show()
end

function GT:ShowUnlockDialog(key, name)
    StaticPopup_Show("GEARTAGS_UNLOCK", name or "Eşya", nil, { key = key })
end

function GT:ShowLockDialog(item)
    self:ShowUnlockDialog(item.key, item.link or item.name)
end

function GT:ToggleSettings()
    if not self.settingsPanel then
        local panel = UI.Panel(UIParent, 280, 450, "GearTagsSettings")
        panel:SetFrameStrata("DIALOG")
        panel:SetClampedToScreen(true)
        panel:SetPoint("TOPLEFT", self.window, "TOPRIGHT", 6, 0)
        UI.Close(panel)
        UI.Label(panel, "Etiket görünümü", 16, -20, "GameFontNormalLarge")
        panel.selected = UI.Label(panel, "", 16, -56, "GameFontHighlight", 240)
        UI.Label(panel, "Seçili etiketin vurgu rengi", 16, -85, "GameFontDisableSmall")
        panel.swatches = {}
        for index, color in ipairs(self.palette) do
            local swatch = UI.Button(panel, "", 23, 23, function()
                local tag = GT.db.tags[GT.filter]
                if tag then
                    tag.color = { color[1], color[2], color[3] }
                    GT:Refresh()
                else GT:Print("Rengini değiştirmek için önce bir etiket seç.") end
            end)
            swatch:SetPoint("TOPLEFT", 16 + (index - 1) * 27, -109)
            swatch:SetBackdropColor(color[1], color[2], color[3], 1)
            panel.swatches[index] = swatch
        end
        panel.dimLabel = UI.Label(panel, "", 16, -154, "GameFontHighlightSmall", 243)
        panel.dim = CreateFrame("Slider", "GearTagsDimSlider", panel, "OptionsSliderTemplate")
        panel.dim:SetPoint("TOPLEFT", 23, -185)
        panel.dim:SetSize(228, 18)
        panel.dim:SetMinMaxValues(15, 85)
        panel.dim:SetValueStep(5)
        panel.dim:SetObeyStepOnDrag(true)
        _G.GearTagsDimSliderLow:SetText("%15")
        _G.GearTagsDimSliderHigh:SetText("%85")
        _G.GearTagsDimSliderText:SetText("")
        panel.dim:SetScript("OnValueChanged", function(_, value)
            GT.character.settings.dimAlpha = value / 100
            panel.dimLabel:SetText("Diğer eşyaların parlaklığı: %" .. math.floor(value + 0.5))
            if not panel.updating then GT:Refresh() end
        end)
        panel.auto = UI.Check(panel, "Çantayla birlikte aç", 12, -231, function(checked)
            GT.character.settings.autoOpen = checked
        end)
        panel.native = UI.Check(panel, "Normal çantalarda da işaretle", 12, -264, function(checked)
            GT.character.settings.nativeOverlay = checked
            GT:Refresh()
        end)
        panel.rename = UI.Button(panel, "Adını değiştir", 117, 27, function()
            local id, tag = GT.filter, GT.db.tags[GT.filter]
            if tag and tag.custom then
                GT:TextPrompt("Etiket adını değiştir", tag.name, function(name) return M.RenameTag(GT.db, id, name) end)
            end
        end)
        panel.rename:SetPoint("TOPLEFT", 16, -316)
        panel.delete = UI.Button(panel, "Etiketi sil", 117, 27, function()
            local tag = GT.db.tags[GT.filter]
            if tag and tag.custom then StaticPopup_Show("GEARTAGS_DELETE_TAG", tag.name, nil, { id = GT.filter }) end
        end)
        panel.delete:SetPoint("TOPRIGHT", -16, -316)
        UI.Label(panel, "Ad değiştirme ve silme yalnızca Custom etiketler için geçerlidir. Etiket silmek satış kilidini kaldırmaz.", 16, -359, "GameFontDisableSmall", 246)
        panel:Hide()
        table.insert(UISpecialFrames, "GearTagsSettings")
        self.settingsPanel = panel
    end
    if self.settingsPanel:IsShown() then self.settingsPanel:Hide()
    else self.settingsPanel:Show(); self:RefreshSettings() end
end

function GT:RefreshSettings()
    local panel = self.settingsPanel
    if not panel then return end
    panel.updating = true
    panel.selected:SetText("Seçili: " .. self:FilterInfo())
    panel.dim:SetValue(self.character.settings.dimAlpha * 100)
    panel.dimLabel:SetText("Diğer eşyaların parlaklığı: %" .. math.floor(self.character.settings.dimAlpha * 100 + 0.5))
    panel.auto:SetChecked(self.character.settings.autoOpen)
    panel.native:SetChecked(self.character.settings.nativeOverlay)
    local tag = self.db.tags[self.filter]
    panel.rename:SetEnabled(tag and tag.custom or false)
    panel.delete:SetEnabled(tag and tag.custom or false)
    panel.updating = nil
end
