# Statistics — Fishcraft 0.8.3

The Statistics window has **Lifetime** and **Current session** views. Eight cards use the existing gold/blue theme. Hover a card for its definition. Session controls remain below the cards; updates happen once per second while visible.

| Metric | Definition |
| --- | --- |
| Time fishing | Elapsed recorded session time, including time between casts. Paused and offline time is excluded. |
| Casts | Deduplicated player Fishing casts while recording. Casts with no recovered loot still count. |
| Items caught | Recovered item quantities attributed to a cast in the same uninterrupted recording period. A stack can contain several items. Includes unclassified fishing loot. |
| Success rate | Casts yielding recovered bobber loot divided by resolved casts measured with collection recording enabled. One success per cast, regardless of slots or quantities. |
| Items / hour | Items caught divided by recorded hours. It is not an estimate of uninterrupted casting efficiency. |
| Avg. cast to loot | Seconds from cast to first item recovery. Includes reaction and loot handling time; excludes casts spanning a pause or session change. |
| Sessions | Archived session count plus one if a current session exists. |
| Unique catches | Distinct item IDs recovered in recorded sessions since 0.5.0 tracking began. Includes non-fish loot. It is separate from the journal's catalog fish discoveries. |

An em dash means no resolved casts or timing samples are available. Ongoing casts remain pending and are excluded from the success-rate denominator. Cast count still increments immediately. The live status shows the number pending.

First verified recovery resolves a success immediately. A matching Fishing channel-stop/interruption/failure event, recast, or verified loot-window closure schedules resolution after three seconds to allow loot events to arrive. Verified open bobber loot holds resolution until recovery or closure. Without an end event, the existing 40-second attribution window is the fallback. A resolved cast with no recorded recovery is unsuccessful for this metric; this includes uncollected or unverifiable loot and does not prove the game reported a failed catch. Late verified recovery in the same recording period corrects that outcome without adding another denominator.

Pause, Stop, save, logout and zone changes discard still-pending outcomes rather than inventing failures. Cast totals remain intact. Closed outcomes from older releases retain their original denominator through one-time initialization of `resolvedCasts`; historical temporary dips cannot be reconstructed. New fields are additive to schema 2.

## Lifetime storage and upgrade

On first upgrade, available saved session time, casts, catches and session counts seed a persistent aggregate. An active session is added live, then archived exactly once when saved. The aggregate survives trimming the visible history to 30 sessions. Saving or starting a session does not reset it.

Sessions already discarded by older versions cannot be recovered. Previously unrecorded time, per-cast outcomes, timing and session-specific unique items cannot be reconstructed from collection totals. Success/timing/unique metrics therefore begin with new tracking; the UI states this. The journal retains its independent, older catch history.

Each newly measured cast carries its current session and uninterrupted recording period into loot attribution. Partial recovery, repeated events, multiple loot slots and reopening a bobber share the same outcome marker. Only first recovery adds a success and duration sample; every genuine recovered quantity adds items. Pausing, saving or changing the session prevents older pending loot from entering the new session's metrics. Collection counts can still grow independently.

Lifetime data, current-session details and collection records are per character. Normal logout/reload saves them. Vendor/auction valuation is not part of this release.

## Sources in the UI

Raw URLs, source buttons and the Data source popup have been removed from all game panels and tooltips. Clicking a fish in Locations opens its journal detail instead. Reference provenance remains in `Data/` and the documentation; removing the URL UI does not change confidence labels or verified data.

## Session controls and API reference

The radial Start/Stop action saves and ends the session on Stop. When auto-start is enabled, the next genuine Fishing cast starts another. Versions 0.8.0–0.8.2 stored a stop latch that silently blocked automatic start; version 0.8.3 removes it without changing explicit preferences. A manually paused session still requires Start/resume. Idle stop defaults to five minutes and can be disabled or set to two/ten minutes in General Settings. It uses the last cast/channel-end/recovered-loot/verified-loot-close time. Idle allowance is part of recorded time; delayed scheduler ticks add no extra AFK time. Manual Pause never auto-archives. An idle-stopped session auto-starts again only when the auto-start preference is enabled.

Matching event payloads were checked against [Blizzard-generated Classic Era Unit API documentation](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua), mirrored by Gethe, on 11 October 2026. Event registration is guarded, payloads must be readable, and the existing attribution timeout remains a fallback. This does not establish native Forever event ordering; test that in the client.

## 0.8.3 automatic-start correction

Observe both `UNIT_SPELLCAST_CHANNEL_START` and `UNIT_SPELLCAST_SUCCEEDED`, using the same readable player/cast-GUID/Fishing-ID validation. The existing Fishing rank-ID catalog is shared by spell discovery, session start, collection arming and channel outcome handling. Duplicate events preserve the original token, timestamp and captured loot slots. The most recent observed GUID survives session Stop/Start, so a delayed second event from an archived cast cannot start or contaminate the next session.

The channel-start pattern is supported by the [Forever Angler implementation](https://github.com/tobarisu1/wow_forever_addons/blob/main/Angler/Angler.lua), rechecked 11 October 2026. It supplements the existing success event; no actual client trace was available for this user's report. Offline regressions verify both event orders, channel-only start, rank variants, immediate icon state, old-stop migration, explicit preference/pause behavior and combat-safe refresh.
