local _, F = ...
local D = F.Data
D.version = 4
-- Structured Forever records checked 2026-10-11. No Classic comments, drop rates,
-- event schedules or exact-water requirements are imported.
local function add(id, name, slug, zones, tags)
    local r = { id=id, name=name, zones=zones or {}, checked="2026-10-11", interface=16001,
        source="https://www.wowhead.com/forever/item="..id.."/"..slug,
        confidence="Forever database listing" }
    for key, value in pairs(tags or {}) do r[key]=value end
    D.fish[id]=r
    for _, zone in ipairs(r.zones) do
        D.zones[zone]=D.zones[zone] or {fish={}, confidence=r.confidence, checked=r.checked}
        table.insert(D.zones[zone].fish,id)
    end
end
-- Only the explicit 'New in Forever' marker establishes this category.
add(251524,"Whimsyfin","whimsyfin",{}, {newForever=true,
    note="Marked New in Forever. No fishing-location list is published in this source; personal catches can establish your own locations."})
add(13754,"Raw Glossy Mightfish","raw-glossy-mightfish",{"Azshara","Tanaris","Feralas","The Hinterlands","Stranglethorn Vale"})
add(13890,"Raw Plated Armorfish","raw-plated-armorfish",{"Eastern Plaguelands","Deadwind Pass","Feralas","Winterspring","Silithus","Alterac Valley"})
local inland={"Western Plaguelands","Moonglade","Feralas","The Hinterlands","Eastern Plaguelands","Un'Goro Crater","Azshara","Felwood","Deadwind Pass","Winterspring","Ashenvale","Silithus","Alterac Valley"}
add(13759,"Raw Nightfin Snapper","raw-nightfin-snapper",inland)
add(13760,"Raw Sunscale Salmon","raw-sunscale-salmon",inland)
add(13758,"Raw Redgill","raw-redgill",inland)
add(13422,"Stonescale Eel","stonescale-eel",{"Azshara","Stranglethorn Vale","Tanaris","Feralas","The Hinterlands","Eastern Plaguelands"})
add(21071,"Raw Sagefish","raw-sagefish",{"Hillsbrad Foothills","Ashenvale","Loch Modan","Silverpine Forest","Stonetalon Mountains"})
add(21153,"Raw Greater Sagefish","raw-greater-sagefish",{"Stranglethorn Vale","Alterac Mountains"})
add(6647,"Bloated Bristle Whisker Catfish","bloated-bristle-whisker-catfish",{"Ashenvale","Redridge Mountains","Stonetalon Mountains","Hillsbrad Foothills","Duskwood","Wetlands"},{bloated=true})
add(8366,"Bloated Mithril Head Trout","bloated-mithril-head-trout",{"Dustwallow Marsh","Arathi Highlands","Desolace","Stranglethorn Vale","Alterac Mountains","Swamp of Sorrows","Thousand Needles"},{bloated=true})
add(13891,"Bloated Whitescale Salmon","bloated-whitescale-salmon",{"Winterspring","Eastern Plaguelands","Feralas","Deadwind Pass","Alterac Valley"},{bloated=true})
for _, r in ipairs({
    {19805,"Keefer's Angelfish","keefers-angelfish",8221},
    {19803,"Brownell's Blue Striped Racer","brownells-blue-striped-racer",8225},
    {19806,"Dezian Queenfish","dezian-queenfish",8224},
}) do
    add(r[1],r[2],r[3],{"Stranglethorn Vale"},{rare=true,
        rareSource="https://www.wowhead.com/forever/quest="..r[4].."/rare-fish-"..r[3],
        note="Named Rare Fish by its Forever quest. This is not an item-quality or catch-rate claim. Event availability is not tracked."})
end
