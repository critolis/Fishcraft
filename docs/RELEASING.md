# Release process

The repository root is the addon root. Keep `Fishcraft.toc` and the existing
runtime module directories in place. Installable archives wrap these files in
one `Fishcraft/` directory.

## Validate and build

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p "test_*.py"
python tools/package.py --check
python tools/package.py
```

`dist/Fishcraft-<version>.zip` includes TOC-listed Lua, original TGA textures,
the full license, copyright/provenance notices and short installation/source
instructions. No Git metadata, tests, development tools, internal docs, local
profiles or credentials are included.

`dist/Fishcraft-<version>-source.zip` contains the corresponding editable source,
including tests, texture generator, build scripts and project documentation.
Keep it available beside the runtime download. Until a public repository or
permanent source download exists, do not distribute the runtime archive alone.
The source archive is not the installable addon file for CurseForge.

`dist/SHA256SUMS.txt` contains checksums of both archives. Members are ordered and
ZIP timestamps fixed, so the same inputs produce identical archives. The builder
uses a file allowlist and validates the TOC, version agreement, local media,
entry-document links, license presence and common sensitive-data patterns.

## Version tags and CI

For a future release, update the version in both `Fishcraft.toc` and
`Core/Bootstrap.lua`, move relevant Unreleased notes into a dated changelog entry,
and update the README/INSTALL version text. Validate before tagging.

```sh
git tag -a v1.0.0 -m "Fishcraft 1.0.0"
git push origin v1.0.0
```

Use that example only after the repository has been approved for publication
and only when the tag does not already exist. Never replace an existing tag.
CI rejects a tag that differs from the TOC version. Pull requests, main pushes
and manual runs also validate and build. The workflow uploads only the two
archives and checksums as GitHub Actions artifacts; it does not create public
GitHub releases or upload to CurseForge. Artifacts are temporary, so use a
permanent source download when publishing a release.

The workflow has read-only contents permission, no project secrets, no
`pull_request_target` trigger, no shell interpolation of user-controlled issue
text, and no persisted checkout credentials. Reference names are passed through
environment variables and quoted. Runtime archives and source archives are
explicitly selected; the entire working directory is never uploaded.
Actions are pinned to exact upstream revisions. Review and update these pins
deliberately; the associated major versions are documented in workflow comments.

Before publication, run `python tools/audit.py` from a Git checkout. It reviews
the source allowlist, index, untracked paths and all local Git blobs (including
unreachable objects), with metadata/email checks. This heuristic scan cannot
replace review of the exact files being published.

## Final manual check

Run the [client checklist](TESTING.md) and record addon/client versions. Offline
tests cannot establish native UI, combat taint or live loot-event behavior.
Upload the installable ZIP to the existing CurseForge project manually, with
the correct Forever version and a corresponding-source download link. Nothing
in this repository requires a CurseForge API token.
