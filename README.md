# ci

Shared GitHub Actions used across Farmalogg project repos. Public so any repo in the org can reference it
via `uses:` without extra access configuration. Contains no secrets or business logic — just the generic
git-tag-bumping steps described in [RELEASE-FLOW.md](https://github.com/Farmalogg-AS/root/blob/main/RELEASE-FLOW.md).

## Actions

- `.github/actions/compute-qa-tag` — creates and pushes the next `vX.Y.0-qa.N` tag for a release branch.
- `.github/actions/compute-release-tag` — creates and pushes the next production `vX.Y.Z` tag.
- `.github/actions/resolve-qa-base-ref` — figures out which branch (a release branch, or `main`) is actually
  under QA testing right now, and checks it out. Used so a push to `main`, the active release branch, or any
  `longtest/*` branch all resolve to the same QA deploy correctly.
- `.github/actions/merge-longtest-branches` — ephemerally merges every active `longtest/*` branch on top of
  the current checkout, for long-lived external-test work that must always be visible in QA. Never pushed
  anywhere; exists only for the build that follows.

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
  uses: Farmalogg-AS/ci/.github/actions/compute-release-tag@v0.3
  with:
    bump: ${{ inputs.bump != 'auto' && inputs.bump || '' }} # auto-detects minor/patch when empty
```

```yaml
- name: Resolve which branch is actually under QA testing
  id: qa_base
  uses: Farmalogg-AS/ci/.github/actions/resolve-qa-base-ref@v0.4
  with:
    qa_release_branch: ${{ vars.QA_RELEASE_BRANCH }}

- name: Create QA tag
  uses: Farmalogg-AS/ci/.github/actions/compute-qa-tag@v0.1
  with:
    release_branch: ${{ steps.qa_base.outputs.base_ref }}

- name: Merge active longtest/* branches (ephemeral, not pushed)
  uses: Farmalogg-AS/ci/.github/actions/merge-longtest-branches@v0.4
```

Both require the calling job's checkout step to use `fetch-depth: 0` (full tag history) and
`permissions: contents: write` (to push the tag).

Only the tag-computation logic is shared here — build/test/deploy steps differ per repo's tech stack and
stay in each project's own workflow files.

## Scripts

- `scripts/promote-to-qa.sh <release-branch>` — switches which release is under QA testing: updates the
  `QA_RELEASE_BRANCH` org variable, then pushes an empty `chore: promote to QA` commit to that branch in
  every repo that has it, so the normal push-based trigger (`qa.push.yml`) fires and creates the tag.
  Currently only affects repos with that workflow (so far just `varer`); others are skipped silently until
  their workflows are rewritten too.

### Doing it manually, without the script

1. Update the `QA_RELEASE_BRANCH` org variable (Settings → Organization → Secrets and variables → Actions →
   Variables) to the new release branch, e.g. `release/v2.4`.
2. For each repo that has that branch: push a commit to it. If you're merging `main` in anyway (the normal
   "sync" step), that push is enough — it'll trigger the deploy now that the variable points there. If the
   branch is already fully up to date and there's nothing to merge, push an empty commit instead so there's
   still something to trigger it:
   ```
   git checkout release/v2.4
   git commit --allow-empty -m "chore: promote release/v2.4 to QA"
   git push origin release/v2.4
   ```

