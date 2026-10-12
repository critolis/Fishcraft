# Validation

## Local validation

The Python runner loads all 24 TOC-listed files in **Lua 5.1**, then initializes the complete addon against a frame/inventory/loot mock. Its 126 checks include schema migration, weapon identities and delayed reads, missing/ambiguous/locked items, empty slots, restoration, full bags, combat guards, close buttons, lure safety, optimizer choices/eligibility/unknown states, session auto-start and manual pause, live statistics, partial/repeated/unrelated loot, collection queries and cooking estimates/coverage. Geometry covers nine anchors, four resolutions and three UI scales.

Run `python tests/run.py`. A local dependency directory can be passed as `--deps PATH`. The mock is intentionally small and cannot prove API availability, Blizzard secure execution, taint behavior, animation quality or client rendering.

## Manual Forever acceptance checklist — NOT YET RUN

Enable Lua errors with `/console scriptErrors 1` for this test session if appropriate. Restore your previous preference afterward. Save `/fc diag` output with any issue.

### Loading and display

- [ ] Confirm interface 16001 and record the exact build. Enable only Fishcraft initially.
- [ ] First login displays the hook without Lua errors; all six labels/icons/textures render correctly.
- [ ] Test center, every screen edge and every corner at 75%, 100% and 150% scale. Buttons, labels and tooltips remain readable and clickable.
- [ ] Drag and lock the launcher; resize the window, change UI scale and `/reload`. Position/preferences persist.
- [ ] Check animation reversal, repeated rapid clicks, reduced motion, collapse setting and minimap visibility.
- [ ] Open each section in the shared window; move/close it, then reopen. Escape closes the main window; text does not overflow.

### Protected actions

- [ ] Location Info replaces Cast Fishing, opens the current zone and clears any fish filter. Cast using the game's own action bar/keybind; Fishcraft still records its events.
- [ ] Enter combat with menu closed, open and animating. It hides without errors; opening/settings changes during combat cannot mutate it.
- [ ] Enter combat while dragging. Verify no stuck movement, then test `/reload` in combat and initialization after combat.
- [ ] Test with another action-bar/UI addon and inspect any blocked-action or taint report.

### Equipment

- [ ] Start with two one-handed weapons, then sword/shield, then a two-handed weapon. Click Fishing pole: it equips directly, saves both slots, and changes to Swap back. One subsequent click restores both original instances without opening a preferences panel.
- [ ] Change preferred pole/lure under Settings → Equipment & lures. Verify /fc gear opens that section.
- [ ] Repeat equip clicks; change bags; reload while the pole is equipped. The original snapshot survives.
- [ ] Verify the Swap back label persists through delayed inventory/equipment events. `/fc diag` reports the pending phase and pole observation. Restore confirms both slots before clearing.
- [ ] Start with either or both weapon slots empty. Restore to the exact empty-slot state.
- [ ] Fill bags and test; no item is lost, deleted or silently replaced.
- [ ] Move an original weapon to the bank before restore. Restoration stops and preserves the snapshot.
- [ ] Carry identical weapons with different enchants; verify GUID identity, or a conservative ambiguity message when GUIDs are unavailable.
- [ ] Hold an item on the cursor, lock an inventory item, and try a trade. Fishcraft must not begin a new gear change.

### Lures and sessions

- [ ] Test each recognized lure present in the actual client; verify skill eligibility and candidate ordering before considering bonus data verified.
- [ ] Apply with no existing enchant. Confirm precisely one lure is consumed and the main-hand pole receives it.
- [ ] With an active enchant, apply is blocked. Check the timer after reload and at expiration.
- [ ] Move/split the lure stack immediately before clicking; confirm the pre-click scan targets the current lure location.
- [ ] Start a session, cast, pause, resume and save. Casting another spell or looting unrelated items does not add casts/catches.
- [ ] Reload mid-session: duration is retained and the session resumes paused; offline time is excluded.
- [ ] Verify actual zone and fishing skill against the character UI, including temporary and gear bonuses.

## Release threshold

### Collection and locations

