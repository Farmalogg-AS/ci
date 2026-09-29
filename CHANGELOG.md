# Changelog

Notable changes to the shared actions/scripts here, per version tag. Consuming repos pin to a tag (e.g.
`@v0.1`) rather than `@main`; bump the pinned ref deliberately after checking what changed.

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
