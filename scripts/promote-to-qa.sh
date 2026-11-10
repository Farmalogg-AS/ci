#!/usr/bin/env bash
# Switches the release currently under QA testing: updates the QA_RELEASE_BRANCH org variable, then pushes an
# empty "chore: promote <release-branch> to QA" commit to that branch in every repo. Repos that don't have the
# branch yet get it cut from main first: without it, main's changes would never reach TEST or QA there (only
# release branches deploy, and the main sync has nothing to merge into), and its next prod tag would bump the
# patch instead of the minor version, breaking lockstep versioning.
#
# Why the empty commit: qa.push.yml is triggered by a push to the release branch named in
# QA_RELEASE_BRANCH (same as any other "sync main into the release branch" push). Updating the variable alone
# fires no GitHub event, so nothing redeploys automatically. If the branch already happens to be fully synced
# with main there's nothing new to merge/push either — the empty commit guarantees a triggering push either
# way, without requiring an actual code change.
#
# Requires: gh CLI, authenticated with an account/token that has org variable admin rights (for a classic login,
# the admin:org scope: `gh auth refresh -h github.com -s admin:org`), and `gh auth setup-git` (or otherwise
# configured git credentials) so plain `git push` works against these repos.
#
# Usage: ./promote-to-qa.sh release/v2.4

set -euo pipefail

BRANCH="${1:?Usage: promote-to-qa.sh <release-branch>, e.g. release/v2.4}"
ORG="Farmalogg-AS"
REPOS=(
    varer
    filflyt
    firma
    kodeverk
    vareweb-frontend
    vareweb-integration-external
    vareweb-integration-internal
)

echo "Setting org variable QA_RELEASE_BRANCH=$BRANCH"
gh variable set QA_RELEASE_BRANCH --org "$ORG" --body "$BRANCH" --visibility all

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

for repo in "${REPOS[@]}"; do
    dir="$WORKDIR/$repo"
    if gh api "repos/$ORG/$repo/branches/$BRANCH" >/dev/null 2>&1; then
        echo "Pushing promote-to-QA commit to $repo@$BRANCH"
        gh repo clone "$ORG/$repo" "$dir" -- --branch "$BRANCH" --single-branch --depth 1 --quiet
    else
        echo "Cutting $BRANCH from main in $repo and pushing promote-to-QA commit"
        gh repo clone "$ORG/$repo" "$dir" -- --branch main --single-branch --depth 1 --quiet
        git -C "$dir" switch --quiet --create "$BRANCH"
    fi
    (
        cd "$dir"
        git commit --allow-empty -m "chore: promote $BRANCH to QA"
        git push origin "$BRANCH"
    )
done
