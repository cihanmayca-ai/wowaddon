-- Deliberately explicit WoW boundary mock; this is NOT an in-game compatibility
-- test. Real secure execution, rendering, taint and third-party addons require WoW.
local mock = { frames = {}, timers = {}, actions = {}, messages = {}, combat = false, alt = false, cursor = nil }
_G.WoWMock = mock
local Methods = {}
Methods.__index = Methods

function Methods:SetSize(w, h) assert(type(w) == "number" and type(h) == "number"); self.width, self.height = w, h end
function Methods:SetWidth(w) self.width = w end
function Methods:SetHeight(h) self.height = h end
function Methods:GetWidth() return self.width or 100 end
function Methods:GetHeight() return self.height or 100 end
function Methods:SetPoint(...) self.point = { ... } end
function Methods:ClearAllPoints() self.point = nil end
function Methods:GetPoint() return unpack(self.point or { "CENTER", UIParent, "CENTER", 0, 0 }) end
function Methods:SetAllPoints(frame) self.allPoints = frame or self.parent end
function Methods:SetFrameStrata(value) self.strata = value end
function Methods:SetFrameLevel(value) self.level = value end
function Methods:GetFrameLevel() return self.level or 1 end
function Methods:SetClampedToScreen(value) self.clamped = value end
function Methods:SetMovable(value) self.movable = value end
function Methods:EnableMouse(value) self.mouse = value end
function Methods:RegisterForDrag(...) self.drag = { ... } end
function Methods:RegisterForClicks(...) self.clicks = { ... } end
function Methods:StartMoving() self.moving = true end
function Methods:StopMovingOrSizing() self.moving = false end
function Methods:SetScript(event, callback) assert(type(callback) == "function"); self.scripts[event] = callback end
function Methods:GetScript(event) return self.scripts[event] end
function Methods:HookScript(event, callback)
    local previous = self.scripts[event]
    self.scripts[event] = function(...) if previous then previous(...) end; callback(...) end
end
function Methods:SetScale(value) self.scale = value end
function Methods:SetID(value) self.id = value end
function Methods:GetID() return self.id or 0 end
function Methods:GetParent() return self.parent end
function Methods:GetName() return self.name end
function Methods:Show()
    local was = self.shown
    self.shown = true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Methods:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Methods:IsShown() return self.shown end
function Methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Methods:SetShown(value) if value then self:Show() else self:Hide() end end
function Methods:SetAlpha(value) assert(type(value) == "number"); self.alpha = value end
function Methods:SetBackdrop(value) self.backdrop = value end
function Methods:SetBackdropColor(...) self.backgroundColor = { ... } end
function Methods:SetBackdropBorderColor(...) self.borderColor = { ... } end
function Methods:SetHighlightTexture(...) self.highlightTexture = { ... } end
function Methods:SetText(value)
    local changed = self.text ~= tostring(value)
    self.text = tostring(value)
    if changed and self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function Methods:GetText() return self.text or "" end
function Methods:SetJustifyH(value) self.justify = value end
function Methods:SetTextColor(...) self.textColor = { ... } end
function Methods:SetTexture(value) self.texture = value end
function Methods:SetTexCoord(...) self.texCoord = { ... } end
function Methods:SetColorTexture(...) self.color = { ... } end
function Methods:SetVertexColor(...) self.vertexColor = { ... } end
function Methods:SetDesaturated(value) self.desaturated = value end
function Methods:SetScrollChild(frame) self.child = frame end
function Methods:SetVerticalScroll(value) self.verticalScroll = value end
function Methods:SetAutoFocus(value) self.autoFocus = value end
function Methods:SetMaxLetters(value) self.maxLetters = value end
function Methods:ClearFocus() self.focus = false end
function Methods:SetFocus() self.focus = true end
function Methods:HighlightText() self.highlightText = true end
function Methods:SetChecked(value) self.checked = value and true or false end
function Methods:GetChecked() return self.checked end
function Methods:SetEnabled(value) self.enabled = value and true or false end
function Methods:SetDrawEdge(value) self.drawEdge = value end
function Methods:SetCooldown(start, duration) self.cooldown = { start, duration } end
function Methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function Methods:SetValueStep(step) self.step = step end
function Methods:SetObeyStepOnDrag(value) self.obeyStep = value end
function Methods:SetValue(value)
    local changed = self.value ~= value
    self.value = value
    if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function Methods:RegisterEvent(event) self.events[event] = true end
