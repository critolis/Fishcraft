local _, F = ...
local J, A = { ledger = {}, slots = {}, lootTokens = {} }, F.API
F.Collection = J
function J:CloseLoot(touch)
    for token in pairs(self.lootTokens) do
        token.lootOpen=nil;F.Statistics:EndCast(token)
        if touch and F.Statistics:Valid(token) then F.Session:Touch() end
    end
    self.lootTokens={}
end
function J:Arm(unit, guid, id)
    if not A.Readable(unit) or not A.Readable(id) or not A.Readable(guid) then return end
    if unit == "player" then
        if A.IsFishingSpell(id) and self.cast and self.cast.guid==guid then return end
        if not self.cast or self.cast.guid~=guid then self:CloseLoot(false) end
        if self.cast and self.cast.guid~=guid then
            self.cast.lootOpen=nil;F.Statistics:EndCast(self.cast)
        end
        self.slots = {}
        if A.IsFishingSpell(id) then
            self.castAt = GetTime()
            -- Repeated spell events must share one success/timing sample.
            if not self.cast or self.cast.guid~=guid then self.cast={guid=guid,at=self.castAt} end
        else self.castAt = nil;self.cast=nil end
    end
end
function J:Source(slot)
    if not GetLootSourceInfo then return nil end
    local result = { pcall(GetLootSourceInfo, slot) }
    if not result[1] or #result < 3 then return nil end
    local source
    for i = 2, #result, 2 do
        local guid = result[i]
        if not A.Readable(guid) or type(guid) ~= "string" then return nil end
        local entry = tonumber(guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-.+$"))
        if not entry or not F.Data.bobbers[entry] or (source and source ~= guid) then return nil end
        source = guid
    end
    return source
end
function J:Capture()
    self.slots = {}
    if not F.compatible or not F.db.settings.trackCollection or A.Locked() then return end
    if not self.castAt or GetTime() - self.castAt > 40 then return end
    for key, row in pairs(self.ledger) do if GetTime() - row.at > 600 then self.ledger[key] = nil end end
    local zone, subzone = A.Zone()
    for slot = 1, (A.Try(GetNumLootItems) or 0) do
        local link = A.Try(GetLootSlotLink, slot)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        local source = id and self:Source(slot)
        local icon, name, count, _, quality = A.Try(GetLootSlotInfo, slot)
        if source and type(count) == "number" and count > 0 then
            local key = source .. ":" .. slot .. ":" .. id
            if not self.ledger[key] then
                self.ledger[key] = { id=id, remaining=count, at=GetTime(), cast=self.cast, zone=zone, subzone=subzone, link=link, name=name or ("Item "..id), icon=icon, quality=quality }
            end
            self.slots[slot] = self.ledger[key]
            if self.slots[slot].cast then
                self.slots[slot].cast.lootOpen=true;self.lootTokens[self.slots[slot].cast]=true
            end
        end
    end
end
function J:Record(row, count)
    if not F.db.settings.trackCollection or count <= 0 then return end
    local record = F.db.collection[row.id]
    if not record then
        record = { count=0, first=time(), firstZone=row.zone, firstSubzone=row.subzone, zones={} }; F.db.collection[row.id] = record
    end
    record.name, record.link, record.icon, record.quality = row.name, row.link, row.icon, row.quality
    record.count, record.last = record.count + count, time()
    record.zones[row.zone] = (record.zones[row.zone] or 0) + count
    record.lastSubzone = row.subzone
    F.Statistics:Recover(row,count)
    F:Emit("COLLECTION_UPDATED")
end
function J:Changed(slot, cleared)
    local row = self.slots[slot]
    if not row or row.remaining <= 0 then return end
    local remaining = 0
    if not cleared then
        local link = A.Try(GetLootSlotLink, slot)
        if link ~= row.link then return end
        local _, _, count = A.Try(GetLootSlotInfo, slot)
        if type(count) ~= "number" or count < 0 then return end
        remaining = count
    end
    if remaining < row.remaining then
        local acquired = row.remaining - remaining
        row.remaining = remaining
        self:Record(row, acquired)
    end
end
function J:Rows(query, zone, allLoot)
    local rows, ids = {}, {}
    for id in pairs(F.Data.fish) do ids[id] = true end
    for id in pairs(F.db.collection) do ids[id] = true end
    query = (query or ""):lower()
    for id in pairs(ids) do
        local ref, owned = F.Data.fish[id], F.db.collection[id]
        local name = owned and owned.name or ref and ref.name or ("Item "..id)
        local inZone = not zone or (owned and owned.zones[zone])
        if not inZone and ref then for _, z in ipairs(ref.zones) do if z == zone then inZone = true end end end
        if (allLoot or ref) and inZone and name:lower():find(query, 1, true) then
            rows[#rows+1] = { id=id, name=name, count=owned and owned.count or 0, owned=owned, ref=ref }
        end
    end
    table.sort(rows, function(a,b) if (a.count>0) ~= (b.count>0) then return a.count>0 end; return a.name<b.name end)
    return rows
end
function J:Initialize()
    F:Register("UNIT_SPELLCAST_SUCCEEDED", function(...) self:Arm(...) end)
    F:Register("UNIT_SPELLCAST_CHANNEL_START", function(...) self:Arm(...) end)
    F:Register("LOOT_READY", function() self:Capture() end)
    F:Register("LOOT_OPENED", function() self:Capture() end)
    F:Register("LOOT_SLOT_CLEARED", function(slot) self:Changed(slot, true) end)
    F:Register("LOOT_SLOT_CHANGED", function(slot) self:Changed(slot, false) end)
    F:Register("LOOT_CLOSED", function()
        self:CloseLoot(true);self.slots = {}
    end)
    F:Register("ZONE_CHANGED_NEW_AREA", function()
        self:CloseLoot(false);F.Statistics:DiscardPending();self.castAt=nil;self.cast=nil;self.slots={}
    end)
end
