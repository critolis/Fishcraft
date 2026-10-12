# Contributing to Fishcraft

Bug reports, small fixes and focused feature proposals are welcome.

## Reports and ideas

Use the repository's Bug report or Feature request template. For bugs, include
the addon version, `/fc diag` output, Forever client build, steps to reproduce,
expected and actual behavior, and the first Lua error. Redact character names,
account paths and other personal details from logs and screenshots. Do not attach
your entire WTF folder or real SavedVariables; use a minimal synthetic example.

Explain the problem before proposing a feature. Discuss large changes in an
issue before implementing them.

## Pull requests

1. Fork the repository and create a focused branch.
2. Follow the existing module structure and Lua 5.1-compatible style. Avoid
   unrelated formatting, refactoring or new runtime dependencies.
3. Run the checks below. Add a regression test for changed behavior when the
   harness can represent it; explain checks that still require the client.
4. Describe the change, user-visible impact and validation in your pull request.

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p "test_*.py"
python tools/package.py --check
python tools/package.py
```

Target WoW: Forever 1.60.1 / Interface 16001. Preserve combat restrictions,
explicit-click equipment/lure actions and SavedVariables compatibility. Do not
claim support for another client without testing and documenting it. Native
rendering, secure execution and live event order need actual client validation;
see [manual checks](docs/TESTING.md).

## Licensing

Contributions must be compatible with the project's [GPLv3-only license](LICENSE).
By submitting a contribution, you agree to provide your original contribution
under that license. Keep third-party notices, identify external sources, and do
not add game assets, scraped databases or other material without redistribution
rights. New artwork should include its editable source or generator.
