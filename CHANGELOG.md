# Changelog

Notable changes to the shared actions/scripts here, per version tag. Consuming repos pin to a tag (e.g.
`@v0.1`) rather than `@main`; bump the pinned ref deliberately after checking what changed.

## v0.5

- `compute-qa-tag` / `compute-release-tag` — tags now live under dedicated `qa/` and `release/` namespaces
  (`qa/vX.Y.0.N` and `release/vX.Y.Z`) instead of flat `vX.Y.0-qa.N` / `vX.Y.Z`, so QA and production tags
  are visually and programmatically distinguishable (e.g. `git tag --list "release/*"`).

## v0.4

- `resolve-qa-base-ref` — new action: resolves and checks out whichever branch is actually under QA testing
  (a release branch, or `main` if none is active), regardless of whether `main`, the release branch, or a
  `longtest/*` branch triggered the run.
- `merge-longtest-branches` — new action: ephemerally merges every active `longtest/*` branch (long-lived
  branches for extended external testing that must never reach `main`) on top of the QA base, for the build
  only — never pushed. This is what lets long-lived test work stay visible in QA at all times, even while a
  release is being tested, without ever leaking into a production release.
- Tags now only ever get created against the real QA base ref, never against the ephemeral longtest merge.

## v0.3

- `compute-release-tag` — now auto-detects minor vs. patch by looking for the highest `release/vX.Y` merge
  commit into `main` since the last tag, instead of requiring a manual `bump` input every time. The `bump`
  input is now optional and only needed to force a choice (e.g. if a merge was squashed instead of a real
  merge commit).

## v0.2

- `scripts/promote-to-qa.sh` — reworked to push an empty "chore: promote to QA" commit after updating
  `QA_RELEASE_BRANCH`, instead of manually dispatching `qa-deploy.yml`. This reuses the normal push-based
  trigger (same as any other sync-with-main push) instead of a separate manual-trigger code path.

## v0.1

- `compute-qa-tag` — creates/pushes the next `vX.Y.0-qa.N` tag for a release branch.
- `compute-release-tag` — creates/pushes the next production `vX.Y.Z` tag (minor/patch bump).
- `scripts/promote-to-qa.sh` — switches the `QA_RELEASE_BRANCH` org variable and triggers `qa-deploy.yml`
  across all repos that have that branch.
