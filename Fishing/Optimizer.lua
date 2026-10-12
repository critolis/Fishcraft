local _, F = ...
local O = {}
F.Optimizer = O
-- Pure choice: minimum sufficient verified bonus; preference only breaks ties.
-- Never spend a lure which cannot reach the requested target.
function O:Choose(rank, effective, target, items, preferred, keepLure)
    local best, bestData, usable, maximum = nil,nil,0,0
    if effective >= target and not keepLure then return nil,"enough",0 end
    for _, item in ipairs(items) do
        local d=F.Data.lures[item.id]
        if d and not item.locked and (item.count or 0)>0 and rank>=d.minimum then
            usable=usable+1;maximum=math.max(maximum,d.bonus)
            if effective+d.bonus>=target then
                if not best or d.bonus<bestData.bonus or
                    (d.bonus==bestData.bonus and item.id==preferred and best.id~=preferred) or
                    (d.bonus==bestData.bonus and best.id~=preferred and item.id~=preferred and item.id<best.id) then
                    best,bestData=item,d
                end
            end
        end
    end
    if best then return best,"recommend",math.max(0,target-effective) end
    return nil,usable==0 and "no_lure" or "short",math.max(0,target-effective-maximum)
end
function O:Target(zone,sub)
    local c=F.db.optimizer
    if c.target and c.zone==zone and c.subzone==sub then return c.target,"Personal target",nil end
    local d=F.Data.optimizerTargets[zone]
    if not d or (d.exclude and (sub=="" or d.exclude[sub])) then return nil,"No sourced target",nil end
    return d.skill,"Guide target",d.source
end
function O:Evaluate()
    local cfg=F.db.optimizer
    local zone,sub=F.API.Zone()
    local skill=F.API.SkillSnapshot()
    local target,label,source=self:Target(zone,sub)
    local r={skill=skill,target=target,label=label,source=source,zone=zone,subzone=sub}
    if not cfg.enabled then r.state="disabled"
    elseif not F.compatible then r.state="unsupported"
    elseif not skill then r.state="unknown_skill"
    elseif not F.Equipment.main or not F.Equipment.main.pole then r.state="equip"
    elseif F.Lures.active==nil then r.state="unknown_enchant"
    elseif F.Lures.active then r.state="active"
    elseif not target then r.state="unknown_target"
    else r.item,r.state,r.shortfall=self:Choose(skill.rank,skill.total,target,F.Lures.items,F.db.settings.preferredLure,cfg.keepLure) end
    return r
end
function O:Refresh()
    self.result=self:Evaluate()
    -- Recommendation mode never rewrites the saved manual preference.
    if F.db.optimizer.enabled and F.db.optimizer.useRecommended then F.Lures.selected=self.result.item
    else F.Lures.selected=F.Lures.manual end
end
function O:Message(r)
    r=r or self.result or self:Evaluate()
    if r.state=="recommend" then
        local d=F.Data.lures[r.item.id]
        return "Use "..d.name.." (+"..d.bonus.."): "..(r.skill.total+d.bonus).." after applying."
    elseif r.state=="enough" then return "Target met without a new lure. Save your lures."
    elseif r.state=="short" then return "Even your strongest usable lure leaves "..r.shortfall.." skill missing. Save it for later."
    elseif r.state=="no_lure" then return "No carried lure meets your base-skill requirement."
    elseif r.state=="equip" then return "Equip your pole first so its actual bonus is included."
    elseif r.state=="active" then return "Keep the active enchantment. Reassess when it expires."
    elseif r.state=="unknown_target" then return "No sourced target here. Set a personal target in Settings > Optimizer."
    elseif r.state=="unknown_enchant" then return "Enchantment status is unknown; lure changes are blocked."
    elseif r.state=="unknown_skill" then return "Fishing skill is unavailable. No bonus is guessed."
    elseif r.state=="unsupported" then return "Optimizer unavailable on this client interface."
    else return "Fishing Skill Optimizer is off." end
end
function O:Lines()
    local r=self:Evaluate();local lines={}
    if not F.db.optimizer.enabled then return lines end
    if r.skill then
        lines[#lines+1]="Effective Fishing: "..r.skill.total.." = "..r.skill.rank.." base + "..r.skill.modifier.." modifier + "..r.skill.temporary.." temporary"
    end
    if r.target then lines[#lines+1]=r.label..": "..r.target.." (not a water guarantee)" end
    lines[#lines+1]=self:Message(r)
    if r.state=="recommend" then lines[#lines+1]=F.db.optimizer.useRecommended and "Lure button: recommended lure; click to apply." or "Advice only; Lure button uses your manual preference." end
    return lines
end
function O:InventoryLines()
    local lines={"Verified Forever lure amounts; base skill determines eligibility."}
    local skill=F.API.SkillSnapshot()
    for _,item in ipairs(F.Lures.items) do
        local d=F.Data.lures[item.id]
        if d then lines[#lines+1]=d.name..": +"..d.bonus..", "..d.seconds/60 .." min, "..(item.count or 0).." carried; requires "..d.minimum..(skill and skill.rank<d.minimum and " (not eligible)" or "") end
    end
    if #lines==1 then lines[#lines+1]="No recognized unlocked lures carried." end
    return lines
end
