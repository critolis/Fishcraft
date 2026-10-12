local _, F = ...
local D = F.Data
D.version = 3
-- Checked against Forever item tooltips and the Forever fishing guide on 2026-10-11.
-- Pole tooltip amounts conflict with the guide: do not populate poleBonuses.
D.lures = {}
for _, row in ipairs({
    {6529,"Shiny Bauble",25,1,600}, {6530,"Nightcrawlers",50,50,600},
    {6811,"Aquadynamic Fish Lens",50,50,600}, {6532,"Bright Baubles",75,100,600},
    {7307,"Flesh Eating Worm",75,100,600}, {6533,"Aquadynamic Fish Attractor",100,100,300},
}) do
    D.lures[row[1]] = {id=row[1],name=row[2],bonus=row[3],minimum=row[4],seconds=row[5],
        source="https://www.wowhead.com/forever/item="..row[1],checked="2026-10-11",interface=16001,
        confidence="Forever item tooltip + guide"}
end
D.optimizerTargets = {}
local function targets(value, names)
    for _, name in ipairs(names) do
        D.optimizerTargets[name]={skill=value,source=D.fishingGuide,checked="2026-10-11",confidence="Guide target"}
    end
end
targets(25,{"Dun Morogh","Durotar","Elwynn Forest","Mulgore","Teldrassil","Tirisfal Glades","Zephras Isle"})
targets(75,{"Darnassus","Ironforge","Stormwind City","Orgrimmar","Thunder Bluff","Undercity"})
targets(225,{"Dustwallow Marsh","Stranglethorn Vale"})
-- Guide targets are never exact-water requirements or readiness guarantees.
-- Stranglethorn's named exception is withheld rather than using the zone default.
D.optimizerTargets["Stranglethorn Vale"].exclude = { ["Jaguero Isle"]=true }
