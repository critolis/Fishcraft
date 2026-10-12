# Validation report — Fishcraft 1.0.0

Checked locally on 11 October 2026.

- All **24 TOC Lua modules** compile and load in Lua 5.1.
- **163 behavioral tests pass** in the frame/inventory/loot harness.
- Coverage includes schema migration; combat guards; weapon identities, empty slots and full bags; same-click restoration of both weapons; missing-offhand preflight; every panel's close handler and drag-layer separation; lure handling; session timing; partial/duplicate/nonfishing loot; unknown sources; reference/personal queries; cooking bands, reserve, bag counts, recipe knowledge and incomplete coverage above 225.
- Existing radial geometry checks cover four resolutions, three scales and nine screen anchors.
- Package checks cover TOC file presence, UTF-8 without Lua BOMs, RGBA TGA dimensions, archive entry count and ZIP CRC.

New checks cover delayed equipment reads preserving weapon snapshots, weakest-sufficient lure ranking, base-skill eligibility, preference tie-breaking, insufficient and unknown states, no double-counted pole bonus, exact-location personal targets, manual/recommended modes, replacement of the Cast shortcut, automatic session start, manual pause, live statistics, save totals and offline-time exclusion.

Discoveries checks cover category/state/zone intersections, unknown-loot exclusion, first-discovery persistence, duplicate recovery, old-record classification, date sorting, empty-page clamping, in-journal details and metadata provenance, complete location pagination and reverse-zone consistency. All previously covered behavior still passes.

The user's 0.2.0 screenshots demonstrate recovered catches and expose the missing live timer and lost weapon snapshot. **Version 1.0.0 has not been executed in that client.** The harness cannot establish Blizzard hit testing, actual rendering, taint rules, one-click equipment permissions or loot-event order. These remain in the manual acceptance checklist.

Reproduce with `python tests/run.py` (Lupa required), optionally `--deps PATH`.


Animation checks cover shared upward staging, curved fan endpoints, complete path bounds at 81 resolution/scale/anchor combinations, rapid reversal without position jumps, disabled action hit areas during motion, combat interruption, and reduced-motion completion. The final visual feel has not been observed inside Forever.

Statistics checks cover one-time migration, stack/multi-slot outcome deduplication, missed/duplicate casts, recording toggles, pause/session boundaries, lifetime history trimming, active-session save/reload totals, zero denominators, scope controls and removal of URL popups. The new cards still need in-client layout and live-loot verification.

Unified-window checks cover a single shared parent/visible section, one Escape registration, close control, recipe/location/fish Back paths, retained discovery filters and draft inputs, Statistics session history, command/dial routing, tracker independence and updates, placement across three screen sizes and three anchors, and stopped/reduced-motion section fades. In-client layering, native drag behavior, text fitting and Escape handling remain manual acceptance items.

New checks cover caught-first grouping under every sort, old catches without dates, live base rank/cap, partial-band deficits, bag consumption with/without skill-ups, training gates, current-step focus, recipe knowledge, unavailable/invalid skill, reached/unsupported targets, manual scenarios, preserved target drafts and event-driven planner/tracker refresh. Live client skill/recipe availability still needs verification.

0.8.1 adds 17 outcome/session tests: pending success-rate stability, channel-end grace, open loot, empty recapture cleanup, delayed correction, recast boundaries, irrelevant events, fallback expiry, boundary exclusion, denominator migration, manual-stop persistence, dial state, idle deadline clamping, delayed ticker handling, disabled/paused settings, auto-start preference, option validation and combat-safe archival. Native Forever testing remains outstanding.

0.8.1 changes only the session icon presentation: green play / red stop, without a separate dot. Both textures are original transparent 128 × 128 RGBA TGAs. Check their appearance at your preferred UI scale in Forever.

0.8.2: all 143 tests pass with 10% larger radial icon textures and 10% smaller layout radii/lift. Existing bounds checks confirm separated action circles and labels at the tested center, edge and corner positions. In-client appearance still needs verification.

0.8.3 adds nine regressions: channel-only timer/icon start, both event orders preserving token/slots/time, rank differences, old Stop migration, late duplicate exclusion across Stop and manual Start, disabled preferences/explicit Pause, unrelated channels and combat-safe texture refresh. Texture assignments are now observed in the mock, not only labels. All 152 tests pass. No native client trace was available to establish which of the blockers affected this character.

1.0.0 adds eight UI regressions covering searchable zones, full pagination, literal queries/empty results, fish-filter scope, dismissal/navigation, per-zone catch badges, independent font settings with combat guards, and section headings. Existing cooking, session, equipment and geometry tests continue to pass. Seven new semantic stat symbols and a dropdown chevron were visually inspected at native and enlarged sizes. Approximate layouts derived from mocked frame state were reviewed at Large text size, including all four Cooking steps; these are not game screenshots and use a substitute font. Tooltip anchoring was deliberately untouched: the user clarified that the apparent clipping in the recording was caused by the capture crop.

1.0.0 adds regressions for count-first sorting with stable ties, exact milestone boundaries, and reused rows switching between gray unseen and colored caught states. Fish detail badges share the same thresholds. Larger-text layout review uses a substitute font and mocked frames; native icon desaturation and client rendering still require an in-game check.
