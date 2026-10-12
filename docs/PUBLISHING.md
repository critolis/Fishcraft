# GitHub publication

Fishcraft is public at [critolis/Fishcraft](https://github.com/critolis/Fishcraft).
The maintainer approved publication on 12 October 2026. Only the standalone
Fishcraft source tree was published; the surrounding workspace was excluded.

Description: Fishing companion for WoW Forever: gear, lures, discoveries and session statistics.

Topics: `world-of-warcraft`, `wow-addon`, `lua`, `fishing`, `wow-forever`

## Working with the repository

```sh
git clone https://github.com/critolis/Fishcraft.git
cd Fishcraft
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p "test_*.py"
python tools/package.py --check
```

Use the issue templates for bugs and feature requests. Review local Git author
settings before committing; a GitHub noreply address avoids publishing a
personal email. Initial publication used the maintainer's GitHub noreply identity.
Submit focused pull requests according to [CONTRIBUTING.md](../CONTRIBUTING.md).
Never force-push to replace existing public history.

## Releases and CurseForge

Follow [RELEASING.md](RELEASING.md) to build installable and corresponding-source
ZIPs. CI validates and builds archives; it does not publish GitHub Releases or
upload to CurseForge. Add the repository URL to the CurseForge Source field and
provide a persistent corresponding-source link for each addon release. Those
CurseForge metadata changes remain manual and have not been performed here.

The first hosted [validation run](https://github.com/critolis/Fishcraft/actions/runs/38301149669)
succeeded. Actual client verification remains separate; see [TESTING.md](TESTING.md).
