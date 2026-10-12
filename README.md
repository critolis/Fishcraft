# Fishcraft

*Every Cast Has a Story.*

Fishcraft is a fishing companion addon for **World of Warcraft: Forever**.
Use a small radial menu to manage fishing gear and lures, then open the journal
for catches, locations and progress.

## Features

- Animated radial menu with movable launcher, scale controls and reduced motion.
- Fishing pole selection and restoration of saved main-hand/off-hand weapons.
- Lure selection, remaining-duration tracking and optional recommendation mode.
- Discoveries journal with filters, catch history and lifetime catch milestones.
- Session and lifetime statistics, automatic session start and configurable idle stop.
- Reference fishing locations alongside your own recorded catches.
- Fishing skill optimizer with guide-based or personal targets.
- Cooking planner through skill 225, using live skill, carried ingredients and recipe information.
- Shared journal window, optional compact tracker and three body-text sizes.

Equipment changes and lure use require your click. Fishcraft does not automate
casting or bobber interaction. See the [user guide](docs/USER-GUIDE.md) for details
and known data limitations.

## Screenshots and radial-menu preview

No verified screenshot or animation of the current release is bundled in this
repository yet. See the [CurseForge project](https://www.curseforge.com/wow/addons/fishcraft)
for its gallery. The [media checklist](docs/SCREENSHOTS.md) describes the screenshots
and short radial-menu recording planned for this section.

## Installation

Download Fishcraft from [CurseForge](https://www.curseforge.com/wow/addons/fishcraft).
For manual installation:

1. Extract the installable ZIP into the Forever client's `Interface/AddOns` folder.
2. Check that `Interface/AddOns/Fishcraft/Fishcraft.toc` exists without an extra nested folder.
3. Restart the client after first installation and enable Fishcraft in the AddOns list.
4. Type `/fc` to open the radial menu. Right-click the hook for Settings.

Keep your existing character SavedVariables when updating. No additional addon
libraries are required. The separate `-source.zip` archive is for development.

## Commands

`/fishcraft` is an alias for `/fc`.

| Command | Action |
| --- | --- |
| `/fc` | Toggle the radial menu |
| `/fc settings` | Open Settings |
| `/fc gear` | Open equipment and lure preferences |
| `/fc optimizer` | Open Fishing Skill Optimizer settings |
| `/fc journal` | Open Discoveries |
| `/fc locations` | Open fishing locations |
| `/fc cooking` | Open Cooking Planner |
| `/fc stats` | Open Statistics |
| `/fc tracker` | Toggle the compact tracker |
| `/fc reset` | Reset launcher position and scale |
| `/fc diag` | Print addon, client and tracking diagnostics |

## Compatibility

Current addon version: **1.0.0**. Target: **WoW: Forever 1.60.1, Interface 16001**.
This interface target is verified in the TOC and runtime compatibility gate;
there is no recorded in-game validation of the current release in this source
checkout. The Lua 5.1 offline suite covers 163 behaviors. Other WoW versions are
not supported unless explicitly tested. See [compatibility notes](docs/COMPATIBILITY.md)
and the [client test checklist](docs/TESTING.md).

## Development

Use Python 3.11 or newer:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p "test_*.py"
python tools/package.py --check
python tools/package.py
```

Builds go to `dist/`: one installable ZIP and one matching source ZIP. The existing
runtime module layout is retained. [Contributions](CONTRIBUTING.md), focused bug
reports and feature suggestions are welcome; use the repository's issue templates.
See the [changelog](CHANGELOG.md), [release process](docs/RELEASING.md) and
[architecture](docs/ARCHITECTURE.md).

## License

Fishcraft's original code, documentation and artwork are licensed under the
[GNU General Public License v3.0 only](LICENSE). Copyright (C) 2026 Fishcraft
contributors. Referenced Blizzard assets and third-party material are not
relicensed by this project; see [licensing and provenance](THIRD_PARTY_NOTICES.md).
