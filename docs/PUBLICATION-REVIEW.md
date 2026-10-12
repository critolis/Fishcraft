# Open-source preparation review

Reviewed on 12 October 2026. Addon version remains **1.0.0**.

## Repository boundary and history

The input was the existing Fishcraft 1.0.0 addon tree, not the surrounding agent
workspace. Its original location was not a Git repository and had no Git history
or remote to migrate. A standalone local Fishcraft repository was initialized
on `main`; only its allowlisted source/documentation files were staged. There
are no commits, historical deleted files or remotes at this preparation stage.
No existing history was rewritten, and the original files were not deleted.

The other addon projects, agent attachments, downloaded dependencies, research
cache, old release ZIPs, game installation and real player profiles are excluded.
The source ZIP also excludes the new repository's `.git` directory.

## Runtime preservation

- All **24 runtime Lua files** and **15 TGA textures** match the original 1.0.0
  input byte for byte in the prepared working tree.
- TOC load order, Interface 16001, SavedVariables name and version are unchanged.
  The only TOC addition is `X-License: GPL-3.0-only`.
- The full original README is retained as `docs/USER-GUIDE.md`, with adjusted
  relative links. Existing detailed documentation and version history remain.
- `.gitattributes` normalizes text line endings on checkout; no Lua logic changes
  were made. `RUNTIME-BASELINE.sha256` records original runtime hashes with LF
  normalization for Lua and raw bytes for textures.

## License and assets

The maintainer explicitly confirmed **GPLv3**. The project uses **GPL-3.0-only**;
no permission for later GPL versions is inferred. `LICENSE` is the full unchanged
official text downloaded from `https://www.gnu.org/licenses/gpl-3.0.txt`:

`3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986`

The copyright notice uses Fishcraft contributors, without a personal name/email.
No vendored runtime libraries were found. All 15 bundled textures reproduce
byte-for-byte from the included generator. Blizzard assets are client references,
not bundled files. No font, sound, copied site image or game executable is shipped.
Reference-data citations are retained and are not represented as a license grant
over third-party websites/databases. See `THIRD_PARTY_NOTICES.md` for boundaries.

## Privacy and credentials

The staged/public source was reviewed for common token and private-key formats,
credential assignments, local user paths, email addresses, personal configuration,
debug logs, real SavedVariables and unexpected files. No matching credentials,
personal paths or email addresses were found. Test profiles are synthetic
fixtures; no character/guild/server history or private messages were copied.

The Git audit inspects all local blobs, including unreachable objects, and
checks Git metadata and remote URL credentials without printing matching values.
The initial audit found zero reachable commits. `.gitignore` excludes `.env`,
credential files, game profiles, logs, caches and generated ZIPs. Runtime assets
and GitHub configuration remain trackable.

These are focused automated checks plus source review, not a guarantee that
arbitrary secret formats or all authorship concerns can be mechanically detected.

## Workflow review

The validation workflow uses upstream Actions pinned to exact revisions, a
read-only contents token, no stored checkout credentials, no repository secrets,
no privileged PR trigger and no CurseForge publishing action. Tag names are
passed through quoted environment variables and must match the TOC version.
Only the two allowlisted archives and checksums are uploaded as CI artifacts.

## Verification results

- Lua 5.1: all 24 modules load; **163 existing behavioral tests passed**.
- Packaging: **7 regression tests passed**, covering clean archives, matching
  source, reproducibility, tag mismatch, missing textures, path traversal and
  rejection of credential/personal-path fixtures.
- All TOC references, custom texture references and entry-document local links
  resolve. The native game resources still require a client check.
- Installable ZIP: **45 files**, exactly one `Fishcraft/` root; no tests, tools,
  internal docs, Git metadata or private configuration. A separate source ZIP
  retains the editable artwork generator and build/test documentation.
- Both ZIPs pass CRC checks and have SHA-256 checksums. Runtime Lua/textures in
  the installable ZIP equal the prepared originals.
- The official GPL download was retrieved successfully. Automated access to the
  existing CurseForge project URL returned HTTP 403; verify that link in a normal
  browser. The source readme does not invent a GitHub repository URL.

Not performed: new in-game testing, hosted GitHub Actions execution, public
GitHub creation/push, GitHub Release creation or CurseForge upload.

## Added or changed preparation files

New: `LICENSE`, `COPYRIGHT`, `THIRD_PARTY_NOTICES.md`, `CONTRIBUTING.md`, root
`CHANGELOG.md`, `.gitignore`, `.gitattributes`, `requirements-dev.txt`, `INSTALL.txt`,
the two issue forms and configuration, `.github/workflows/validate.yml`,
`tools/package.py`, `tools/audit.py`, `tests/test_package.py`, and the new user-guide,
media, release, publishing, baseline and publication-review documents in `docs/`.

Changed: root `README.md`, TOC license metadata and trailing blank-line cleanup
in existing changelog/data/roadmap documents. Runtime Lua and Media are
unchanged. No files outside the standalone Fishcraft project are part of the
source archive or intended public repository.

## Remaining maintainer actions

Approve public publication before creating/pushing the GitHub project. Review
your Git author identity and use a noreply address if desired. Follow
`PUBLISHING.md` for the exact commands and repository settings. Make the matching
source archive permanently available alongside each installable download.
Add redacted current-version screenshots/animation when available and perform
the existing client acceptance checklist before claiming client validation.
