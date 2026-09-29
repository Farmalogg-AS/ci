# ci

Shared GitHub Actions used across Farmalogg project repos. Public so any repo in the org can reference it
via `uses:` without extra access configuration. Contains no secrets or business logic — just the generic
git-tag-bumping steps described in [RELEASE-FLOW.md](https://github.com/Farmalogg-AS/root/blob/main/RELEASE-FLOW.md).

## Actions

- `.github/actions/compute-qa-tag` — creates and pushes the next `vX.Y.0-qa.N` tag for a release branch.
- `.github/actions/compute-release-tag` — creates and pushes the next production `vX.Y.Z` tag.

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version tag.

## Usage

```yaml
- name: Create QA tag
  uses: Farmalogg-AS/ci/.github/actions/compute-qa-tag@v0.1
  with:
    release_branch: ${{ vars.QA_RELEASE_BRANCH }}
```

```yaml
- name: Create release tag
  uses: Farmalogg-AS/ci/.github/actions/compute-release-tag@v0.1
  with:
    bump: ${{ inputs.bump }}
```

Both require the calling job's checkout step to use `fetch-depth: 0` (full tag history) and
`permissions: contents: write` (to push the tag).

Only the tag-computation logic is shared here — build/test/deploy steps differ per repo's tech stack and
stay in each project's own workflow files.

## Scripts

- `scripts/promote-to-qa.sh <release-branch>` — switches which release is under QA testing: updates the
  `QA_RELEASE_BRANCH` org variable and triggers a QA deploy in every repo that has that branch. Needed because
  updating the variable alone doesn't trigger anything — see [RELEASE-FLOW.md](https://github.com/Farmalogg-AS/root/blob/main/RELEASE-FLOW.md).
  Currently only repos with a `qa-deploy.yml` workflow (so far just `varer`) will actually deploy; others are
  skipped silently until their workflows are rewritten too.
