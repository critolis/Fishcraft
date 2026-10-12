# Compatibility research — 11 October 2026

## Target and evidence

Fishcraft targets **Forever 1.60.1 / interface 16001**. The developer's own client was not available. The exact installed build therefore remains unverified. The following are inspected primary project artifacts, not proof that Fishcraft runs in-game:

1. [Forever client API extraction](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md): identifies extraction build **70170**, interface **16001**, dated 1 October 2026. API declarations establish names and return structures, not permission to invoke protected actions.
2. [ForeverOneKeyFishing developer README](https://github.com/jBeyondstars/ForeverOneKeyFishing): declares interface 16001, documents development client 1.60.1.69913 and developer-reported casting. Its source demonstrates modern spellbook discovery and secure spell buttons. Fishcraft uses no interaction key rebinding or CVars from that implementation.
3. [Forever Angler source](https://github.com/tobarisu1/wow_forever_addons/blob/main/Angler/Angler.lua): demonstrates `C_Item` fishing-pole classification, `C_PaperDollInfo.GetTemporaryEnchantmentInfo`, and a physical-click lure macro. Its six lure IDs are candidate identifiers, not independently verified bonuses.
4. [Blizzard SecureTemplates source mirror, live branch](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua): supports secure spell/item/macro dispatch, including `macrotext`. Mainline source is a cross-check; it cannot prove Forever-specific restrictions.

Runtime `GetBuildInfo()` must return interface 16001 before Fishcraft configures gameplay actions. Missing secure state-driver support also disables gameplay controls. This is a narrow compatibility gate, not a claim that every build sharing the interface is verified. `/fc diag` reports build, interface, resolved spell, and inventory counts. Do not identify Forever solely by `WOW_PROJECT_ID`.

## Feasibility matrix

| Feature | Inspected API/pattern | Implementation and confidence | Remaining verification |
| --- | --- | --- | --- |
| Addon loading/persistence | TOC 16001, SavedVariablesPerCharacter, PLAYER_LOGIN/LOGOUT | Implemented; standard event lifecycle | Actual login, reload and logout persistence |
| Native UI and styling | CreateFrame, BackdropTemplate, textures, font strings, mask textures | Implemented; WoW patterns and offline frame mock | Native asset paths, font rendering, alpha masks |
| Animation | Temporary OnUpdate easing, no animation-group requirement | Implemented; stops after each transition | Frame behavior during combat transition |
| Radial geometry | UIParent dimensions, scales, normalized saved position | Implemented; geometry tested at 4 resolutions × 3 scales × 9 anchors | Actual anchors, UI scale/resolution changes and other UI mods |
| Combat visibility | SecureHandlerStateTemplate, RegisterStateDriver | Implemented; `[combat] hide; show` | Client taint and state transitions, combat while dragging |
| Fishing discovery | C_SpellBook and C_Spell | Localized spell resolution for session/catch events; cast shortcut replaced by Location Info in 0.3.0 | Learned ranks/locales and channel start events |
| Bag/item discovery | [C_Container](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Items-Inventory/C_Container.md), [C_Item](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Items-Inventory/C_Item.md) | Names and signatures source-confirmed; runtime guards and coalesced scans | Uncached items, locks, new Forever-specific gear classes |
| Pole classification | Weapon class 2 / fishing-pole subclass 20 | Matches Forever Angler pattern | Pole variants and possible profession-tool slots |
| Equip / restore | ItemLocation, C_Item.GetItemGUID, PickupInventoryItem, EquipCursorItem, C_Container.PickupContainerItem | Implemented only on explicit clicks outside combat; capability checks | Cursor/equip semantics and restrictions in actual Forever client |
| Strongest pole | Verified bonus table or explicit preference | Preference implemented; bonus table intentionally empty | Verified client-specific bonuses and eligibility data |
| Fishing Skill Optimizer | C_SkillInfo, six sourced Forever lure records, guide/personal targets | Implemented inside Settings/tooltips; weakest eligible sufficient lure, optional recommended-button mode | Live skill field semantics, lure use eligibility, exact-water target coverage; conflicting pole values excluded |
| Lure state/timer | [C_PaperDollInfo](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Player-Character/C_PaperDollInfo.md): remainingTimeMs | Declaration source-confirmed; nil/secret/error guarded | Whether every lure appears as a temporary enchantment |
| Lure use | Secure macro `/use [nocombat] bag slot`, then slot 16 | Implemented; pre-click rescan; active/unknown state blocks | Macro permissions, eligibility, timing, no unnecessary consumption |
| Location | GetRealZoneText, GetSubZoneText | Live display implemented | Zone/subzone variations |
| Fishing skill | [C_SkillInfo.GetSkillLineInfoByID](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Professions-Crafting/C_SkillInfo.md), ID 356 | rank/modifier/tempPoints source-confirmed; neutral fallback | Whether all gear/buff bonuses appear in these fields |
| Sessions | UNIT_SPELLCAST_CHANNEL_START / UNIT_SPELLCAST_SUCCEEDED player + recognized Fishing rank + GUID deduplication | Cast/time tracking implemented | Cast event meaning: successful spell start is not a fish caught |
| Catch attribution | GetLootSourceInfo, GetLootSlotInfo/Link, LOOT_READY/OPENED, LOOT_SLOT_CHANGED/CLEARED; [ForeverDB pattern](https://github.com/Imemoth/wow-foreverdb/blob/main/addon/ForeverDB/LootTracker.lua) | Implemented: recent player cast + object 35591 source + recovered quantity; partial/repeated events tested | Actual bobber GUID and event order, manual/autoloot, additional bobber variants |
| Catch journal | SavedVariables schema 2 and sourced item catalog | Counts, dates, zones, search/filtering and pagination implemented | Live catch validation; larger catalog and locales; milestones remain later work |
| Fishing locations | [Forever item listings](https://www.wowhead.com/forever/item=6358), guide and personal records | Zone associations with provenance; exact water requirements unknown | Water-level validation and zone ID/localization mapping |
| Cooking planner | [C_TradeSkillUI](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Professions-Crafting/C_TradeSkillUI.md), C_SkillInfo ID 185 and carried bags | Four sourced recipes, guide estimates through 225, optional reserve, inventory and knowledge display | Profession context/learned flag, live skill query, quantities remain estimates; 225–300 unplanned |

## Boundaries

- No automatic recast, bobber clicking, consumable use, equipment changes, CVar changes, or key rebinding.
- No retail/Classic Era fallback represented as Forever compatibility. Legacy fallback APIs are queried only if present.
- Unknown/secret data is not compared or presented as confirmed. Failed enchant reads disable lure application.
- The art references guide layout, palette and proportions. Their fish tables, requirements, item bonuses, and durations are illustrative and not imported as facts.
- No running client was inspected or modified. A passing local suite does not certify protected gameplay actions or visual fidelity in-game.

## 0.2.0 client follow-up

The user's screenshots show the earlier build running and identify a non-working X and the desired direct pole toggle. This release excludes the X from the drag region and gives it a higher frame level. Restore attempts both weapon slots synchronously in one hardware callback; if live item locks delay the second action, a retained snapshot allows a retry. No equipment operation is deferred to a timer or event. Both fixes require an actual-client check.

Data sources, provenance distinctions and coverage are recorded in [DATA.md](DATA.md). The reference images remain design inputs, not numerical sources.

## 0.3.0 client follow-up

The user demonstrated recovered catches in 0.2.0 and reported lost weapon memory after using the pole button. A delayed-inventory regression now reproduces the unsafe old condition; snapshot clearing requires an explicit restoring phase. Statistics now auto-starts a session on a Fishing cast and displays the current session live. The user's earlier screenshots do not validate the new build.

Lure amounts and requirements now have independent Forever item-page checks, documented in [OPTIMIZER.md](OPTIMIZER.md). Guide targets are advisory. Client-reported skill is used without adding catalog pole values. Verify the displayed breakdown against the actual profession UI and buffs.
