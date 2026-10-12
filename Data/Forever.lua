local _, F = ...
local D = F.Data
D.version, D.checked = 2, "2026-10-11"
D.fishingGuide = "https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling"
D.cookingGuide = "https://www.wowhead.com/forever/guide/professions/cooking/overview-leveling"
-- Only structured Forever fishing-location lists are used, never old comments or vendor lists.
local function fish(id, name, zones)
    D.fish = D.fish or {}
    D.fish[id] = { id = id, name = name, source = "https://www.wowhead.com/forever/item=" .. id,
        confidence = "Forever database listing", checked = D.checked, interface = 16001, zones = zones or {} }
    for _, zone in ipairs(zones or {}) do
        D.zones[zone] = D.zones[zone] or { fish = {}, confidence = "Forever database listing", checked = D.checked }
        table.insert(D.zones[zone].fish, id)
    end
end
fish(6291, "Raw Brilliant Smallfish", { "Elwynn Forest", "Stormwind City", "Mulgore", "Durotar", "Teldrassil", "Tirisfal Glades", "Darnassus", "Orgrimmar", "Darkshore", "The Barrens", "Thunder Bluff", "Silverpine Forest", "Undercity", "Westfall", "Dun Morogh", "Loch Modan", "Duskwood", "Tanaris" })
fish(6289, "Raw Longjaw Mud Snapper")
fish(6308, "Raw Bristle Whisker Catfish")
fish(6303, "Raw Slitherskin Mackerel")
fish(8365, "Raw Mithril Head Trout", { "Western Plaguelands", "Dustwallow Marsh", "Moonglade", "Alterac Mountains", "Stranglethorn Vale", "Feralas", "Arathi Highlands", "The Hinterlands", "Desolace", "Swamp of Sorrows", "Azshara", "Thousand Needles", "Un'Goro Crater", "Felwood", "Ashenvale", "Eastern Plaguelands", "Hillsbrad Foothills" })
fish(6358, "Oily Blackmouth", { "Stranglethorn Vale", "Western Plaguelands", "Moonglade", "Dustwallow Marsh", "Feralas", "Wetlands", "Darkshore", "Westfall", "Azshara", "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Desolace", "Silverpine Forest", "The Barrens", "Arathi Highlands", "Ashenvale", "Un'Goro Crater", "Felwood", "Swamp of Sorrows", "Eastern Plaguelands" })
fish(6359, "Firefin Snapper", { "Stranglethorn Vale", "Azshara", "Dustwallow Marsh", "Wetlands", "Tanaris", "Feralas", "Hillsbrad Foothills", "Desolace", "The Hinterlands", "Stonetalon Mountains", "Swamp of Sorrows", "Arathi Highlands", "Ashenvale", "The Barrens" })
fish(6522, "Deviate Fish", { "The Barrens" })
-- Guide-level advice is separate from exact requirements for a body of water.
for _, name in ipairs({ "Darnassus", "Ironforge", "Stormwind City", "Orgrimmar", "Thunder Bluff", "Undercity" }) do
    D.zones[name] = D.zones[name] or { fish = {} }
    D.zones[name].guideSkill, D.zones[name].guideSource = 75, D.fishingGuide
end
for _, name in ipairs({ "Stranglethorn Vale", "Dustwallow Marsh" }) do
    D.zones[name].guideSkill, D.zones[name].guideSource = 225, D.fishingGuide
end
-- Recipe ingredients from the respective Forever spell pages. Difficulty thresholds
-- are NOT imported from Classic comments. The route's estimates vary by skill band.
for _, r in ipairs({
    {7751,6325,6291,"Brilliant Smallfish",1},
    {7753,6328,6289,"Longjaw Mud Snapper",50},
    {7755,6330,6308,"Bristle Whisker Catfish",100},
    {20916,17062,8365,"Mithril Headed Trout",175},
}) do
    D.recipes[r[1]] = { id=r[1], recipeItem=r[2], fish=r[3], name=r[4], minimum=r[5], ingredients={ [r[3]]=1 },
        source="https://www.wowhead.com/forever/spell="..r[1], confidence="Forever recipe + guide", checked=D.checked, interface=16001 }
end
D.route = {
    { from=1, to=50, recipe=7751, estimate=52 }, { from=50, to=100, recipe=7753, estimate=55 },
    { from=100, to=150, recipe=7755, estimate=55 }, { from=150, to=175, recipe=7755, estimate=65 },
    { from=175, to=225, recipe=20916, estimate=55 },
}
D.bobbers = { [35591] = true } -- Fishing spell 7620, Forever: Summon Object 35591.
D.bobberSource = "https://www.wowhead.com/forever/spell=7620/fishing"
