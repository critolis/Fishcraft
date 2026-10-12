local _, F = ...
local C = {}
F.Cooking = C
-- Band-specific guide estimates account for decreasing skill-up efficiency.
-- Partial bands are prorated estimates, never exact probabilities or guarantees.
function C:Build(current, target, buffer)
    current = math.floor(F.Model.Number(current,1,1,300))
    target = math.floor(F.Model.Number(target,current,1,300))
    local plan={rows={}, current=current, target=target, covered=math.min(target,225), complete=target<=225, total=0}
    if target<=current then plan.complete=true;plan.covered=current;return plan end
    for _, band in ipairs(F.Data.route) do
        local first,last=math.max(current,band.from),math.min(target,band.to)
        if last>first then
            local recipe=F.Data.recipes[band.recipe]
            local need=math.ceil((last-first)/(band.to-band.from)*band.estimate)
            if buffer then need=math.ceil(need*1.2) end
            local row=plan.rows[#plan.rows]
            if row and row.recipe.id==recipe.id then row.to=last;row.need=row.need+need
            else row={from=first,to=last,recipe=recipe,need=need};plan.rows[#plan.rows+1]=row end
            plan.total=plan.total+need
        end
    end
    return plan
end
function C:Count(id)
    local count=0
    for _,item in ipairs(F.Equipment.items or {}) do if item.id==id then count=count+(item.count or 0) end end
    return count
end
function C:Known(id)
    local info=F.API.Try(C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo,id)
    if info and F.API.Readable(info.learned) and type(info.learned)=="boolean" then return info.learned end
    local known=F.API.Try(C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell or IsSpellKnown,id)
    if known==true then return true end
    return nil -- A false spellbook result is not proof a profession recipe is unlearned.
end
function C:ReadSkill()
    local info=F.API.Try(C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID,185)
    if type(info)~="table" then return nil end
    local rank=info.rank
    if not F.API.Readable(rank) or type(rank)~="number" or rank~=rank or rank<1 or rank>300 or rank~=math.floor(rank) then return nil end
    local maximum=info.maxRank
    if not F.API.Readable(maximum) or type(maximum)~="number" or maximum~=maximum or maximum<rank or maximum>300 or maximum~=math.floor(maximum) then maximum=nil end
    return {rank=rank,maximum=maximum}
end
function C:Refresh()
    local cfg=F.db.cooking
    self.skill=self:ReadSkill()
    if cfg.auto~=false and not self.skill then
        self.plan={rows={},total=0,complete=false,unavailable=true,target=cfg.target};return
    end
    local current=cfg.auto~=false and self.skill.rank or cfg.current
    if cfg.auto~=false then cfg.current=current end
    local maximum=cfg.auto~=false and self.skill.maximum or nil
    local limit=maximum and math.min(cfg.target,maximum) or cfg.target
    self.plan=self:Build(current,limit,cfg.buffer)
    local plan=self.plan
    plan.target=cfg.target;plan.maximum=maximum;plan.live=cfg.auto~=false
    plan.training=maximum and cfg.target>maximum and current<cfg.target or false
    plan.complete=current>=cfg.target or (cfg.target<=225 and not plan.training)
    if current<cfg.target then plan.covered=math.min(limit,225) end
    local allocated={}
    for _,row in ipairs(self.plan.rows) do
        local id=row.recipe.fish
        local available=math.max(0,self:Count(id)-(allocated[id] or 0))
        row.have=math.min(available,row.need);row.remaining=row.need-row.have
        allocated[id]=(allocated[id] or 0)+row.have
        row.known=self:Known(row.recipe.id)
    end
end
function C:UseCurrentSkill()
    F.db.cooking.auto=true;self:Refresh();return not self.plan.unavailable
end
function C:Advice()
    local plan=self.plan
    if not plan or plan.unavailable then return "Open Cooking to read your skill, or select Manual planning." end
    if plan.current>=plan.target then return "Cooking target reached. Choose a higher target to plan further." end
    if plan.current>=225 then return "The verified fish route ends at Cooking 225; further counts are unavailable." end
    if plan.training and plan.current>=plan.maximum then return "Raise your Cooking cap above "..plan.maximum.." before gathering for the next step." end
    local row=plan.rows[1]
    if not row then return "No verified fish recipe for this skill range." end
    if row.known==false then return "Learn "..row.recipe.name.." before gathering for this step." end
    if row.known==nil then return "Open Cooking to check whether you know "..row.recipe.name.."." end
    local fish=F.Data.fish[row.recipe.fish].name
    if row.have>0 then return "Cook your "..row.have.." "..fish.." first; then reassess the remaining fish.",row.recipe.fish end
    return fish..": about "..row.remaining.." more for Cooking "..row.to.." (estimate)",row.recipe.fish
end
function C:PlanNote()
    local p=self.plan
    if not p or p.unavailable then return "Live Cooking skill is unavailable. No fish counts are suggested.\nOpen Cooking, or switch to Manual for a hypothetical plan." end
    local limit=p.target>225 and "The verified route ends at 225; higher levels are not planned."
        or p.training and ("Plan stops at your current cap of "..p.maximum..". Raise it to continue.")
        or "Counts are guide estimates; skill-ups are not guaranteed."
    return limit.."\n"..(p.live and "Updates with skill and bag changes. Uses carried raw fish only." or "Manual scenario: skill updates will not change the entered starting skill.")
end
function C:GoalText()
    if not F.db.cooking.active then return nil end
    return self:Advice()
end