function Methods:AddMessage(message) table.insert(mock.messages, message) end
function Methods:SetOwner(owner) self.owner = owner end
function Methods:GetOwner() return self.owner end
function Methods:AddLine(text, ...) table.insert(self.lines, text) end
function Methods:SetBagItem(bag, slot) self.lines = { "Native item tooltip" }; self.bag, self.slot = bag, slot end
function Methods:SetInventoryItem(unit, slot) self.lines = { "Native equipment tooltip" } end

local function newObject(name, parent)
    local object = setmetatable({ name = name, parent = parent, shown = true, scripts = {}, events = {}, lines = {} }, Methods)
    if name then _G[name] = object end
    return object
end
function Methods:CreateFontString(name) return newObject(name, self) end
function Methods:CreateTexture(name) return newObject(name, self) end
function CreateFrame(kind, name, parent, template)
    local frame = newObject(name, parent)
    frame.kind, frame.template = kind, template
    table.insert(mock.frames, frame)
    if template == "OptionsSliderTemplate" and name then
        for _, suffix in ipairs({ "Low", "High", "Text" }) do newObject(name .. suffix, frame) end
    end
    return frame
end
UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1920, 1080)
Minimap = CreateFrame("Frame", "Minimap", UIParent)
GameTooltip = CreateFrame("GameTooltip", "GameTooltip", UIParent)
DEFAULT_CHAT_FRAME = CreateFrame("Frame", "ChatFrame1", UIParent)
MerchantFrame = CreateFrame("Frame", "MerchantFrame", UIParent)
MerchantFrame.selectedTab = 1
MerchantFrame:Hide()
UISpecialFrames, SlashCmdList, StaticPopupDialogs = {}, {}, {}
WOW_PROJECT_ID, WOW_PROJECT_CLASSIC = 2, 2
NUM_CONTAINER_FRAMES = 13
ITEM_QUALITY_COLORS = {}
for index = 0, 7 do ITEM_QUALITY_COLORS[index] = { r = 0.2 + index * 0.1, g = 0.4, b = 0.7 } end
C_Timer = { After = function(_, callback) table.insert(mock.timers, callback) end }
function mock.Flush()
    local count = 0
    while #mock.timers > 0 do
        count = count + 1; assert(count < 100, "Timer refresh loop")
        local timer = table.remove(mock.timers, 1); timer()
    end
end
function InCombatLockdown() return mock.combat end
function IsAltKeyDown() return mock.alt end
function IsModifiedClick() return mock.modified or false end
function GetCursorInfo() return mock.cursor end
function UnitGUID() return "Player-Test-1" end
function GetBuildInfo() return "1.15.9", "70003", "Sep 23 2026", 11509 end
function StaticPopup_Show(id, text, _, data) mock.popup = { id = id, text = text, data = data }; return mock.popup end
function StaticPopup_Hide(id) if mock.popup and mock.popup.id == id then mock.popup = nil end end
function hooksecurefunc(target, method, callback)
    if type(target) == "string" then callback, method, target = method, target, _G end
    local original = assert(target[method], "Unknown hook: " .. method)
    target[method] = function(...)
        local results = { original(...) }
        callback(...)
        return unpack(results)
    end
end

