local _, F = ...
local L = {}
F.Lures = L
function L:Scan()
    self.items = {}
    for _, id in ipairs(F.Data.lureIDs) do
        local candidate
        for _, item in ipairs(F.Equipment.items or {}) do
            if item.id == id and not item.locked then
                if not candidate then
                    candidate = {}
                    for k, v in pairs(item) do candidate[k] = v end
                    self.items[#self.items + 1] = candidate
                else candidate.count = (candidate.count or 0) + (item.count or 0) end
            end
        end
    end
    self.manual = F.Model.Choose(self.items, F.db.settings.preferredLure)
    self.selected = self.manual
    self.active, self.remaining = F.API.Enchant()
    self.checkedAt = GetTime()
end
function L:Status()
    if not F.Equipment.main or not F.Equipment.main.pole then return F.L["Equip a fishing pole first"] end
    if self.active == nil then return F.L["Lure status unavailable"] end
    if self.active then
        local remaining = self.remaining and math.max(0, self.remaining - (GetTime() - self.checkedAt))
        if remaining then return string.format(F.L["Enchantment active · %d min"], math.ceil(remaining / 60)) end
        return F.L["Enchantment active"]
    end
    if F.db.optimizer.enabled and F.db.optimizer.useRecommended then return F.Optimizer:Message(F.Optimizer:Evaluate()) end
    local d=self.selected and F.Data.lures[self.selected.id]
    local skill=F.API.SkillSnapshot()
    if d and skill and skill.rank<d.minimum then return "Selected lure requires base Fishing "..d.minimum end
    return self.selected and (self.selected.name .. " · " .. (self.selected.count or 0)) or F.L["No recognized lures in your bags"]
end
function L:Configure(button)
    if F.API.Locked() then return end
    button:SetAttribute("type", nil)
    button:SetAttribute("macrotext", nil)
    local pole = F.Equipment.main
    local data = self.selected and F.Data.lures[self.selected.id]
    local skill = F.API.SkillSnapshot()
    if F.compatible and pole and pole.pole and self.active == false and self.selected and data and skill and skill.rank>=data.minimum and CursorHasItem and not CursorHasItem() then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", "/use [nocombat] " .. self.selected.bag .. " " .. self.selected.slot .. "\n/use [nocombat] 16")
    end
end