- [ ] Catch an ordinary fish with manual loot, then autoloot. Counts rise by the quantity recovered, once only.
- [ ] Open a bobber, leave the items, and close it: no increase. Reopen and recover them: one increase.
- [ ] With nearly full bags, recover part of a stack and later the remainder: no loss or duplication in counts.
- [ ] Loot a corpse, container, vendor item or mail after casting: no fishing attribution.
- [ ] Catch an item outside the 23-fish reference set. It appears under All loot without being classified as fish.
- [ ] Start/pause a session while continuing to fish: lifetime collection grows, paused session totals do not.
- [ ] Search/filter/page the collection; inspect first/latest dates and per-zone totals. Reload and confirm persistence.
- [ ] Open Locations from a fish and from the current-zone action. Reference and personal records are distinguished. Missing locations and exact water requirements remain unknown.
- [ ] X and Escape close every window. Header dragging still works.

### Cooking Planner

- [ ] Open Cooking in Live mode: compare current base skill and cap against the profession window. Check known versus missing recipes.
- [ ] In Manual mode, plan 1–225: 52 Smallfish, 55 Mud Snapper, 120 Catfish and 55 Trout before reserve. Inspect recipe ingredient quantities against the client.
- [ ] Plan 150–175: 65 Catfish before reserve. Test a partial band and +20% reserve.
- [ ] Move/split/use fish in bags: Have/Left updates. Bank fish do not count.
- [ ] In Live mode, cook fish: the remaining plan recalculates from actual skill and bag changes without clicking sync.
- [ ] Target 300: coverage above 225 stays visibly unplanned, including when current skill already exceeds 225.
- [ ] Track the checklist and inspect the hook tooltip. Stop tracking and confirm the goal disappears.
- [ ] Check panel text and controls at different scales; no footer, row or tooltip overlap.

## Release status

### Optimizer and live statistics (0.3.0)

- [ ] Check Settings → Optimizer, `/fc optimizer`, and the hook/Lure/Location Info tooltips. No extra radial control or standalone optimizer window appears.
- [ ] Compare base/modifier/temporary/total Fishing with the client before and after pole equip, lure use, skill-ups and food/buff expiration. No pole/lure bonus is added twice.
- [ ] Carry +25, +50, +75 and +100 lures with sufficient base skill. Set a personal target requiring +51: recommend +75, not +100. Set +25: recommend +25.
- [ ] Check minimum base skill; buffed skill cannot qualify an otherwise ineligible lure. Move, split, exhaust or lock recommended stacks immediately before clicking.
- [ ] Manual mode retains the saved lure preference. Recommended mode prepares only the current recommendation. No recommendation means no consumable use in that mode.
- [ ] Sufficient current skill recommends saving lures. Keep-lure mode recommends the weakest eligible lure for perks. Active/unknown enchantment state blocks replacement.
- [ ] If all carried lures are too weak, show the residual gap without applying the strongest one.
- [ ] Unknown zone/subzone requirements are not guessed. Stranglethorn without a subzone or at Jaguero Isle gets no default target. A personal target applies only to its exact zone/subzone.
- [ ] From no active session, cast Fishing normally: the timer starts and the first cast counts. Statistics updates while open without saving first.
- [ ] Pause manually and cast again: it stays paused. Resume, save, and cast again: a new session starts without double-counting totals.
- [ ] Disable auto-start or all recording and confirm those choices are respected. Reload excludes offline time; a manual pause survives reload.

### Discoveries (0.4.0)

- [ ] Journal opens Discoveries with catalog progress. Cycle all five categories, all/caught/unseen, search, current zone and all four sorts. Empty results remain usable; page numbers clamp.
- [ ] Click a fish and return to the list: filters/page remain. Check long names and long reference-zone lists at each supported UI scale.
- [ ] Whimsyfin is New in Forever but has no reference location. A recovered personal catch adds a personal location without changing that reference.
- [ ] Named rare fish appear independently of their item quality. Unknown rare-quality loot appears only under All loot and does not increase fish progress.
- [ ] First catch saves count/date/first zone. Later catches update latest date and zone totals without rewriting the first discovery. Reload retains history.
- [ ] Upgrade older catches: no reset, fabricated first location or epoch date display. A newly classified historical catch retains its original count/date.
- [ ] In Stranglethorn Vale, page through all listed catches; switch zones and confirm catch pages reset. Click a fish to open journal details; no source popup appears. Check X/Escape.
- [ ] Record the client build and confirm names/locations from actual catches. No automatic tournament availability or camp requirement is claimed.

