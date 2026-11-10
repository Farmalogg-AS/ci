#!/usr/bin/env bash
# Switches which release is under QA testing: sets the QA_RELEASE_BRANCH org variable, then pushes an empty
# "chore: promote <release-branch> to QA" commit to that branch in every repo.
#
# Repos without the branch get it cut from main first. Only release branches deploy to TEST and QA, so without
# it main's changes never get there, and the repo wouldn't release the same vX.Y as the others.
#
# The empty commit triggers the QA deploy (qa.push.yml): setting the variable fires no event, and the branch may
# have nothing new to push. On a newly cut branch, it also gives the release a commit of its own, so it can be
# merged into main and its prod tag bumps the minor version rather than the patch.
#
# Requires: gh CLI logged in with org variable admin rights (classic token: `gh auth refresh -h github.com -s
# admin:org`), and git credentials for plain `git push` (e.g. `gh auth setup-git`).
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
