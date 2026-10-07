# ci - AI Coding Instructions

See `README.md` for what the shared actions do, and `CONTRIBUTING.md` for how to change and release them. This file only
has extra instructions specific to AI agents.

This repo is one of several in the Farmalogg workspace. If this session was started from inside this repo, the
workspace's `../AGENTS.md` and `../CONTRIBUTING.md` (shared instructions, commit conventions, PR process and
coding standards) aren't loaded automatically, so read them before you start.

## Critical rules

- This repo is public: never add secrets or infrastructure names (see `CONTRIBUTING.md`).
- Never create or push tags; other repos run these actions by version tag, so releasing is left to the human.
