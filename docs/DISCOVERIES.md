# Discoveries — Fishcraft 0.4.0

Open Journal → **Discoveries**. This expands the catalog from 8 to **23 sourced fish records**. The denominator is Fishcraft's current catalog, not all fish in Forever.

Click the category control to cycle **All fish → New in Forever → Rare catches → Bloated fish → All loot**. Combine it with a name search, current-zone filter and **All discoveries / Caught / Unseen**. Caught fish always sort before unseen fish. Most catches is the default sort, descending by lifetime count with name and item ID tie-breakers. Sorting cycles Most catches → Name → First discovered → Latest catch. Uncaught entries have gray names and desaturated icons. Caught entries display lifetime count badges: neutral below 10, pastel green at 10+, blue at 100+, purple at 500+, and amber-gold at 1,000+. The tooltip names the achieved threshold and the next target. Badges are personal milestones, not item rarity. The same badge appears on the fish detail page. Entries without dates sort last within their group in date modes. Filters remain when returning from a fish detail page; they reset on reload.

Click a fish for its lifetime count, first/latest catch dates, first discovery location when recorded, reference zones, personal location counts on hover. **Known locations** opens the existing location panel. Use Previous/Next catches to see all entries in a large zone list. Source URLs are retained in this document and the reference data; version 0.5.0 removes them from the game UI.

Existing SavedVariables remain compatible. New catalog entries automatically classify previously unclassified catches by item ID; their counts and dates are retained. First location/subzone are recorded for discoveries made from 0.4.0 onward. Older history does not have that information reconstructed. Collection recording still requires recovered loot from a recognized fishing bobber; this feature does not scan bags or award discoveries for merely seeing an item.

## Reference expansion

Checked **11 October 2026**, target interface **16001**, dataset revision **4**. The links below are the item records used by `Data/Discoveries.lua`. Location lists come exclusively from their structured Fishing Locations sections, not comments. See that file for complete zone arrays.

| Item | Category | Reference fishing zones |
| --- | --- | --- |
| [251524 Whimsyfin](https://www.wowhead.com/forever/item=251524/whimsyfin) | New in Forever | None listed; unknown until a source or personal catch establishes one |
| [13754 Raw Glossy Mightfish](https://www.wowhead.com/forever/item=13754/raw-glossy-mightfish) | Fish | 5 |
| [13890 Raw Plated Armorfish](https://www.wowhead.com/forever/item=13890/raw-plated-armorfish) | Fish | 6 |
| [13759 Raw Nightfin Snapper](https://www.wowhead.com/forever/item=13759/raw-nightfin-snapper) | Fish | 13 |
| [13760 Raw Sunscale Salmon](https://www.wowhead.com/forever/item=13760/raw-sunscale-salmon) | Fish | 13 |
| [13758 Raw Redgill](https://www.wowhead.com/forever/item=13758/raw-redgill) | Fish | 13 |
| [13422 Stonescale Eel](https://www.wowhead.com/forever/item=13422/stonescale-eel) | Fish | 6 |
| [21071 Raw Sagefish](https://www.wowhead.com/forever/item=21071/raw-sagefish) | Fish | 5 |
| [21153 Raw Greater Sagefish](https://www.wowhead.com/forever/item=21153/raw-greater-sagefish) | Fish | 2 |
| [6647 Bloated Bristle Whisker Catfish](https://www.wowhead.com/forever/item=6647/bloated-bristle-whisker-catfish) | Bloated | 6 |
| [8366 Bloated Mithril Head Trout](https://www.wowhead.com/forever/item=8366/bloated-mithril-head-trout) | Bloated | 7 |
| [13891 Bloated Whitescale Salmon](https://www.wowhead.com/forever/item=13891/bloated-whitescale-salmon) | Bloated | 5 |
| [19805 Keefer's Angelfish](https://www.wowhead.com/forever/item=19805/keefers-angelfish) | Rare fish | Stranglethorn Vale |
| [19803 Brownell's Blue Striped Racer](https://www.wowhead.com/forever/item=19803/brownells-blue-striped-racer) | Rare fish | Stranglethorn Vale |
| [19806 Dezian Queenfish](https://www.wowhead.com/forever/item=19806/dezian-queenfish) | Rare fish | Stranglethorn Vale |

Whimsyfin's **New in Forever** classification uses the explicit marker on its item record. An imported record's patch number alone does not qualify it as a new fish.

Rare classification comes from the named Forever quests: [Keefer's Angelfish](https://www.wowhead.com/forever/quest=8221/rare-fish-keefers-angelfish), [Brownell's Blue Striped Racer](https://www.wowhead.com/forever/quest=8225/rare-fish-brownells-blue-striped-racer), and [Dezian Queenfish](https://www.wowhead.com/forever/quest=8224/rare-fish-dezian-queenfish). It is independent of item quality and does not assert a drop chance. Unknown blue/purple fishing loot remains under All loot and does not inflate fish totals.

Bloated is a separate category, not a rarity claim. No contents, camp prerequisites, tournament schedules, time-of-day restrictions, rates or exact-water thresholds are inferred. A zone listing is not a guarantee that every water there yields that fish. Reference data and personal observations remain separate. Client validation is still required.
