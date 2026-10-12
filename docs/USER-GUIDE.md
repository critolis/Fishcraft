# Fishcraft 1.0.0

**A quiet companion for every cast.** A modular fishing addon for World of Warcraft: Forever, targeting interface **16001**.

Version 1.0.0 adds achievement-style Discoveries: muted gray uncaught fish, most-caught ordering by default, and pastel lifetime catch badges at 10, 100, 500 and 1,000 catches. Independent body-text sizing, prominent section headings, a Cooking next-step card, searchable locations, and semantic Statistics icons remain included. Active casts stay out of the success-rate denominator; the dial includes Start/Stop session with automatic start and configurable idle stopping. Discovered-first ordering, live Cooking planning, the shared window and tracker remain included. This release passes 163 offline tests and still needs in-client validation.

## Install or update

1. Close the Forever client.
2. Extract the archive and replace the old `Interface/AddOns/Fishcraft` folder with the included **Fishcraft** folder. Check that `Interface/AddOns/Fishcraft/Fishcraft.toc` exists without an extra nested folder.
3. Keep your existing character SavedVariables. Schema 1 upgrades automatically to schema 2, preserving preferences, sessions and saved weapons.
4. Start the client, enable Fishcraft, and type `/fc`. Use `/fc diag` to report the build and interface when troubleshooting.

No external addon libraries are required. Python dependencies are only for development.

## Controls

| Control | Action |
| --- | --- |
| Left-click hook | Expand/collapse six radial actions |
| Right-click hook | Open Settings |
| Drag hook | Move launcher, unless locked |
| Fishing pole | Save main/off hand and equip the preferred bag pole |
| Swap back | Restore saved main/off hand in the same click |
| Lure | Apply selected lure when a pole is equipped and no temporary enchantment is active |
| Location info | Open the current fishing location, clearing any previous fish filter |
| Journal | Discoveries in the shared Fishcraft window |
| Start / Stop session | Start or resume recording; Stop saves it; the next cast starts another when auto-start is enabled |
| Journal → Statistics | Lifetime/current time, casts, items, success rate, items/hour, cast-to-loot time, sessions and unique catches |
| Settings → Equipment & lures | Choose preferred pole and lure |
| X / Escape | Close the main window; a pinned tracker stays visible |
| Pin tracker / `/fc tracker` | Toggle the compact session/lure/cooking tracker |

The six action icons are 10% larger inside their existing frames, and the menu radius is 10% smaller. Corner endpoints are slightly inset to preserve label spacing. The dial opens in 0.42 seconds: icons rise together above the hook, then fan along curved paths into their positions. Labels fade in as the fan settles. Closing reverses the motion in 0.30 seconds. Rapid toggles reverse from the current position; action buttons accept clicks only after opening completes. Paths stay inside the screen at edge/corner anchors. **Reduced motion** in General Settings keeps opening/closing immediate.

The radial controls hide in combat. Gear changes run only on a click outside combat. If the client locks an item before the second slot can be restored, the snapshot remains and the next click retries. Missing or ambiguous original weapons block the swap. An already-equipped pole cannot reveal previous weapons: equip your weapons manually once, then use Fishcraft to start tracking swaps.

Pole bonus sources conflict, so pole preferences remain manual. The optimizer uses the client's reported total skill rather than adding a guessed pole bonus. Active or unreadable enchantment state blocks lure replacement. Cast with your normal game action bar/keybind.

If 0.2.0 already lost your weapon snapshot, it cannot be reconstructed. After updating, manually equip your normal weapons once, then click Fishing pole to create a new snapshot. The new snapshot survives delayed inventory reads and clears only after a requested restore is confirmed.

## One window, connected sections

Use the left navigation for **Discoveries, Locations, Cooking, Statistics, Settings**. Dial and slash shortcuts open those sections in the same frame. Fish details and recipe locations have a Back path that retains your prior selection and page; section controls retain their filters and draft input. **Session history** is now under Statistics.

The current section has the main heading, with smaller Fishcraft branding. Selected navigation has a gold marker; secondary controls use softer borders. **Settings → General → Text size** cycles through Compact (original sizes), Comfortable (+1 px, default), and Large (+2 px) without changing window or dial scale. Headings and radial label sizes stay fixed.

