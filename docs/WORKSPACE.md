# Unified window — Fishcraft 0.6.0

Fishcraft now has one main window. The left navigation selects **Discoveries, Locations, Cooking, Statistics, or Settings**. Each section keeps its controls and state while another section is displayed. A highlighted navigation item identifies the active section.

The dial's Journal, Location Info and Settings actions open the appropriate section in this same window. Pole, Lure and Start/Stop session are direct actions. Statistics is available in the main window's navigation and via `/fc stats`. No new radial buttons were added. Slash commands continue to work; repeating a section toggle closes the main window when that section is already active.

## Navigation and closing

- Clicking a fish opens its full detail page inside Discoveries.
- Known locations opens Locations filtered to that fish.
- Clicking a Cooking recipe opens its fish's locations.
- **Back** returns through these linked views, restoring the previous fish/location selection and page. Search, filters and draft cooking input remain in their existing controls.
- Selecting a left-navigation section starts a new navigation path. The Back stack is bounded to 20 entries and resets on reload.
- Session history is now **Statistics → Session history**, alongside Lifetime and Current session.
- One X or Escape closes the main window. Closing it does not stop the fishing session or hide a pinned tracker.

The shared window is opaque, movable by its header, and remembers its position across reloads. Window and tracker positions are independent from the radial launcher. Scaling fits the main window within the current screen. Short section fades respect Reduced motion; the dial retains its lift-and-fan animation. This release uses full detail pages at all sizes; it does not introduce a wide-screen split-view layout.

## Optional tracker

Click **Pin tracker** at the lower left of the main window, enable **Show compact fishing tracker** in Settings → General, or use `/fc tracker`. It starts unpinned on upgrade.

The tracker shows current session time/items, lure status or remaining duration, and the active Cooking checklist target. It refreshes once per second while shown and remains visible when the main window closes. Hover for full lure/goal text. Drag its header to move it; position and pinned state persist. **Open Statistics** opens the main window's Statistics section. X unpins only the tracker.

The tracker is informational: it does not cast, use lures, change equipment or start sessions automatically. It sits below the main window in drawing order and is not part of the Escape close list.

## Implementation and verification

Only `FishcraftWindow` is registered in `UISpecialFrames`. The former independent panels are ordinary child frames under that window; navigation explicitly shows exactly one. The tracker is a separate smaller frame on a lower drawing layer. This removes the independent main-window stacking that allowed controls to interleave.

Offline tests cover single-section visibility, close behavior, recipe/fish/location Back navigation, filter preservation, session-history relocation, command/radial routes, tracker updates/pinning, saved placement and screen bounds, and reduced-motion transitions. Native rendering, drag behavior and Escape handling still require a Forever client check.
