# Changelog

Notable changes to the shared actions/scripts here, per version tag. Consuming repos pin to a tag (e.g.
`@v0.1`) rather than `@main`; bump the pinned ref deliberately after checking what changed.

## v0.9

- `compute-release-tag` — fixed the step failing, after the prod deploy, whenever no `release/vX.Y` branch was
  merged since the last tag, i.e. for every hotfix: GitHub runs `shell: bash` with `pipefail`, so finding no
  release merge failed the step instead of choosing a patch bump.
- `merge-longtest-branches` — new `merged` output: the `longtest/*` branches it merged, as space-separated
  `<branch>@<commit>` entries (empty if none).
- `compute-qa-tag` — the tag annotation now describes the deploy: base branch and commit, merged `longtest/*`
  branches, image, trigger and a link to the run. Release-branch tags also list the changes since the previous
  QA tag of that release (or, for its first, the latest prod tag): `feat`, `fix`, `perf` and `vis` commits by
  subject, other types counted. To record the longtest branches and image, pass the new optional inputs
  `longtest_branches` (`merge-longtest-branches`' `merged` output) and `image`.
- `compute-release-tag` — the tag annotation now records the previous tag, why it bumped minor or patch,
  trigger, a link to the run, and the changes since the previous tag, listed as for QA tags. To record the
  image, pass the new optional input `image`.
- `compute-qa-tag` / `compute-release-tag` — tags are now created by `github-actions[bot]`, with its noreply
  address, so GitHub shows and links the bot as the tagger.

## v0.8

- `resolve-qa-base-ref` / `compute-qa-tag` — branch names now reach the scripts through environment variables
  instead of being pasted into them, so a branch named e.g. `longtest/$(cmd)` can't run commands in the job.
- `setup-java-maven` — new action: installs a Temurin JDK (21 by default) with Maven caching, and, if
  `maven_repository_url` is given, writes a `settings.xml` with that repository and its credentials. Replaces
  the `actions/setup-java` step plus the inline `settings.xml` heredoc in callers' workflows; the generated
  file is the same.
- `deploy-container-app` — new action: logs in to Azure (`azure/login@v2`) and the registry, builds the image
  from the checkout tagged with the short HEAD commit hash, pushes it, and deploys it to a Container App.
  Replaces callers' Azure login, ACR login, commit hash, docker build/push and deploy steps. Azure login now
  happens right before the deploy rather than before the build, so a build that needs Azure credentials (e.g.
  tests reading Key Vault) must log in itself first.
- `compute-qa-tag` — also tags branches other than `release/vX.Y`, with a unique
  `qa/branch/<branch>/<run id>.<run attempt>` tag, so callers no longer need their own tag step for manual
  deploys of other branches. Before, those got a meaningless tag such as `qa/vmain.0.1`. The input is still
  called `release_branch`.
- `resolve-qa-base-ref` — new `base_sha` output: the commit of `base_ref` that was checked out, i.e. what to
  tag after deploying. Replaces the step callers needed to save `git rev-parse HEAD` before
  `merge-longtest-branches` moved HEAD.

## v0.7

- `compute-release-tag` — detects a shipped release from a `release/vX.Y` branch merge into `main` again. v0.6
  looked for `prod/vX.Y` merges instead, which never match, so every run was treated as a hotfix (patch bump).
- `sync-main-into-releases` — now always pushes with `push_token`. Before, the `GITHUB_TOKEN` that
  `actions/checkout` stores by default took precedence, so sync pushes didn't trigger the release branches'
  workflows unless the caller's checkout set `persist-credentials: false`. That setting is no longer needed.

## v0.6

- `compute-release-tag` — now creates/pushes the next production `prod/vX.Y.Z` tag instead of
  `release/vX.Y.Z`, so "release" only ever means a branch, never a tag. Existing `release/vX.Y.Z` tags are
  ignored when computing the next one, so recreate them as `prod/vX.Y.Z` before bumping.
- Known issue: `compute-release-tag` treats every run as a hotfix (patch bump). Fixed in v0.7; use that
  instead.

## v0.5

- `compute-qa-tag` / `compute-release-tag` — tags now live under dedicated `qa/` and `release/` namespaces
  (`qa/vX.Y.0.N` and `release/vX.Y.Z`) instead of flat `vX.Y.0-qa.N` / `vX.Y.Z`, so QA and production tags
  are visually and programmatically distinguishable (e.g. `git tag --list "release/*"`). Tags in the old format
  are ignored when computing the next one: QA numbering restarts at `.1` for each release, and existing
  `vX.Y.Z` production tags must be recreated as `release/vX.Y.Z` before bumping.
- `sync-main-into-releases` — new action: merges `main` into every `release/v*` branch that doesn't already
  contain it, and pushes the result. Skips branches with nothing to merge, which also prevents a release
  branch's own merge into `main` from looping back into itself. Requires a non-default push token so the
  sync push retriggers each branch's own CI. Until v0.7, the caller's checkout also needs
  `persist-credentials: false` for that to work.

## v0.4

- `resolve-qa-base-ref` — new action: resolves and checks out whichever branch is actually under QA testing
  (a release branch, or `main` if none is active), regardless of whether `main`, the release branch, or a
  `longtest/*` branch triggered the run.
- `merge-longtest-branches` — new action: ephemerally merges every active `longtest/*` branch (long-lived
  branches for extended external testing that must never reach `main`) on top of the QA base, for the build
  only — never pushed. This is what lets long-lived test work stay visible in QA at all times, even while a
  release is being tested, without ever leaking into a production release.
- To use these, add `longtest/*` to the QA workflow's push trigger, and run `compute-qa-tag` on the resolved
  base commit rather than after `merge-longtest-branches`, so QA tags never point at the ephemeral merge (see
  the usage example in [README.md](README.md)).

## v0.3

- `compute-release-tag` — now auto-detects minor vs. patch by looking for the highest `release/vX.Y` merge
  commit into `main` since the last tag, instead of requiring a manual `bump` input every time. The `bump`
  input is now optional and only needed to force a choice (e.g. if a merge was squashed instead of a real
  merge commit).

## v0.2

- `scripts/promote-to-qa.sh` — reworked to push an empty "chore: promote to QA" commit after updating
  `QA_RELEASE_BRANCH`, instead of manually dispatching `qa-deploy.yml`. This reuses the normal push-based
  trigger (same as any other sync-with-main push) instead of a separate manual-trigger code path. Repos need a
  QA workflow triggered by pushes to the active release branch for this to deploy anything.

## v0.1

- `compute-qa-tag` — creates/pushes the next `vX.Y.0-qa.N` tag for a release branch.
- `compute-release-tag` — creates/pushes the next production `vX.Y.Z` tag (minor/patch bump).
- `scripts/promote-to-qa.sh` — switches the `QA_RELEASE_BRANCH` org variable and triggers `qa-deploy.yml`
  across all repos that have that branch.
