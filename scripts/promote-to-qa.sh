#!/usr/bin/env bash
# Switches the release currently under QA testing: updates the QA_RELEASE_BRANCH org variable, then pushes an
# empty "chore: promote to QA" commit to that branch in every repo that has it.
#
# Why the empty commit: qa.push.yml is triggered by a push to the release branch named in
# QA_RELEASE_BRANCH (same as any other "sync main into the release branch" push). Updating the variable alone
# fires no GitHub event, so nothing redeploys automatically. If the branch already happens to be fully synced
# with main there's nothing new to merge/push either — the empty commit guarantees a triggering push either
# way, without requiring an actual code change.
#
# Requires: gh CLI, authenticated with an account/token that has org variable admin rights, and `gh auth
# setup-git` (or otherwise configured git credentials) so plain `git push` works against these repos.
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
    if ! gh api "repos/$ORG/$repo/branches/$BRANCH" >/dev/null 2>&1; then
        echo "Skipping $repo (no $BRANCH branch)"
        continue
    fi

    echo "Pushing promote-to-QA commit to $repo@$BRANCH"
    dir="$WORKDIR/$repo"
    gh repo clone "$ORG/$repo" "$dir" -- --branch "$BRANCH" --single-branch --depth 1 --quiet
    (
        cd "$dir"
        git commit --allow-empty -m "chore: promote $BRANCH to QA"
        git push origin "$BRANCH"
    )
done