### Radial animation (0.4.1)

- [ ] Open the hook: all six icons rise together, then fan from the top into their radial slots. Labels appear after separation. Closing gathers them above the hook, then lowers/fades them.
- [ ] Toggle repeatedly during lift, fan and closing: no jumps, stuck icons or premature clickable actions. Actions become clickable at full expansion.
- [ ] Test top/bottom/left/right/corner placements at several scales. Icon paths and final positions stay inside the screen; the upward lift shortens near the top edge.
- [ ] Enter combat mid-animation and leave combat: protected controls remain hidden in combat and reset cleanly afterward. Dragging, resizing and changing scale also reset cleanly.
- [ ] Enable Reduced motion: expansion/collapse is immediate, with full labels and functional actions when open.

### Statistics and UI cleanup (0.5.0)

- [ ] Inspect Locations, journal details, Cooking and Optimizer: no source buttons or URL tooltips. Location fish rows open journal details.
- [ ] Compare Lifetime and Current session cards before casting, while fishing, paused, saved and after reload. Current session clears after Save; lifetime totals do not double-count.
- [ ] Catch a stack or multiple loot slots: quantities count fully but success and timing count once. Leave a bobber unlooted: no success. First recovery determines timing.
- [ ] Pause/resume or save/start with pending loot: it may update the journal but does not enter a new recording period's statistics. Test collection/session recording toggles.
- [ ] Upgrade existing history: retain available totals, show new-tracking note, and avoid invented old success/timing/unique values. Totals remain after more than 30 sessions.
- [ ] At supported scales, all eight cards, long values, live header, controls and footer remain legible without overlap. Hover definitions explain item counts versus successful casts.

### Unified window and tracker (0.6.0)

- [ ] Click all sidebar/dial/slash routes. Exactly one main section is visible. No text, buttons or click targets from hidden sections appear through it.
- [ ] Click a Cooking recipe, then a location fish, then Back twice. Original location/page and cooking draft remain. Repeat from a filtered Discovery list.
- [ ] Check Statistics → Session history and switch back to Lifetime/Current session. History and stat cards never overlap.
- [ ] X and Escape close the main window. Drag it, close/reopen and reload: position persists. Check resized screens and 75–150% UI scales.
- [ ] Pin the tracker using the sidebar, settings and `/fc tracker`. Close the main window: tracker still shows advancing time, recovered items, lure status and cooking goal.
- [ ] Drag/reload the tracker; its independent position and pin preference survive. Tracker X unpins it without closing the main window. Open Statistics brings up the shared frame.
- [ ] If tracker and main window overlap, the opaque main window fully covers it. Verify click handling and readable text at the minimum screen size.
- [ ] Switch sections rapidly and close mid-fade. No stuck fade; Reduced motion is immediate. Existing dial/pole/lure and combat behavior remains intact.

### Live Cooking and discovered-first sorting (0.7.0)

- [ ] In Discoveries, caught entries precede unseen entries for all three sort modes. Caught records with missing old dates still stay in the caught group.
- [ ] Upgrade defaults to Live Cooking. Open it before/after opening the profession UI: current rank and cap should match the player, or counts should stay hidden if unavailable.
- [ ] Target above the current cap: plan stops at the cap, keeps the full target, and prompts training when capped. Training unlocks later route bands.
- [ ] Catch, consume, move or sell fish; cook with and without a skill-up. Have/Left and the next-action text update accordingly. At each recipe boundary, verify the focus changes species.
- [ ] Carry enough current-step fish but lack future fish: focus recommends cooking the current fish before gathering later ones. Missing/unknown recipes are not presented as immediately usable.
- [ ] Switch to Manual and enter a hypothetical skill: skill events retain that value. Return to Live: actual skill takes over. Draft target text survives background refreshes until applied.
- [ ] At or above the chosen target, no further gathering is suggested. Above verified Cooking 225, no unsupported fish quantities are invented.
- [ ] Pin the checklist/tracker and check it follows the planner. Verify live/manual labels, cap status and next-action text fit in the shared window.

## Release acceptance

