# Data provenance — revision 4, checked 11 October 2026

Reference records live in `Data/Forever.lua` and `Data/Discoveries.lua`, separately from per-character observations. Each fish and recipe has a Forever URL, confidence label, check date and target interface 16001. No values are imported from the design screenshots.

## Fish and fishing locations

Twenty-three item records are included: the eight seed records below and [15 Discoveries additions](DISCOVERIES.md), with sources and classification rules. Only structured **Fishing Locations** on the respective Forever item pages seed zone lists. Vendor locations, old comments and a similarly named Classic page do not qualify.

| Item | Source | Included fishing zones |
| --- | --- | --- |
| 6291 Raw Brilliant Smallfish | [Forever item](https://www.wowhead.com/forever/item=6291) | 18 |
| 6289 Raw Longjaw Mud Snapper | [Forever item](https://www.wowhead.com/forever/item=6289) | None verified in inspected listing |
| 6308 Raw Bristle Whisker Catfish | [Forever item](https://www.wowhead.com/forever/item=6308) | None verified in inspected listing |
| 6303 Raw Slitherskin Mackerel | [Forever item](https://www.wowhead.com/forever/item=6303) | None verified in inspected listing |
| 8365 Raw Mithril Head Trout | [Forever item](https://www.wowhead.com/forever/item=8365) | 17 |
| 6358 Oily Blackmouth | [Forever item](https://www.wowhead.com/forever/item=6358) | 21 |
| 6359 Firefin Snapper | [Forever item](https://www.wowhead.com/forever/item=6359) | 14 |
| 6522 Deviate Fish | [Forever item](https://www.wowhead.com/forever/item=6522) | The Barrens |

A database listing establishes a reported zone association, not probability or universal availability across that zone's waters. Source dates do not certify the installed client build.

The [Forever fishing guide](https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling) supplies general skill guidance: 75 for capital cities and 225 for Stranglethorn Vale / Dustwallow Marsh. These values are explicitly separate from exact water requirements. No numerical readiness threshold is shipped.

## Cooking

The [Forever cooking guide](https://www.wowhead.com/forever/guide/professions/cooking/overview-leveling) supplies this initial route:

| Skill band | Recipe spell | Estimated raw fish |
| --- | --- | --- |
| 1–50 | [7751 Brilliant Smallfish](https://www.wowhead.com/forever/spell=7751) | 52 |
| 50–100 | [7753 Longjaw Mud Snapper](https://www.wowhead.com/forever/spell=7753) | 55 |
| 100–150 | [7755 Bristle Whisker Catfish](https://www.wowhead.com/forever/spell=7755) | 55 |
| 150–175 | Same recipe | 65 |
| 175–225 | [20916 Mithril Headed Trout](https://www.wowhead.com/forever/spell=20916) | 55 |

The respective Forever spell pages supply the raw-fish ingredient requirement: one per craft. Cooked output quantity is not the raw ingredient requirement. Recipe item IDs are 6325, 6328, 6330 and 17062. Partial bands prorate the guide estimates and round up; optional reserve adds 20% per band and rounds up. These are not measured probabilities. Cooking 225–300 and alternative routes remain uncovered.

## Personal catches

A player Fishing cast within 40 seconds plus a readable `GameObject` source GUID matching bobber entry **35591** allows observation. That entry comes from [Forever Fishing spell 7620](https://www.wowhead.com/forever/spell=7620/fishing). Items are recorded only as slot quantities decrease or clear; opening a loot window alone records nothing. A source/slot/item ledger deduplicates reopening and repeated events.

[ForeverDB's LootTracker](https://github.com/Imemoth/wow-foreverdb/blob/main/addon/ForeverDB/LootTracker.lua) provides a primary-source example of source GUID/count pairs and loot API use. Fishcraft implements its own stricter attribution logic. In-client event ordering and additional bobber variants remain to be validated. Unknown or mixed sources are skipped rather than guessed.

Personal records retain count, first/latest time, quality, item link, per-zone counts and latest subzone. New discoveries also retain their first zone/subzone; older records leave those optional fields unknown. Unknown items appear in **All loot**, not automatically as fish. These observations do not infer a required skill.

## Equipment and future data

Six lure bonuses, durations and skill requirements are now checked against Forever item records and the guide: see [OPTIMIZER.md](OPTIMIZER.md). Pole source values conflict, so pole bonuses are read only as part of the client's current skill total. Camp, legacy and tournament values in later feature sketches still require independent verification. Guide targets remain distinct from exact-water requirements.
