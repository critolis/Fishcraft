# Architecture

The TOC loads **24 Lua modules** using a private addon namespace. Only required SavedVariables, slash commands and named frames enter the global namespace. No external addon libraries are required.

| Module | Responsibility |
| --- | --- |
| Core/Bootstrap | Event dispatch and chat messaging |
| Core/Model | Schema migration, normalization, selection, restore steps and radial geometry |
| Compatibility/API | Guarded client reads, item/spell discovery and compatibility gate |
| Data/Catalog + Data/Forever + Data/Optimizer + Data/Discoveries | Equipment IDs, sourced fish/recipes, verified lure records and labeled guide targets |
| Equipment | Bag cache, exact weapon snapshots and click-driven toggle |
| Lures | Selection, enchantment state and secure macro |
| Fishing/Statistics | Persistent archived totals, session snapshots, cast outcomes and first-recovery timing |
| Fishing/Session | Timing, casts and bounded session history |
| Fishing/Optimizer | Pure weakest-sufficient choice, live skill/target evaluation and tooltip advice |
| Journal/Collection | Bobber attribution, partial recovery, deduplication and collection queries |
| Journal/Discoveries | Category/state queries, discovery totals and date sorting |
| UI/Discoveries | Journal discovery list, filters, fish history and location detail page |
| Locations | Reference/personal zone queries and tooltip summaries |
| Cooking/Planner | Pure estimate calculation, bag allocation and knowledge/skill adapters |
| Localization | English string keys with locale override boundary |
| UI/Theme + Components | Shared colors, artwork, tooltips, controls and draggable panels |
| UI/Panels | Collection/sessions, locations, planner, statistics and settings sections |
| UI/Workspace | Shared main window, section visibility, Back routes, saved placement and optional tracker |
| UI/Radial | Six controls, positioning, animation and secure actions |
| Core/Main | Startup, event wiring, coalesced refresh and commands |

## Persistence

Schema **2** adds `collection` and `cooking` to `ui`, `settings`, `equipment`, `history` and optional `activeSession`. Version 0.3.0 adds optional `optimizer`, `autoStartSession`, equipment phase and session `manualPaused` fields without changing the format of older fields. Version 0.4.0 adds optional collection `firstZone` / `firstSubzone` fields only for new discoveries. Version 0.5.0 adds an optional `statistics` aggregate and per-session measurement/item fields; existing schema 2 records remain readable. Version 0.6.0 adds optional normalized `windowX/Y`, `trackerX/Y`, and `tracker` visibility fields under `ui`. Version 0.7.0 adds `cooking.auto`, default true; existing manual scenarios can be explicitly selected. Version 0.8.0 adds `resolvedCasts`, the manual `sessionStopped` latch, `settings.sessionIdleSeconds` (0/120/300/600), and session `endReason`. Version 0.8.3 retires `sessionStopped`; explicit auto-start and manual Pause preferences remain. Both channel-start and success events share one cast token and deduplication across Stop/Start. Pending cast tokens and activity timestamps are runtime-only; unfinished outcomes are excluded at recording boundaries. Schema 1 migrates additively. Higher schemas block startup rather than being downgraded. Preferences and original item identities survive migration. Saved sessions are capped at 30; lifetime collection records are separate. Reloaded sessions exclude offline time and restart on a Fishing cast unless manually paused or auto-start is disabled.

Original main/offhand links and GUIDs are stored before pole equip. False represents an empty slot. The toggle preflights both originals, then performs up to three synchronous restore steps inside the same click. It stops on no progress, a cursor item or completion. No delayed callback changes gear. Client item locks may require another click. New snapshots have phase `equipping` and must observe the pole before restoration. Only phase `restoring` can be cleared by matching both original slots. This prevents old inventory reads after equip from looking like a completed restoration. Legacy snapshots remain usable. A snapshot already lost by 0.2.0 cannot be reconstructed.

## Catch authority

Collection owns attribution. It combines the player cast, a whitelisted bobber object source, and a reduction in loot-slot contents. Source/slot/item keys prevent repeated events or reopening from duplicating counts. The transient ledger expires entries after ten minutes; persistent records hold aggregate history. `COLLECTION_UPDATED` refreshes UI and statistics. Session item totals increase only while recording.

Reference fish membership and source zones never overwrite observations. Unknown recovered items remain visible under All loot. The 23-record reference list is a partial catalog, not a claim of completeness. The New in Forever marker and Rare Fish quest tags are explicit metadata; item quality does not establish membership. Discovery queries never modify counts or infer missing dates/locations. Location lists paginate all matches.

## Cooking model

`Build(current,target,buffer)` is pure: intersect guide bands, prorate and round estimates, merge consecutive identical recipes, report coverage. `Refresh` adds current carried-bag counts and recipe knowledge. A false spellbook lookup alone does not prove a profession recipe is unlearned. Live mode reads base Cooking rank and the current cap on refresh, including when opening Cooking. It blocks stale estimates if rank is unreadable and plans only through the reported cap. Manual mode keeps an explicit hypothetical rank. The focus stays on the first route step: check recipe, cook carried fish, then gather an estimated deficit. Readable skill/cap and bag changes recalculate the plan; draft target text is retained until applied.

## UI and events

The secure radial visibility driver hides controls in combat. The Lure action is secure; Location Info replaces the old secure Cast action. Lure pre-click rescans recalculate recommendations and eligibility. The five main sections are ordinary child frames of one opaque Fishcraft window, and only one section is shown at a time. Its drag region excludes the shared X area. The independently pinned tracker sits on a lower drawing layer. Only the main window is registered for Escape closing.

Inventory/profession/player-aura events coalesce for 100 ms. The five-second lure timer uses cached bag data and refreshes optimizer advice. A one-second session ticker resolves pending outcomes and archives idle sessions even with all panels closed; delayed ticks archive at the idle deadline. Protected radial refreshes remain combat-guarded. Animation OnUpdate exists only during transitions; session elapsed text updates while Statistics or the pinned tracker is shown. Statistics combines a persistent archived aggregate with the live current session. Saving archives once, so trimming history cannot lower lifetime totals. A cast token binds outcome/timing to its session and uninterrupted recording period. No source popup remains; provenance is kept in data/docs. All panels retain the gold/blue styling.

New systems should consume Collection and Locations results, not independently infer catches. Extend dated reference data before adding readiness or optimization claims.


The radial uses a shared reversible progress value. `Model.RadialPose` maps its first 28% to a shared upward lift and its remainder to a curved fan, clamped to the layout bounds. Labels/status dots fade in late; action hit areas stay disabled until fully open. Reduced motion resolves immediately. No animation OnUpdate persists after completion.

## 0.9.0 presentation

`ui.textSize` is additive to schema 2: Compact=0, Comfortable=1 (default), Large=2. Owned body FontStrings and EditBoxes register with `UI.Components`; refresh changes only their fonts outside combat. Large headings and outlined radial labels retain their sizes. The zone selector is an opaque, raised child of the Locations section, not another root window. It filters the current location scope with literal case-insensitive search; it closes on selection, Escape in its search field, section changes, or main-window close. Current navigation state and tooltip anchors are preserved. Cooking uses the existing `Advice()` result in a next-step card, and row quantities have independent aligned columns.
