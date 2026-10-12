local _, F = ...
local E, A, M = {}, F.API, F.Model
F.Equipment = E
function E:Scan()
    self.items, self.empty = A.Bags()
    self.main, self.off = A.Inventory(16), A.Inventory(17)
    self.poles = {}
    local seen = {}
    if self.main and self.main.pole then table.insert(self.poles, self.main); seen[self.main.id] = true end
    for _, item in ipairs(self.items) do
        if item.pole and not item.locked and not seen[item.id] then
            seen[item.id] = true
            item.bonus = F.Data.poleBonuses[item.id]
            table.insert(self.poles, item)
        end
    end
    self.selected, self.ranked = M.Choose(self.poles, F.db.settings.preferredPole)
    if F.db.equipment then
        local snapshot = F.db.equipment
        if self.main and self.main.pole then snapshot.poleObserved = true end
        local step = M.RestoreStep(F.db.equipment, { [16] = self.main, [17] = self.off }, self.items)
        -- Equip requests and inventory reads need not settle in the same frame.
        -- Only a requested restore may clear a snapshot; old weapon reads after
        -- requesting pole equip are not evidence of a completed round trip.
        if step and step.done and snapshot.phase == "restoring" then F.db.equipment = nil end
    end
end
function E:Guard()
    if A.Locked() then F:Say(F.L["Equipment is locked during combat."]); return false end
    if not F.compatible then F:Say(F.L["Equipment changes are disabled on this client interface."]); return false end
    if not CursorHasItem or CursorHasItem() then F:Say(F.L["Clear your cursor first."]); return false end
    if not EquipCursorItem or not PickupInventoryItem or not C_Container or not C_Container.PickupContainerItem then
        F:Say(F.L["Equipment APIs unavailable. Equip your pole manually."]); return false
    end
    return true
end
function E:ReadableEquipment()
    if (self.main and self.main.unavailable) or (self.off and self.off.unavailable) then
        F:Say(F.L["Equipment information is unavailable. Wait for item data and try again."]); return false
    end
    return true
end
function E:Swap(item, slot)
    C_Container.PickupContainerItem(item.bag, item.slot)
    if not CursorHasItem() then return false end
    EquipCursorItem(slot)
    -- The client may have put the off-hand item in the original bag slot.
    -- Never swap that item back onto the cursor: find a genuinely empty slot.
    if CursorHasItem() then
        local occupied = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if not occupied then C_Container.PickupContainerItem(item.bag, item.slot)
        else
            local _, free = A.Bags()
            if free then C_Container.PickupContainerItem(free.bag, free.slot) end
        end
    end
    if CursorHasItem() then F:Say(F.L["An item remains on your cursor. Place it in a bag before continuing."]) end
    return true
end
function E:Equip()
    if not self:Guard() then return end
    self:Scan()
    if not self:ReadableEquipment() then return end
    if self.main and self.main.pole then F:Say(F.L["A fishing pole is already equipped."]); return end
    if F.db.equipment then F:Say(F.L["Restore your saved equipment before starting another equipment swap."]); return end
    local pole = self.selected
    if not pole or not pole.bag then F:Say(F.L["No available fishing pole in your bags."]); return end
    if self.off and not self.empty then F:Say(F.L["Free a regular bag slot for your off-hand item first."]); return end
    F.db.equipment = { main = self.main, off = self.off, created = time(), phase = "equipping" }
    self.pendingEquip = true
    self:Swap(pole, 16)
    self.pendingEquip = false
    F:Refresh()
end
function E:Restore(quiet)
    if not self:Guard() then return end
    self:Scan()
    if not self:ReadableEquipment() then return end
    local snapshot = F.db.equipment
    if snapshot and snapshot.phase == "equipping" and not snapshot.poleObserved then
        F:Say("Waiting for the client to confirm pole equip. Your weapons are still saved."); return
    end
    local step, message = M.RestoreStep(F.db.equipment, { [16] = self.main, [17] = self.off }, self.items)
    if not step then F:Say(F.L[message]); return end
    F.db.equipment.phase = "restoring"
    if step.done then F.db.equipment = nil
    elseif step.empty then
        if not self.empty then F:Say(F.L["Free a regular bag slot before restoring an empty equipment slot."]); return end
        PickupInventoryItem(step.slot)
        if CursorHasItem() then C_Container.PickupContainerItem(self.empty.bag, self.empty.slot) end
    else self:Swap(step.item, step.slot) end
    F:Refresh()
    if F.db.equipment and not quiet then F:Say(F.L["Restore is incomplete. Clear any locked items and click Swap back again."]) end
end
function E:Toggle()
    if not self:Guard() then return end
    self:Scan()
    if F.db.equipment then
        -- Preflight both original instances before making any changes.
        for _, wanted in pairs({ F.db.equipment.main, F.db.equipment.off }) do
            if type(wanted) == "table" and not M.Same(wanted, self.main) and not M.Same(wanted, self.off) then
                local count = 0
                for _, item in ipairs(self.items) do if M.Same(wanted, item) and not item.locked then count = count + 1 end end
                if count ~= 1 then F:Say("A saved weapon is missing, locked, or ambiguous. Your snapshot is retained."); return end
            end
        end
        -- All actions occur in this one hardware click, never in timers or events.
        for _ = 1, 3 do
            if not F.db.equipment or CursorHasItem() then break end
            local beforeMain, beforeOff = self.main, self.off
            self:Restore(true)
            if M.Same(beforeMain, self.main) and M.Same(beforeOff, self.off) then break end
        end
        if F.db.equipment then F:Say("Swap back paused. Your saved weapons are retained; click again when the item lock clears.") end
    elseif self.main and self.main.pole then
        F:Say("No previous weapons were saved. Equip your weapons manually once, then use Fishcraft to switch to the pole.")
    else self:Equip() end
    F:Refresh()
end