Drag the header to move the window; placement is remembered. X/Escape closes it. **Pin tracker** keeps a small session/lure/cooking summary visible while the main window is closed. Enable it from the sidebar, General Settings, or `/fc tracker`; drag its header and use its X to unpin. It is off by default. See [window and tracker behavior](WORKSPACE.md).

## Fishing Skill Optimizer

Open **Settings → Optimizer** or `/fc optimizer`.

- Advice is on by default. The Lure button initially retains your manual preference.
- Switch **Lure button: manual preference** to **recommended** to use the recommended lure on your next click. This does not consume anything automatically or overwrite your saved preference.
- It chooses the weakest carried, unlocked, eligible lure that reaches the target. Base skill determines lure eligibility; current equipped gear/buffs are counted once in the live total.
- If the target is already met, it recommends saving your lures. If even the strongest eligible lure falls short, it shows the remaining gap without preparing that consumable.
- **Keep a lure for perks** optionally recommends a lure even when skill is sufficient. Perks are not automatically detected and their yield is not modeled.
- Sourced guide targets cover starter zones, six capitals, Dustwallow Marsh and ordinary Stranglethorn locations. Stranglethorn with no subzone or at Jaguero Isle has no automatic target.
- A personal target applies only to the exact current zone/subzone. Use **Set for here**, or **Use guide** to remove it.
- Targets are advice, not exact-water catch guarantees. Unknown zones and unreadable skill/enchantment data remain explicit.
- Hover **Carried lure details** for bonuses, duration, quantity and base-skill requirements. The hook, Lure and Location Info tooltips show current advice.

Six lure bonuses/requirements are sourced from Forever item records; pole values are deliberately not hard-coded because the current item pages and guide disagree. See [optimizer data and limitations](OPTIMIZER.md).

## Live sessions

The first player Fishing channel-start or spell-success event starts the session timer by default, including casts from your normal action bar. Known Fishing rank IDs are recognized independently of the single spellbook selection. Duplicate events for one cast share one token and cannot double-count it. Statistics updates the current timer once per second while visible and includes current casts/time in totals. Start/resume, Pause and Save are available there and in Statistics → Session history.

The dial has **Start session / Stop session** in place of Statistics: a green play triangle when stopped and a red stop square while recording. Stop saves and ends the current session. With auto-start enabled, your next new cast starts another and immediately switches the green play icon to red Stop. The old persisted Stop blocker is removed automatically on upgrade; it no longer silently disables auto-start. Statistics remains in the Journal window’s left navigation and at `/fc stats`.

**Settings → General → Auto-stop** cycles through Off, 2, 5 (default), and 10 minutes without fishing activity. Idle stop saves the session and permits the next cast to auto-start another when auto-start is enabled. Recorded time includes the idle allowance, but never additional time beyond its deadline. Casting, a matching channel-end event, and verified loot recovery/closure refresh the activity time.

Manual Pause stays paused until you resume and is not automatically archived. The existing Statistics **Save session** control ends the current session while leaving automatic start available. Turn off **Start session on first Fishing cast** in General Settings for manual sessions. Turn off session recording to disable both. This is elapsed session time, not a per-cast stopwatch, and earlier unrecorded time cannot be recovered.

## Statistics

Choose **Lifetime** or **Current session**. The eight cards show recorded time, casts, item quantities caught, success rate, items/hour, average cast-to-first-loot time, sessions and unique item catches. Hover for definitions.

Lifetime aggregates retain available older saved-session totals and keep growing beyond the 30-session history limit. Old discarded sessions cannot be recovered. Success, timing and unique-catch metrics begin with new tracking; no historical values are guessed. Success counts one recovered outcome per resolved cast, while Items counts quantities. Active casts remain pending and do not lower the percentage. A matching channel end or recast starts a three-second loot grace period; verified open bobber loot stays pending until recovered or closed. Missing end events use the existing 40-second attribution window as a fallback. Unfinished casts at Pause/Stop/logout are excluded from the rate while remaining in the Casts count. Pause and offline time are excluded. See [metric definitions and upgrade behavior](STATISTICS.md).

Source URLs and source popups no longer appear in game. Clicking a fish in Locations opens its journal entry. All references remain in the documentation and data files.

## Collection and locations

