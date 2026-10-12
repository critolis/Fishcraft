local _, F = ...
local Z = {}
F.Locations = Z
function Z:Names()
    local set, list = {}, {}
    for zone in pairs(F.Data.zones) do set[zone]=true end
    local current = F.API.Zone(); set[current]=true
    for _, row in pairs(F.db.collection) do for zone in pairs(row.zones) do set[zone]=true end end
    for name in pairs(set) do list[#list+1]=name end
    table.sort(list); return list
end
function Z:ForFish(id)
    local ref, owned = F.Data.fish[id], F.db.collection[id]
    local set, list = {}, {}
    if ref then for _, zone in ipairs(ref.zones) do set[zone]="Database" end end
    if owned then for zone in pairs(owned.zones) do set[zone]="Personal catch" end end
    for zone, confidence in pairs(set) do list[#list+1]={name=zone, confidence=confidence} end
    table.sort(list, function(a,b) return a.name<b.name end); return list
end
function Z:Summary(zone)
    local ref = F.Data.zones[zone]
    local lines = { "Exact water requirement: unknown" }
    if ref and ref.guideSkill then lines[#lines+1] = "Guide skill: "..ref.guideSkill.." (zone-level advice, not a water threshold)" end
    local rows = F.Collection:Rows("",zone,true)
    for i=1,math.min(3,#rows) do
        local r=rows[i]; lines[#lines+1]=r.name .. (r.owned and r.owned.zones[zone] and " · personally caught" or " · database listing")
    end
    if #rows==0 then lines[#lines+1]="No verified catches listed yet. Your discoveries will appear here." end
    return lines
end
