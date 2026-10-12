# Changelog

## 1.0.0 — 11 October 2026

- Make Most catches the default Discoveries sort; retain discovered-first grouping and optional name/date sorts.
- Gray out uncaught fish names and desaturate their icons without disabling discovery details.
- Add subtle lifetime catch badges: 10+ green, 100+ blue, 500+ purple, 1,000+ amber-gold; counts below 10 remain neutral.
- Show achieved and next catch milestones in row tooltips; repeat the count badge on fish detail pages. Colors indicate personal progress, not item quality.
- Preserve existing catch history and preferences. No SavedVariables schema change.
- Pass 163 offline behavioral tests. Native client appearance still requires verification.

## 0.9.0 — 11 October 2026

- Add independent Compact / Comfortable / Large body-text sizing, defaulting to +1 px, and brighten secondary text. Enlarge the tracker slightly to accommodate larger text.
- Make the current section the primary heading, retain smaller Fishcraft branding, and distinguish selected navigation and primary actions from quieter secondary borders.
- Move Cooking advice into a prominent Next step card directly above the recipe list; align estimated, held and remaining quantities in separate columns. Calculation behavior is unchanged.
- Replace zone-by-zone stepping with an in-window searchable selector, including paging, Enter selection, Escape dismissal, fish-specific scope and All locations reset. Keep current-location access.
- Add fish icons and compact reference/personal badges to location rows. Keep notes near short lists and hide single-page catch pagination.
- Add original gold clock, fish, checkmark, rate, stopwatch, session-log and collection textures to Statistics. Keep the existing hook for casts.
- Strengthen radial label outlines and add a restrained hover halo. Preserve the compact dial geometry and animation timing.
- Leave tooltip positioning unchanged following clarification that the recording was cropped.
- Pass 160 behavioral tests across 24 modules. Approximate larger-text layouts reviewed; native client verification remains pending.

## 0.8.3 — 11 October 2026

- Fix Stop silently disabling future automatic sessions: retire the persisted stop latch and clear old values on upgrade. With auto-start enabled, the next new cast begins a new session. Explicit Pause and disabled preferences remain respected.
- Observe Fishing channel-start as well as spell-success events. Share recognized Fishing IDs across session, collection and outcome handlers so event rank differences do not block tracking.
- Deduplicate both event orders without resetting loot slots or cast timing. Preserve the last observed cast GUID across Stop/Start so delayed duplicate events cannot reopen a stopped session.
- Verify immediate green Play → red Stop texture/label updates on automatic start; protected refreshes remain deferred in combat.
- Extend `/fc diag` with session state, recording/auto-start preferences and the last recognized Fishing event and spell ID.
- Pass 152 behavioral tests across 24 Lua modules, including nine new auto-start regressions. Native Forever verification remains pending.

## 0.8.2 — 11 October 2026

- Increase the six radial action icon textures by 10% inside their existing frames.
- Reduce radial layout radii and the animation's shared lift height by 10%. Inset corner arc endpoints by two degrees to keep labels separated.
- Preserve launcher/minimap sizes, labels, hit areas and animation timing. All 143 existing tests pass, including layout and animation bounds across screen sizes, scales and anchors. Native visual verification remains pending.

## 0.8.1 — 11 October 2026

- Show a green play triangle for Start session and a red stop square for Stop session. Keep the existing labels and gold dial frame; remove the extra recording dot from this button so its color is unambiguous.
- Include original transparent, antialiased TGA symbols and their reproducible texture generator.
- Session behavior is unchanged. The existing 143 behavioral tests pass; native client visual verification remains pending.

## 0.8.0 — 11 October 2026

- Exclude active casts from success rate until resolved; display pending count. Match channel outcomes by player, Fishing spell and cast GUID, with a three-second loot grace and forty-second missing-event fallback.
- Hold verified open bobber loot pending, deduplicate outcomes, and permit late recovery to correct the same outcome. Exclude unfinished outcomes at recording boundaries and preserve previous aggregate denominators.
- Replace the Statistics radial shortcut with a clock-icon Start/Stop session action, live label and recording indicator. Statistics stays in the Journal window navigation.
- Manual Stop saves and suppresses automatic start until an explicit Start, including across reloads. Existing Pause and Save session controls retain their distinct behavior.
- Add General Settings idle stop: Off / 2 / 5 (default) / 10 minutes. Archive at the activity deadline even after a delayed tick; automatic restart still respects the auto-start preference.
- Pass 143 behavioral tests across 24 Lua modules. Native Forever event order and rendering still require client validation.

## 0.7.0 — 11 October 2026

- Sort caught discoveries before unseen entries in every sort mode; preserve name/date ordering within groups.
- Default Cooking Planner to live base skill and current training cap, refreshed when opened and on skill/profession/bag/known cooking-cast events.
- Recalculate remaining guide estimates and bag deficits dynamically. Prioritize learning/checking the current recipe, cooking fish already held, and then gathering the estimated remainder.
- Retain the requested target beyond the current cap, stop actionable counts at the cap, and keep unsupported coverage above 225 explicit.
- Hide stale estimates when live skill is unreadable. Keep an explicit Manual scenario mode and preserve draft targets during background refreshes.
- Pass 126 behavioral tests across 24 Lua modules. In-client validation remains pending.