mock.definitions = {
    [19019] = { name = "Test Sword", equipLoc = "INVTYPE_WEAPON", classID = 2 },
    [765] = { name = "Silverleaf", equipLoc = "", classID = 7 },
    [118] = { name = "Minor Healing Potion", equipLoc = "", classID = 0 },
    [200] = { name = "Loading Sword", equipLoc = "INVTYPE_WEAPON", classID = 2 },
}
mock.bags = {
    [0] = {
        [1] = { itemID = 19019, guid = "Item-A", stackCount = 1 },
        [2] = { itemID = 19019, guid = "Item-B", stackCount = 1 },
        [3] = { itemID = 765, guid = "Stack-A", stackCount = 12 },
        [4] = { itemID = 118, guid = "Stack-P", stackCount = 5 },
        [6] = { itemID = 200, stackCount = 1 },
    },
    [1] = { [1] = { itemID = 765, guid = "Stack-B", stackCount = 3 } },
    [2] = {}, [3] = {}, [4] = {},
}
local sizes = { [0] = 8, [1] = 4, [2] = 0, [3] = 0, [4] = 0 }
C_Container = {}
function C_Container.GetContainerNumSlots(bag) return sizes[bag] or 0 end
function C_Container.GetContainerItemInfo(bag, slot)
    local item = mock.bags[bag] and mock.bags[bag][slot]
    if not item then return nil end
    local info = {}
    for key, value in pairs(item) do info[key] = value end
    info.iconFileID, info.quality = 134400, 4
    info.hyperlink = "|cffa335ee|Hitem:" .. item.itemID .. ":0:0:0:0:0:0:0|h[" .. mock.definitions[item.itemID].name .. "]|h|r"
    return info
end
function C_Container.GetContainerItemID(bag, slot) local item = C_Container.GetContainerItemInfo(bag, slot); return item and item.itemID end
function C_Container.GetContainerItemLink(bag, slot) local item = C_Container.GetContainerItemInfo(bag, slot); return item and item.hyperlink end
function C_Container.GetContainerItemCooldown() return 0, 0, 1 end
function C_Container.PickupContainerItem(bag, slot) table.insert(mock.actions, { type = "pickup", bag = bag, slot = slot }) end
function C_Container.UseContainerItem(bag, slot)
    table.insert(mock.actions, { type = MerchantFrame:IsShown() and "sell" or "use", bag = bag, slot = slot })
end
C_Item = {}
function C_Item.GetItemInfoInstant(id)
    local definition = mock.definitions[id]
    if not definition then return nil end
    return id, "Type", "SubType", definition.equipLoc, 134400, definition.classID, 0
end
function C_Item.GetItemInfo(id)
    id = type(id) == "string" and tonumber(id:match("item:(%d+)")) or id
    return mock.definitions[id] and mock.definitions[id].name
end
function C_Item.RequestLoadItemDataByID() end
function C_Item.DoesItemExist(location) return mock.bags[location.bag] and mock.bags[location.bag][location.slot] ~= nil end
function C_Item.GetItemGUID(location)
    if location.equipment then return "Item-A" end
    local item = mock.bags[location.bag] and mock.bags[location.bag][location.slot]
    return item and item.guid
end
ItemLocation = {
    CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end,
    CreateFromEquipmentSlot = function(_, slot) return { equipment = slot } end,
}
function GetInventoryItemID() return 19019 end
function ContainerFrameItemButton_OnClick(button, mouseButton)
    if mouseButton == "RightButton" then C_Container.UseContainerItem(button:GetParent():GetID(), button:GetID())
    else C_Container.PickupContainerItem(button:GetParent():GetID(), button:GetID()) end
end
function ContainerFrameItemButton_OnModifiedClick(button, mouseButton)
    table.insert(mock.actions, { type = "modified", bag = button:GetParent():GetID(), slot = button:GetID() })
end
function ContainerFrame_Update() end
function ContainerFrame_OnShow() end
function ContainerFrame_OnHide() end
ContainerFrame1 = CreateFrame("Frame", "ContainerFrame1", UIParent)
ContainerFrame1:SetID(0)
ContainerFrame1.size = sizes[0]
for index = 1, sizes[0] do
    local button = CreateFrame("Button", "ContainerFrame1Item" .. index, ContainerFrame1)
    button:SetID(index)
    button:SetScript("OnClick", ContainerFrameItemButton_OnClick)
end
ContainerFrame1:Hide()
return mock
