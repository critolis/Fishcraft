local _, F = ...
local D = {}
F.Discoveries = D
D.categories = {"All fish", "New in Forever", "Rare catches", "Bloated fish", "All loot"}
D.states = {"All discoveries", "Caught", "Unseen"}
D.sorts = {"Name", "First discovered", "Latest catch", "Most catches"}
D.defaultSort = 4
function D:Milestone(count)
    local reached=0
    for _,threshold in ipairs({10,100,500,1000}) do
        if count<threshold then return reached,threshold end
        reached=threshold
    end
    return reached,nil
end
function D:Tag(ref)
    if not ref then return "Unclassified fishing loot" end
    if ref.newForever then return "New in Forever" end
    if ref.rare then return "Rare fish (quest)" end
    if ref.bloated then return "Bloated fish" end
    return "Fish"
end
function D:Rows(query, zone, category, state, sort)
    category, state, sort = category or 1, state or 1, sort or self.defaultSort
    local rows = {}
    for _, r in ipairs(F.Collection:Rows(query,zone,category==5)) do
        local ref=r.ref
        local categoryMatch=category==1 or category==5 or (ref and
            ((category==2 and ref.newForever) or (category==3 and ref.rare) or (category==4 and ref.bloated)))
        local stateMatch=state==1 or (state==2 and r.count>0) or (state==3 and r.count==0)
        if categoryMatch and stateMatch then rows[#rows+1]=r end
    end
    table.sort(rows,function(a,b)
        -- Keep personal discoveries together, including old catches without dates.
        if (a.count>0)~=(b.count>0) then return a.count>0 end
        if sort==4 then
            if a.count~=b.count then return a.count>b.count end
        elseif sort~=1 then
            local key=sort==2 and "first" or "last"
            local av,bv=a.owned and a.owned[key] or 0,b.owned and b.owned[key] or 0
            if av~=bv then return av>bv end
        end
        if a.name~=b.name then return a.name<b.name end
        return a.id<b.id
    end)
    return rows
end
function D:Totals()
    local seen,total,rare,new=0,0,0,0
    for id,ref in pairs(F.Data.fish) do
        total=total+1
        local owned=F.db.collection[id]
        if owned and owned.count>0 then
            seen=seen+1
            if ref.rare then rare=rare+1 end
            if ref.newForever then new=new+1 end
        end
    end
    return seen,total,rare,new
end
function D:Date(value)
    return type(value)=="number" and value>0 and date("%d %b %Y %H:%M",value) or "Not recorded"
end
