# Fishing Skill Optimizer — data revision 3

Checked 11 October 2026 for Forever interface 16001. Database verification means checking the Forever records below; it is not a claim of in-client testing on every beta build.

## Verified consumable records

| Lure | Bonus | Base Fishing | Duration | Forever source |
| --- | --- | --- | --- | --- |
| Shiny Bauble | +25 | 1 | 10 min | [6529](https://www.wowhead.com/forever/item=6529/shiny-bauble) |
| Nightcrawlers | +50 | 50 | 10 min | [6530](https://www.wowhead.com/forever/item=6530/nightcrawlers) |
| Aquadynamic Fish Lens | +50 | 50 | 10 min | [6811](https://www.wowhead.com/forever/item=6811/aquadynamic-fish-lens) |
| Bright Baubles | +75 | 100 | 10 min | [6532](https://www.wowhead.com/forever/item=6532/bright-baubles) |
| Flesh Eating Worm | +75 | 100 | 10 min | [7307](https://www.wowhead.com/forever/item=7307/flesh-eating-worm) |
| Aquadynamic Fish Attractor | +100 | 100 | 5 min | [6533](https://www.wowhead.com/forever/item=6533/aquadynamic-fish-attractor) |

The item tooltips and [Forever fishing guide](https://www.wowhead.com/forever/guide/professions/fishing/overview-leveling) agree on these bonuses and minimum skills. Shiny Bauble's base skill 1 comes from the guide. Old item-page comments are not used. Eligibility uses base rank conservatively; the game remains authoritative.

## Skill accounting and conflicting poles

The [Forever C_SkillInfo extraction](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Professions-Crafting/C_SkillInfo.md) declares rank, modifier, tempPoints and maxRank. Fishcraft shows their breakdown and calculates rank + modifier + tempPoints. It requires readable finite fields. Gear and active effects are already included in this total and are not added again. Unapplied food, camps, permanent line upgrades or bag poles are not invented as extra bonuses.

The [Strong Fishing Pole item record](https://www.wowhead.com/forever/item=6365/strong-fishing-pole) currently displays +45 while the guide lists +5. Similar discrepancies exist for Blump and Big Iron. Consequently the numerical pole table stays empty, bag poles are not ranked, and the optimizer asks you to equip your preferred pole before computing advice from the client. This avoids choosing one conflicting source as fact.

## Target confidence

Guide targets are limited to the guide's starter/capital/leveling recommendations: 25, 75 and 225. Their exact zone list is in Data/Optimizer.lua. Stranglethorn's Jaguero Isle exception and an unavailable Stranglethorn subzone suppress the default. No extra locations are inferred from Classic data. Names currently match the English client; unmatched locales remain unknown.

Guide and user-entered targets are explicitly labeled and never represented as exact-water requirements. A personal target is scoped to the exact zone and subzone where entered. Location's radial dot stays amber for a target and gray for unknown; it never claims verified green readiness.

## Choice and application

With a pole equipped and no enchant active, pick the smallest known bonus that reaches the target from the current total. Exclude locked/exhausted/unverified lures and those above base skill. Use manual preference only to break equal-bonus ties, then item ID for stable ordering. This minimizes bonus consumption, not gold cost; prices and future session duration are not modeled.

If already sufficient, recommend no new lure. If the largest eligible bonus is insufficient, report the residual gap without consuming it. Optional keep-lure mode chooses the weakest sufficient lure even when skill is met, for players who want a lure for perks. No perk is inferred or quantified.

Advice-only is the default. Recommended-button mode prepares a secure item macro only for a concrete eligible recommendation. It disables application for unknown targets, sufficient skill, insufficient available boosts, or active/unknown enchantments. Disabling the optimizer returns to manual preferences. A fresh scan and evaluation run before every lure click. No timer/event consumes a lure or equips anything.

## Acceptance

Compare the displayed total with the client before/after equipping a pole, applying a lure, gaining skill and gaining/losing buffs. Check both manual and recommended modes. Different beta behavior must update the adapter/data; it must not be papered over with Classic values.
