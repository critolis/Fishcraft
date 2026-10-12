# Dynamic Cooking Planner — Fishcraft 0.7.0

Open Cooking in the sidebar. **Skill: live** is the default, including upgrades. The current skill is read from the player's base Cooking rank (skill line 185), without adding buffs. Choose a target and click Update plan. Live mode does not allow editing the current-skill field.

The plan refreshes on opening Cooking and on existing skill, profession and bag events. Successful casts of the four catalog cooking recipes also request a coalesced refresh. Skills gained through other recipes are picked up through skill/profession events. Target input being edited is preserved until Update plan is clicked.

## What the plan takes into account

- Current Cooking rank and readable current training cap.
- Your selected target, capped for the actionable plan by the current training cap and verified route coverage.
- The remaining portion of each guide skill band.
- Current raw fish in carried bags; banks and cooked food are excluded.
- Recipe knowledge when the client reports it.
- Optional 20% extra-fish reserve.

The route still covers 1–225. A higher target stays saved, but its unsupported portion gets no invented fish counts. If the current skill has already reached the target, the planner reports completion. If live skill is unavailable, it hides counts and asks you to open Cooking or choose Manual; it does not reuse a stale saved rank as live data.

When a current training cap is available, the plan stops there. At the cap, its next action is to raise the cap. If the cap cannot be read, no cap is guessed; later steps can still require training.

## Next action

The planner focuses on the first remaining recipe in the route. If it is known and you carry its raw fish, it recommends cooking those fish first, then reassessing. It does not move to future fish just because the current fish are already in your bags. Once the skill passes into the next recipe band, the recommended species changes automatically.

When you have none of the current fish, it shows the estimated remaining fish to gather for that step. A known-missing recipe instead prompts learning it. Unknown recipe knowledge prompts opening Cooking to check it. The route table remains an estimated preparation plan in both cases.

The next action appears in Cooking even when the checklist is not pinned. **Track fishing checklist** also puts it in the hook/location tooltips and compact tracker.

Example: Cooking 125/150, target 225, 10 raw catfish in bags. The remaining 125–150 band estimates 28 raw catfish, with 10 available and 18 left. The next action is to cook the 10 first. After actual skill-ups and ingredient consumption, the plan recalculates. Raising the cap unlocks planning for later bands while retaining the 225 target.

## Estimates, not a probability model

The [Forever Cooking guide](https://www.wowhead.com/forever/guide/professions/cooking/overview-leveling), checked again on 11 October 2026, gives quantities for skill bands and explicitly describes them as approximate. Fishcraft prorates those quantities over the remaining part of a band and rounds up. This is an estimate, not a measured skill-up curve; partial-band accuracy can vary. Reserve is applied per band before merging rows.

No exact recipe difficulty probabilities, legacy bonuses or adaptive learning model are assumed. Cooking a fish without gaining a skill point reduces the bag supply while leaving the skill-based estimate unchanged; the displayed deficit can therefore rise. Conversely, actual skill-ups reduce the remaining route. More accurate predictions would require verified per-skill probabilities or enough reliable cast/skill observations to fit a separately labeled model.

## Manual scenarios

Click **Skill: live** to switch to **Skill: manual**. Enter a hypothetical current skill and target, then Update plan. Live rank changes no longer overwrite that starting skill, and the current training cap does not constrain a hypothetical route. Bag supplies and recipe checks still update. Clicking the mode button again restores live planning immediately.
