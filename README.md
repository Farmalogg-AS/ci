# ci

Shared GitHub Actions used across Farmalogg project repos. Public so any repo in the org can reference it
via `uses:` without extra access configuration. Contains no secrets, infrastructure names or business logic:
the generic git steps (tagging, resolving the QA base branch, merging) of the flow described in
[RELEASE-FLOW.md](https://github.com/Farmalogg-AS/root/blob/main/RELEASE-FLOW.md), and build steps several
repos share. Anything repo- or environment-specific, including credentials, is passed in as inputs by the
calling workflow.

## Actions

- `.github/actions/compute-qa-tag` — creates and pushes the next `qa/vX.Y.0.N` tag for a release branch, or a
  unique `qa/branch/<branch>/<run>` tag for any other branch deployed to QA. The tag annotation records the
  base commit, the merged `longtest/*` branches, the image, the trigger and a link to the run, and for release
  branches, the changes since the previous QA tag of that release (or the latest prod tag).
- `.github/actions/compute-release-tag` — creates and pushes the next production `prod/vX.Y.Z` tag. The tag
  annotation records the previous tag, why it bumped minor or patch, the image, the trigger and a link to the
  run, and the changes since the previous tag.
- `.github/actions/resolve-qa-base-ref` — figures out which branch (a release branch, or `main`) is actually
  under QA testing right now, checks it out, and outputs its name and commit. Used so a push to `main`, the active release branch, or any
  `longtest/*` branch all resolve to the same QA deploy correctly.
- `.github/actions/merge-longtest-branches` — ephemerally merges every active `longtest/*` branch on top of
  the current checkout, for long-lived external-test work that must always be visible in QA. Never pushed
  anywhere; exists only for the build that follows. Outputs which branches it merged, at which commit.
- `.github/actions/sync-main-into-releases` — merges `main` into every `release/v*` branch that doesn't
  already contain it, and pushes the result so each branch's own CI retriggers normally. Skips release
  branches already merged into `main` (shipped), so shipping a release doesn't push and redeploy it again.
- `.github/actions/setup-java-maven` — installs a JDK with Maven caching, and optionally configures an
  authenticated Maven repository (e.g. GitHub Packages) to resolve dependencies from.
- `.github/actions/deploy-container-app` — logs in to Azure and the container registry, builds and pushes a
  Docker image tagged with the commit hash, and deploys it to an Azure Container App.

The tag actions share scripts in `.github/actions/lib/` for their annotations. `describe-changes.sh` lists the
changes, grouping commits by their `<type>: <description>` subject: `feat`, `fix`, `perf` and `vis` commits are
listed, other types only counted.

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version tag, and [CONTRIBUTING.md](CONTRIBUTING.md)
for how to make and release changes.

## Usage

```yaml
- name: Create QA tag
  uses: Farmalogg-AS/ci/.github/actions/compute-qa-tag@v0.9
  with:
      release_branch: ${{ vars.QA_RELEASE_BRANCH }}
```

```yaml
- name: Create release tag
  uses: Farmalogg-AS/ci/.github/actions/compute-release-tag@v0.9
  with:
      bump: ${{ inputs.bump != 'auto' && inputs.bump || '' }} # auto-detects minor/patch when empty
      image: ${{ steps.deploy.outputs.image }} # optional, recorded in the tag annotation
```

```yaml
- name: Resolve which branch is actually under QA testing
  id: qa_base
  uses: Farmalogg-AS/ci/.github/actions/resolve-qa-base-ref@v0.9
  with:
      qa_release_branch: ${{ vars.QA_RELEASE_BRANCH }}

- name: Merge active longtest/* branches (ephemeral, not pushed)
  id: longtest
  uses: Farmalogg-AS/ci/.github/actions/merge-longtest-branches@v0.9

# ... build and deploy, e.g. with deploy-container-app as step "deploy" ...

# Tag only after a successful deploy, and on the real base commit rather than the ephemeral longtest merge.
- name: Restore QA base commit for tagging
  run: git checkout --detach "${{ steps.qa_base.outputs.base_sha }}"

- name: Create QA tag
  uses: Farmalogg-AS/ci/.github/actions/compute-qa-tag@v0.9
  with:
      release_branch: ${{ steps.qa_base.outputs.base_ref }}
      longtest_branches: ${{ steps.longtest.outputs.merged }} # optional, listed in the tag annotation
      image: ${{ steps.deploy.outputs.image }} # optional, recorded in the tag annotation
```

```yaml
- name: Sync main into release branches
  uses: Farmalogg-AS/ci/.github/actions/sync-main-into-releases@v0.9
  with:
      push_token: ${{ secrets.SYNC_RELEASE_BRANCHES_PAT }} # a PAT/App token, NOT the default GITHUB_TOKEN
```

```yaml
- name: Set up Java and Maven
  uses: Farmalogg-AS/ci/.github/actions/setup-java-maven@v0.9
  with:
      maven_repository_url: https://maven.pkg.github.com/<owner>/<repo> # omit if no extra repository is needed
      maven_repository_username: ${{ secrets.GH_PACKAGES_USERNAME }}
      maven_repository_password: ${{ secrets.GH_PACKAGES_TOKEN }}
```

```yaml
- name: Deploy to Azure Container Apps
  uses: Farmalogg-AS/ci/.github/actions/deploy-container-app@v0.9
  with:
      azure_credentials: ${{ secrets.AZURE_CREDENTIALS }}
      registry_login_server: ${{ vars.REGISTRY_LOGIN_SERVER }}
      registry_username: ${{ vars.REGISTRY_USERNAME }}
      registry_password: ${{ secrets.REGISTRY_PASSWORD }}
      image_name: ${{ vars.APP_NAME }}
      container_app_name: <container app>
      resource_group: <resource group>
```

The git actions (all but `setup-java-maven` and `deploy-container-app`) expect the calling job's checkout
step to use `fetch-depth: 0`, since they read tag history or merge branches. The tag actions also need
`permissions: contents: write` to push the tag. `sync-main-into-releases` pushes with `push_token` instead,
because pushes made with `GITHUB_TOKEN` don't trigger the release branches' own workflows.

Only steps that are the same in several repos live here. Triggers, choosing which environment to deploy to,
the build command itself, and when to tag stay in each project's own workflow files.

## Scripts

- `scripts/promote-to-qa.sh <release-branch>` — switches which release is under QA testing: updates the
  `QA_RELEASE_BRANCH` org variable, then pushes an empty `chore: promote <release-branch> to QA` commit to that
  branch in every repo that has it, so the normal push-based trigger (`qa.push.yml`) fires, deploys and creates the
  tag. Repos without that branch are skipped. Repos that have the branch but not yet the new `qa.push.yml` still
  get the empty commit; it just doesn't deploy anything there.

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