The **Discoveries** tab includes 23 sourced fish records. Cycle categories with the category button: **All fish**, **New in Forever**, **Rare catches**, **Bloated fish**, **All loot**. Combine name search and current-zone filtering with **Caught / Unseen**; caught fish always appear before unseen fish, with most catches first by default (name breaks ties). The sort control also offers name, newest first discovery and latest catch. Uncaught entries have gray names and desaturated icons. Lifetime catch badges are neutral for 1–9, pastel green for 10–99, blue for 100–499, purple for 500–999, and amber-gold for 1,000+. Hover a caught fish for its milestone and progress to the next threshold; these colors represent your catch history, not item rarity. Click a fish for dates, personal locations and reference details. Large location lists now have Previous/Next catches controls.

Whimsyfin is the first sourced New in Forever entry; its reference fishing locations remain unknown. Three rare fish use an explicit quest designation, not item quality or guessed catch rates. Existing counts/dates survive the update. First-location details are saved for newly discovered fish; missing older history is not fabricated. See [Discoveries and its 15 added sources](DISCOVERIES.md).

Recording requires a recent player Fishing cast, a recognized bobber source and loot removal. Merely opening a loot window adds nothing. Unknown sources are skipped. Collection recording is independent of starting a session; session item totals increase only while a session runs.

Use the searchable location selector to jump directly to a zone; Enter chooses the first match and Escape dismisses the selector. Fish-specific location browsing keeps its scope until **All locations** is selected. Location rows show fish icons and compact **Personally caught** / **Reference listing** labels, with local catch counts. Single-page catch lists hide unnecessary pagination.

Locations distinguish **Forever database listings** from **personal catches**. Vendor listings do not become fishing locations. Exact water requirements remain unknown: general zone guidance does not establish a guaranteed-catch threshold. English reference zone names currently match English clients; personal observations still retain the names reported by other clients.

## Cooking Planner

Open Cooking in the left navigation or use `/fc cooking`. **Skill: live** reads your base Cooking skill automatically. Enter a target and click **Update plan**. Skill, profession and bag changes update the route. Switch to **Skill: manual** only for a hypothetical starting skill.

- Sourced fishing route through **Cooking 225**, using four recipes.
- Estimates cover the remaining skill bands, stopping at your readable current training cap. The full target stays saved for after training.
- Optional **20% extra fish** reserve.
- Current carried-bag ingredients, remaining fish and recipe knowledge when the API reports it.
- Click a recipe row for fishing locations; unavailable locations remain explicit.
- Track a checklist to show the next fish in the hook tooltip.
- Cook carried fish for the current step first, then reassess. The next species changes when your actual skill reaches the next recipe band.
- Missing recipes and unreadable skill/knowledge produce clear next steps. Unavailable live skill suppresses stale estimates.
- Example: at 125/150 with 10 catfish, the plan estimates 28 total / 18 remaining, but recommends cooking the 10 first and then recalculates.

Targets up to 300 can be entered, but the unverified portion above 225 is clearly marked **not planned**. Quantities are estimates, not guaranteed skill-ups. Bank contents are excluded. Recipe knowledge may remain unknown until Cooking is opened. See [dynamic planning and estimate limitations](COOKING.md).

## Commands and storage

`/fc` · `/fc gear` · `/fc optimizer` · `/fc journal` · `/fc locations` · `/fc cooking` · `/fc stats` · `/fc tracker` · `/fc settings` · `/fc reset` · `/fc diag`

`diag` reports whether recording and auto-start are enabled, whether the session is manually paused, and the last recognized Fishing event/spell. `gear` opens equipment preferences in Settings. `reset` resets only launcher position and scale. Window/tracker placement, tracker visibility, settings, weapons, collections, lifetime statistics, optimizer/planner preferences and the last 30 saved sessions are character-specific. WoW saves on normal logout or reload. Interrupted sessions remain paused until another Fishing cast (with auto-start enabled) or Start/resume; manual pauses remain paused. Offline time is excluded.

See [data provenance](DATA.md), [compatibility](COMPATIBILITY.md), [manual checks](TESTING.md), [later feature roadmap](ROADMAP.md), and [architecture](ARCHITECTURE.md).

## Development

Use Python with `lupa` and, for artwork generation, `Pillow`:

```text
python tests/run.py
python tools/build_media.py
```

The test runner explicitly uses Lua 5.1 and loads every TOC module before the behavioral suite. A local dependency path can be supplied with `--deps PATH`. Mocks cannot prove client taint behavior, protected actions or rendering. Original TGA artwork is reproducible; native game icons are referenced rather than redistributed.


See [0.9.0 UI refinements](UI-POLISH.md) for the Cooking next-step card, text settings, icons and verification limits.
