# Initial GitHub publication

Prepared repository name: **Fishcraft**

Description: `Fishing companion for WoW Forever: gear, lures, discoveries and session statistics.`

Topics: `world-of-warcraft`, `wow-addon`, `lua`, `fishing`, `wow-forever`

The intended account is `critolis`, as returned by the connected GitHub account.
Publication requires the maintainer's explicit approval. No remote repository
has been created or changed by this preparation. The existing connector can
inspect repositories, but does not expose repository creation; GitHub CLI is
not installed in the preparation environment.

## After approval

From this **Fishcraft** repository root, review `git status --short`, run the
checks in [RELEASING.md](RELEASING.md), and review the source archive. Never run
the following from the parent multi-project workspace.

Using GitHub CLI, authenticate interactively with `gh auth login`; do not paste
tokens into files or commands. First check whether the intended repository
already exists:

```sh
gh repo view critolis/Fishcraft
```

If it exists, stop and inspect it. Do not overwrite its source or visibility.
Only proceed with creation after confirming that it is absent and that the
lookup did not merely fail because of authentication or network trouble.
Review your local Git author name/email before committing; a GitHub noreply
address avoids publishing a personal email.

```sh
git add .
git diff --cached --stat
git commit -m "Prepare Fishcraft 1.0.0 for open-source publication"
gh repo create critolis/Fishcraft --public --source=. --remote=origin --push --description "Fishing companion for WoW Forever: gear, lures, discoveries and session statistics."
gh repo edit critolis/Fishcraft --enable-issues --add-topic world-of-warcraft --add-topic wow-addon --add-topic lua --add-topic fishing --add-topic wow-forever
```

Alternatively, create an empty public Fishcraft repository on GitHub, enable
Issues, and add the description/topics in Settings. Do not initialize it with a
second README or license. After approval and a local initial commit, connect
and push using the URL shown by GitHub. Use an ordinary push; never force-push.

Once published, add the verified repository URL to the CurseForge Source field
and add a persistent corresponding-source download for each addon release.
Use the repository issue forms for reports. CI produces artifacts only; public
release and CurseForge uploads remain manual actions.