## 0.6.0 — 11 October 2026

- Replace independent overlapping main panels with one opaque Fishcraft window and left navigation for Discoveries, Locations, Cooking, Statistics and Settings.
- Route dial/slash shortcuts through the same frame. Add bounded Back navigation for fish/location/recipe paths; retain section controls and state.
- Move session history into Statistics. Use one shared X/Escape close target, remembered window position and short reduced-motion-aware section fades.
- Add an optional independently positioned tracker for session time/items, lure status and Cooking goal. Pin from sidebar/General Settings or `/fc tracker`; it stays visible when the main window closes.
- Pass 117 offline tests across 24 Lua modules. Native client rendering and input checks remain pending.

## 0.5.0 — 11 October 2026

- Remove source URL buttons, tooltip links and the Data source popup. Location fish rows open journal details; provenance remains in data files and documentation.
- Redesign Statistics as eight cards with Lifetime / Current session views: time, casts, items, success, items/hour, cast-to-loot duration, sessions and unique catches.
- Persist lifetime aggregates independently of the last 30 sessions. Migrate available older totals once; do not invent missing outcomes or timing.
- Tie newly recovered items to their recorded cast/session, count success/timing once per cast, and exclude paused or changed-session loot from new session statistics.
- Pass 109 behavioral tests across 23 Lua modules. In-client checks remain pending.

## 0.4.1 — 11 October 2026

- Replace the radial fade/short slide with a shared upward lift followed by a curved fan from twelve o’clock: 0.42-second opening, 0.30-second reverse closing.
- Fade labels/status dots in after separation, disable action hit areas during motion, and reverse rapid toggles without position jumps.
- Bound the full motion path near screen edges; retain immediate reduced-motion behavior and combat guards.
- Pass 100 offline behavioral checks, including staging, full-path bounds, interrupted toggles and combat interruption. In-client animation feel/rendering remains to be checked.

## 0.4.0 — 11 October 2026

- Expand Journal → Discoveries to 23 sourced fish records, including Whimsyfin, eight additional ordinary fish, three bloated fish and three quest-designated rare fish.
- Add category and caught/unseen filters, name/current-zone filtering, name/date sorting and catalog discovery progress.
- Open fish details inside the journal with first/latest dates, personal locations, reference listings and copyable item/rare-quest sources.
- Preserve historical counts and dates; capture first zone/subzone for newly discovered fish without reconstructing missing older history.
- Paginate larger location catch lists. Keep all six radial actions.
- Keep unknown locations and event conditions explicit; import no guessed drop rates, camp prerequisites or Classic comment data.
- Pass 96 behavioral checks across 22 Lua modules. In-client validation remains pending.

## 0.3.0 — 11 October 2026

- Add Fishing Skill Optimizer inside Settings and existing hook/lure/location tooltips: live skill breakdown, weakest sufficient eligible lure, guide or location-scoped personal target, advice/manual and recommended-button modes, optional keep-lure preference, source links.
- Verify six Forever lure records. Avoid double-counting equipped bonuses and do not hard-code conflicting pole values.
- Replace Cast Fishing with Location Info while retaining six radial actions. The shortcut opens the current zone and clears a prior fish filter.
- Fix loss of weapon snapshots when the client still reports original gear immediately after requesting pole equip. Retain snapshots until a requested restoration is confirmed.
- Auto-start sessions on the first Fishing cast; add live current-session timer/counts and session controls to Statistics. Respect manual Pause and recording settings, exclude offline time and avoid double-counting saved sessions.
- Add snapshot phase diagnostics. Extend the suite to 84 checks across 19 modules, including delayed equipment reads.

## 0.2.0 — 11 October 2026

- Fix panel X hit testing: exclude the close-button area from the drag header and raise the button.
- Make the radial pole action a direct toggle. Save both original weapon slots before equipping; restore both within the same click when the client permits. Retain pending snapshots on missing/locked items.
- Move preferred pole/lure selection into Settings → Equipment & lures; keep /fc gear as a shortcut.
- Add recovered-bobber-loot recording, first/latest catches, per-zone history, searchable collection and separate unclassified fishing loot.
- Add eight sourced fish records, reference fishing locations, personal location observations and source links.
- Add a four-recipe Cooking Planner covering skill 1–225, guide-based estimates, optional reserve, bag counts, recipe knowledge and a tracked tooltip checklist.
- Add /fc locations and /fc cooking.
- Migrate SavedVariables to schema 2, retaining existing settings, sessions and weapon snapshots.
- Record the user's later optimizer, camp, discoveries, buff, tournament, legacy, progression, advisor and Smart Fishing Location ideas in the roadmap.
- Expand offline Lua 5.1 tests from 38 to 62 behavioral checks.

## 0.1.0 — 11 October 2026

Initial modular alpha: compatibility research, original circular art, six-action radial UI, adaptive geometry, secure casting/lure controls, equipment snapshots/preferences, session journal, statistics, settings and 38 offline behavioral checks.
