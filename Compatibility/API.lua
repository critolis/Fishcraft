local _, F = ...
local A = {}
F.API = A
function A.Locked() return InCombatLockdown and InCombatLockdown() end
function A.Readable(v) return not issecretvalue or not issecretvalue(v) end
function A.Try(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if ok and A.Readable(a) and A.Readable(b) and A.Readable(c) and A.Readable(d) and A.Readable(e) and A.Readable(f) and A.Readable(g) then return a, b, c, d, e, f, g end
end
function A.Item(id)
    local fn = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local itemID, _, _, equipLoc, icon, class, subclass = A.Try(fn, id)
    if not itemID then return nil end
    local name = A.Try(C_Item and C_Item.GetItemInfo or GetItemInfo, id)
    return { id = itemID, name = name or ("Item " .. itemID), icon = icon, equipLoc = equipLoc, pole = class == 2 and subclass == 20 }
end
function A.GUID(bag, slot, inventory)
    if not ItemLocation or not ItemLocation.CreateFromEquipmentSlot or not ItemLocation.CreateFromBagAndSlot or not C_Item or not C_Item.GetItemGUID then return nil end
    local loc = inventory and ItemLocation:CreateFromEquipmentSlot(inventory) or ItemLocation:CreateFromBagAndSlot(bag, slot)
    return A.Try(C_Item.GetItemGUID, loc)
end
function A.Inventory(slot)
    if not GetInventoryItemID or not GetInventoryItemLink then return { unavailable = true } end
    local ok, id = pcall(GetInventoryItemID, "player", slot)
    if not ok or not A.Readable(id) then return { unavailable = true } end
    if not id then return false end
    local link = A.Try(GetInventoryItemLink, "player", slot)
    if not link then return { unavailable = true, id = id } end
    local item = A.Item(link)
    if not item then return { link = link } end
    item.link, item.guid = link, A.GUID(nil, nil, slot)
    return item
end
function A.Bags()
    local items, empty = {}, nil
    local C = C_Container
    if not C or not C.GetContainerItemInfo then return items, empty end
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local n = A.Try(C.GetContainerNumSlots, bag) or 0
        local _, family = A.Try(C.GetContainerNumFreeSlots, bag)
        for slot = 1, n do
            local info = A.Try(C.GetContainerItemInfo, bag, slot)
            if not info then
                if not empty and family == 0 then empty = { bag = bag, slot = slot } end
            elseif A.Readable(info.itemID) and A.Readable(info.hyperlink) and A.Readable(info.isLocked) then
                local item = A.Item(info.itemID)
                if item then
                    item.bag, item.slot, item.link = bag, slot, info.hyperlink
                    item.guid, item.locked, item.count = A.GUID(bag, slot), info.isLocked, info.stackCount
                    items[#items + 1] = item
                end
            end
        end
    end
    return items, empty
end
local fishingIDs = { 131474, 7620, 7731, 7732, 18248, 33095, 51294, 88868 }
function A.IsFishingSpell(id)
    if not A.Readable(id) or type(id)~="number" then return false end
    if id==F.spellID then return true end
    for _,known in ipairs(fishingIDs) do if id==known then return true end end
    return false
end
function A.FishingSpell()
    local ids = fishingIDs
    local names = {}
    for _, id in ipairs(ids) do
        local info = A.Try(C_Spell and C_Spell.GetSpellInfo, id)
        if info and A.Readable(info.name) then names[info.name] = true end
    end
    local S = C_SpellBook
    if S and S.GetNumSpellBookSkillLines and C_Spell and C_Spell.GetSpellInfo and Enum and Enum.SpellBookSpellBank then
        for i = 1, (A.Try(S.GetNumSpellBookSkillLines) or 0) do
            local line = A.Try(S.GetSpellBookSkillLineInfo, i)
            if line then
                for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                    local item = A.Try(S.GetSpellBookItemInfo, slot, Enum.SpellBookSpellBank.Player)
                    local info = item and item.spellID and A.Try(C_Spell.GetSpellInfo, item.spellID)
                    if info and A.Readable(info.name) and names[info.name] then return item.spellID, info.name end
                end
            end
        end
    end
    for _, id in ipairs(ids) do
        local known = A.Try(S and S.IsSpellKnown or IsPlayerSpell or IsSpellKnown, id)
        if known then
            local info = A.Try(C_Spell and C_Spell.GetSpellInfo, id)
            if info and A.Readable(info.name) then return id, info.name end
        end
    end
end
function A.Enchant()
    if C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        local ok, info = pcall(C_PaperDollInfo.GetTemporaryEnchantmentInfo, 16)
        if not ok or not A.Readable(info) then return nil end
        if not info then return false end
        local ms = info.remainingTimeMs
        return true, A.Readable(ms) and type(ms) == "number" and ms / 1000 or nil
    end
    if GetWeaponEnchantInfo then
        local has, ms = A.Try(GetWeaponEnchantInfo)
        if has == nil then return nil end
        return not not has, type(ms) == "number" and ms / 1000 or nil
    end
end
function A.SkillSnapshot()
    local info = A.Try(C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID, 356)
    if type(info)~="table" then return nil end
    for _,key in ipairs({"rank","modifier","tempPoints","maxRank"}) do
        local n=info[key]
        if not A.Readable(n) or type(n)~="number" or n~=n or math.abs(n)>10000 then return nil end
    end
    if info.rank<=0 then return nil end
    return {rank=info.rank,modifier=info.modifier,temporary=info.tempPoints,maximum=info.maxRank,
        total=info.rank+info.modifier+info.tempPoints}
end
function A.Skill()
    local s=A.SkillSnapshot()
    if s then return s.rank,s.modifier+s.temporary,s.maximum end
end
function A.Zone() return A.Try(GetRealZoneText) or "Unknown location", A.Try(GetSubZoneText) or "" end
function A.Supported()
    local _, build, _, interface = GetBuildInfo()
    return interface == 16001, build, interface
end
