# Fishcraft roadmap

## Delivered

**0.1.0:** modular addon, compatibility checks, original circular artwork, six-action adaptive radial menu, secure casting/lure actions, equipment snapshots, preferences and session tracking.

**0.2.0:** repaired X-button hit areas; direct pole/weapon toggle; preferences inside Settings; recovered-loot collection journal; sourced zone listings and personal observations; Cooking Planner through 225; bag checklist and tooltip goal; schema migration and behavioral tests.

## Next acceptance gate

**0.3.0 delivered:** initial Fishing Skill Optimizer, Location Info radial replacement, delayed-update weapon snapshot fix, and automatically started live session statistics.

**0.4.0 delivered:** Discoveries journal with 23 sourced records, category/state/date filters, first-catch history and location pagination.

**0.4.1 delivered:** staged lift-and-fan dial animation with reversible motion and bounded paths.

**0.5.0 delivered:** source URL UI removed; eight Statistics cards with current/lifetime scopes, persistent totals and measured outcomes.

**0.6.0 delivered:** unified main window, preserved navigation context, Statistics history and optional compact tracker.

**0.7.0 delivered:** discovered-first ordering and live Cooking skill/cap/bag planning with current-step advice.

**0.8.0 delivered:** pending/resolved cast rates, Start/Stop session dial action, manual stop persistence, and configurable idle archival.

Validate 0.8.0 in the actual Forever client: pending outcomes, channel-to-loot timing, manual/idle session stops, cooking skill/recipe availability and live recalculation, single-window layering, navigation, tracker and placement, stat layout, live outcomes and upgrade totals, animation feel and edge behavior, discovery filtering/history persistence, dense text and location pagination, plus delayed inventory updates, optimizer totals/eligibility/modes, first-cast session start, manual Pause, source confidence and UI layout. The user's 0.2.0 screenshots show recovered fish but exposed lost snapshots and the missing automatic/live session workflow. Record the client build. The offline harness cannot certify it.

## Later features requested by the user

These are backlog ideas, not implemented features or verified game mechanics. Their screenshot examples supply design direction, not authoritative numerical data.

| Priority | Feature | Intended behavior / prerequisites |
| --- | --- | --- |
| Delivered; expand later | Fishing Skill Optimizer | Initial six-lure implementation in 0.3.0. Future work: broader verified targets/consumables, resolved pole data and individual effect attribution. |
| High | Camp Assistant | Show available Fish Bowl, Fishing Rack and Fishing Hut options, required materials and current bonuses after verifying Forever mechanics. Share a material checklist with the Cooking Planner. |
| Delivered; expand later | Forever Fish Collection / Discoveries | Initial 23-record journal in 0.4.0. Add further independently sourced Forever fish and locations as evidence becomes available. |
| Medium | Cooking Buff Advisor | Recommend useful food, including verified fishing bonuses, based on current context and recipe availability. |
| Medium | Tournament Tracker | Record tournament catches, progress and remaining time using verified event rules and schedules. |
| Medium | Legacy Awareness | Include Luremaster and relevant legacy perks in statistics and recommendations after checking their actual effects. |
| Medium | Fishing Progression Guide | Contextual reminders for training, an Expert book and Nat Pagle progression where verified for the active client version. |
| Cross-feature | Adaptive Fishing Advisor | Show at most one or two useful contextual tips inside existing panels/tooltips. Prioritize advice by present need; avoid a separate large window. |
| Cross-feature | Smart Fishing Location | A compact current-location widget with progressive disclosure, details on hover/click, effective skill and up to three relevant catches. Open the journal filtered to that location. |

### Smart Fishing Location design

Keep the six primary radial actions. Show only compact location/status information around existing controls; no long lists or extra radial button.

- Green: verified sufficient skill for the specific water.
- Amber: low skill or uncertain data, with an explanation.
- Gray: requirements unknown.
- Hover: required skill, effective skill including verified pole/lure effects, and three useful catches.
- Click: the detailed location-filtered Fishing Journal.

Zone-level guide advice must not generate a green guarantee for every pool, coast or inland water. The screenshot's 225 / 150 values are illustrative. The current release provides a basic location tooltip and detail panel; the adaptive widget and readiness evaluation remain later work.

## Additional planned work

Broader fish and recipe coverage; verified water IDs and thresholds; locale-aware zone IDs; recipe alternatives and efficient route selection; additional discovery categories; milestones and optional notifications; catch comparisons; exact preferred item instances; lure warnings; UI refinement from real screenshots; translations; performance profiling.

## Data and interaction principles

Forever is changing. Keep data versioned and dated, record sources, and recheck important values against the client. Unknown values stay unknown. Integrate enhancements into existing tooltips and detail screens. Casting, lure use and equipment changes always require user action.
