local addonName, GT = ...
GT.version = "0.1.0-alpha"

local Model = {}
GT.Model = Model

local defaults = {
    { id = "pve", name = "PvE", color = { 0.73, 0.34, 1 }, icon = "Interface\\Icons\\INV_Helmet_06" },
    { id = "pvp", name = "PvP", color = { 0.18, 0.60, 1 }, icon = "Interface\\Icons\\INV_Shield_05" },
    { id = "essential", name = "Essential Gear", color = { 1, 0.78, 0.20 }, icon = "Interface\\Icons\\INV_Misc_Orb_05" },
    { id = "gathering", name = "Gathering", color = { 0.34, 0.83, 0.30 }, icon = "Interface\\Icons\\INV_Misc_Herb_01" },
    { id = "crafting", name = "Crafting", color = { 1, 0.49, 0.14 }, icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { id = "consumables", name = "Consumables", color = { 0.96, 0.31, 0.36 }, icon = "Interface\\Icons\\INV_Potion_51" },
}

GT.palette = {
    { 0.73, 0.34, 1 }, { 0.18, 0.60, 1 }, { 1, 0.78, 0.20 },
    { 0.34, 0.83, 0.30 }, { 1, 0.49, 0.14 }, { 0.96, 0.31, 0.36 },
    { 0.13, 0.84, 0.77 }, { 0.96, 0.47, 0.79 }, { 0.68, 0.74, 0.82 },
}

local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = clone(child) end
    return result
end

local function cleanText(value, limit)
    value = tostring(value or ""):gsub("|", ""):gsub("[%c]", " ")
    value = value:match("^%s*(.-)%s*$")
    if #value > limit then return nil end
    return value
end

function Model.Init(db, characterID)
    db = type(db) == "table" and db or {}
    -- Do not silently reinterpret a future database with this older addon.
    if db.schema and db.schema > 1 then return nil, "Veri sürümü daha yeni; GearTags'i güncelle." end
    db.schema = 1
    db.tags = type(db.tags) == "table" and db.tags or {}
    db.order = type(db.order) == "table" and db.order or {}
    db.characters = type(db.characters) == "table" and db.characters or {}
    db.nextTagID = tonumber(db.nextTagID) or 1
    local ordered, seen = {}, {}
    for _, definition in ipairs(defaults) do
        if type(db.tags[definition.id]) ~= "table" then db.tags[definition.id] = clone(definition) end
        table.insert(ordered, definition.id)
        seen[definition.id] = true
    end
    for _, id in ipairs(db.order) do
        local tag = db.tags[id]
        if type(tag) == "table" and tag.custom and not seen[id] then
            table.insert(ordered, id)
            seen[id] = true
        end
    end
    db.order = ordered
    local character = db.characters[characterID]
    if type(character) ~= "table" then character = {}; db.characters[characterID] = character end
    character.items = type(character.items) == "table" and character.items or {}
    character.settings = type(character.settings) == "table" and character.settings or {}
    local settings = character.settings
    if settings.mode ~= "only" then settings.mode = "highlight" end
    settings.dimAlpha = math.max(0.15, math.min(0.85, tonumber(settings.dimAlpha) or 0.35))
    if settings.autoOpen == nil then settings.autoOpen = true end
    if settings.nativeOverlay == nil then settings.nativeOverlay = true end
    return db, character
end

-- Equipment uses a physical instance GUID. Stackable materials use an item-type
-- key so splitting/merging a stack does not lose its tags or its vendor lock.
-- A missing equipment GUID is NOT replaced by a slot number or shared item ID.
function Model.Identity(item)
    if not item or not item.itemID then return nil end
    if item.identityPending then return nil end
    if item.isEquipment then
        if type(item.guid) == "string" and item.guid ~= "" then return "guid:" .. item.guid end
        return nil
    end
    return "item:" .. tostring(item.itemID)
end

function Model.GetRecord(character, key, create)
    if not key then return nil end
    local record = character.items[key]
    if not record and create then
        record = { tags = {}, locked = false, note = "" }
        character.items[key] = record
    end
    return record
end

function Model.GetTags(db, record)
    local result = {}
    if record and record.tags then
        for _, id in ipairs(db.order) do
            if record.tags[id] and db.tags[id] then table.insert(result, db.tags[id]) end
        end
    end
    return result
end

function Model.HasTag(db, record, id)
    if not record then return false end
    if id == "locked" then return record.locked == true end
    if id == "custom" then
        for _, tag in ipairs(Model.GetTags(db, record)) do
            if tag.custom then return true end
        end
        return false
    end
    return record.tags and record.tags[id] == true or false
end

local function fold(text)
    return tostring(text or ""):gsub("İ", "i"):gsub("I", "i"):gsub("ı", "i"):gsub("Ş", "ş")
        :gsub("Ğ", "ğ"):gsub("Ü", "ü"):gsub("Ö", "ö"):gsub("Ç", "ç"):lower()
end

function Model.Matches(db, item, record, filter, query)
    if not item or not item.itemID then return false end
    local matches = not filter or filter == "all"
    if filter == "untagged" then
        matches = #Model.GetTags(db, record) == 0
    elseif not matches then
        matches = Model.HasTag(db, record, filter)
    end
    if not matches then return false end
    query = fold(query):match("^%s*(.-)%s*$")
    if query == "" then return true end
    local fields = { item.name or "", tostring(item.itemID), record and record.note or "" }
    for _, tag in ipairs(Model.GetTags(db, record)) do table.insert(fields, tag.name) end
    return fold(table.concat(fields, " ")):find(query, 1, true) ~= nil
end

function Model.SetTag(db, character, key, id, enabled)
    if not key or not db.tags[id] then return false end
    local record = Model.GetRecord(character, key, true)
    record.tags = record.tags or {}
    record.tags[id] = enabled and true or nil
    return true
end

function Model.SetLock(character, key, enabled)
    if not key then return false end
    Model.GetRecord(character, key, true).locked = enabled and true or false
    return true
end

function Model.SetNote(character, key, note)
    local cleaned = cleanText(note, 300)
    if not key or not cleaned then return false end
    Model.GetRecord(character, key, true).note = cleaned
    return true
end

function Model.CreateTag(db, name)
    name = cleanText(name, 48)
    if not name or name == "" then return nil, "Etiket adı 1–48 bayt olmalı." end
    for _, tag in pairs(db.tags) do
        if fold(tag.name) == fold(name) then return nil, "Bu etiket adı zaten var." end
    end
    if #db.order >= #defaults + 32 then return nil, "En fazla 32 özel etiket oluşturabilirsin." end
    local id
    repeat
        id = "custom_" .. db.nextTagID
        db.nextTagID = db.nextTagID + 1
    until not db.tags[id]
    db.tags[id] = { id = id, name = name, custom = true, color = clone(GT.palette[7]), icon = "Interface\\Icons\\INV_Misc_Rune_01" }
    table.insert(db.order, id)
    return id
end

function Model.RenameTag(db, id, name)
    local tag = db.tags[id]
    if not tag or not tag.custom then return false, "Yalnızca özel etiketlerin adı değiştirilebilir." end
    name = cleanText(name, 48)
    if not name or name == "" then return false, "Geçerli bir ad yaz." end
    for otherID, other in pairs(db.tags) do
        if otherID ~= id and fold(other.name) == fold(name) then return false, "Bu ad zaten var." end
    end
    tag.name = name
    return true
end

function Model.DeleteTag(db, id)
    local tag = db.tags[id]
    if not tag or not tag.custom then return false end
    db.tags[id] = nil
    for index = #db.order, 1, -1 do
        if db.order[index] == id then table.remove(db.order, index) end
    end
    for _, character in pairs(db.characters) do
        for _, record in pairs(character.items or {}) do
            if record.tags then record.tags[id] = nil end
            -- Deleting a label must never remove an independent vendor lock.
        end
    end
    return true
end

-- Pure decision function shared by our bag and the native bag safety overlay.
-- No automatic sell or delayed sell is ever performed by the unlock dialog.
function Model.VendorDecision(item, record, merchantOpen, cursorBusy)
    if not merchantOpen then return "allow" end
    if cursorBusy then return "cursor" end
    if item and item.itemID and not Model.Identity(item) then return "unresolved" end
    if record and record.locked then return "locked" end
    return "allow"
end