Do not call this build client-verified or stable until the checklist passes on a recorded Forever build. Fix and rerun affected tests when client behavior differs from mocks. Validate data independently before enabling location/cooking claims.

## 0.8.0 pending outcomes and session controls

1. Catch one fish, then cast again with Statistics open. Success should stay at 100% and show one pending cast until resolved. The very first pending cast shows an em dash, not 0%.
2. Interrupt a cast or let it expire. After the channel ends and the three-second grace passes, it contributes an unsuccessful resolved outcome exactly once. Failed attempts before a bobber is cast do not add casts.
3. With auto-loot off, click the bobber and leave its verified loot open for more than three seconds. It stays pending. Loot it for one success, or close it uncollected and allow resolution. Try partial stacks, duplicate events, and delayed loot.
4. Use the green play dial action to Start and the red square to Stop. The icon and label follow recording, pause, manual stop and idle stop; there is no extra status dot on this button. Stop archives once; the next new cast automatically starts a session when enabled. Reload preserves that preference. A duplicate event from the stopped cast must not restart it. Journal > Statistics and `/fc stats` still work.
5. Choose two-minute idle stop in General Settings. With all panels hidden, stop fishing and wait. The session is saved; the next cast auto-starts a new session if enabled. Verify Off, five-minute default, ten-minute option and auto-start disabled. Manual Pause should never auto-save.
6. Stop, pause or reload while a cast is pending. Its Casts count stays, but no fabricated failed outcome is added. Confirm existing lifetime totals and weapon/preferences survive an upgrade.
7. Confirm idle archival during combat does not cause protected-action errors and the session label refreshes when combat ends. Check settings text and tooltip placement in the actual UI.

## 0.8.3 auto-start regression

1. Upgrade without deleting SavedVariables, including characters where Stop was previously clicked. Enable session recording and automatic start in General Settings. If explicitly paused, click Start/resume once, then Stop to end that paused session.
2. Leave the dial open and cast Fishing from your usual action bar. It should immediately show a red stop square and Stop session; the timer starts and Casts increments once. Catch the fish and confirm one resolved success.
3. Click Stop. The green play icon returns. A new cast should start a new session without any extra click. Ensure the previous cast's late events do not start a session by themselves.
4. Turn auto-start off and repeat: casts must not start a session. Turn it back on and cast again. Explicit Statistics Pause must still hold until resumed.
5. If the issue persists, run `/fc diag` immediately after a cast and capture its session/recording/auto-start/last-event/spell lines along with the client build.

## 0.9.0 UI polish

1. Check Compact, Comfortable and Large text sizes in General Settings. Verify the preference survives reload without changing UI scale or radial spacing. Check long discovery names, equipment notes, all four Cooking rows and the tracker.
2. In Locations, open the selector, type a partial name, select with a click and then with Enter. Check no results, paging, Escape, main-window close and navigation to another section. Typing must stop capturing keys after dismissal.
3. Enter Locations from a fish/recipe and check that the picker is restricted to its known locations. All locations should restore the full list without unnecessarily jumping away from the current zone. Back should retain the prior navigation context.
4. Confirm location counts reflect catches in that zone and reference-only entries remain explicit. Single-page lists should not show paging buttons; longer lists must still expose every fish.
5. Read the Cooking next-step card with missing/unknown/known recipes, fish in bags, a training cap and an unavailable skill. Recommendations and quantities should match previous behavior. Check column alignment at each text size.
6. Confirm Statistics icons load, the selected sidebar section is obvious, and radial labels/hover remain readable over bright water. Inspect tooltips using the full screen: their anchor logic has not changed.

## 1.0.0 Discovery milestones

1. Open Discoveries after reload: Most catches should be selected, highest lifetime counts first. Ties use names; unseen fish remain last.
2. Uncaught icons and names should be gray, but rows must still open details. Search/filter/page between caught and unseen entries and verify their styling resets correctly.
3. Check counts at 9/10, 99/100, 499/500 and 999/1,000: badges switch to green, blue, purple and amber-gold exactly at the thresholds. Hover for achieved/next milestones. Detail pages must show the same count and color.
4. Check all three text sizes, long names and large catch counts. Catch another fish and confirm its count, badge and sort position refresh. Reload and verify counts are preserved.
