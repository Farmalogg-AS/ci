# Changelog

Notable changes to the shared actions/scripts here, per version tag. Consuming repos pin to a tag (e.g.
`@v0.1`) rather than `@main`; bump the pinned ref deliberately after checking what changed.

## v0.1

- `compute-qa-tag` — creates/pushes the next `vX.Y.0-qa.N` tag for a release branch.
- `compute-release-tag` — creates/pushes the next production `vX.Y.Z` tag (minor/patch bump).
- `scripts/promote-to-qa.sh` — switches the `QA_RELEASE_BRANCH` org variable and triggers `qa-deploy.yml`
  across all repos that have that branch.
