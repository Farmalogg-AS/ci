#!/usr/bin/env bash
# Switches the release currently under QA testing: updates the QA_RELEASE_BRANCH org variable and
# (re)triggers the manual qa-deploy.yml workflow in every repo that has the given release branch.
#
# Why this is needed: updating QA_RELEASE_BRANCH is just data, it doesn't fire any GitHub event, so nothing
# auto-deploys. Any earlier push to this branch (while a different release was under QA) was already skipped
# by that workflow's branch check, so it won't rerun on its own either. This script does both steps together.
#
# Requires: gh CLI, authenticated with an account/token that has org variable admin rights and can dispatch
# workflows on the repos below (e.g. `gh auth login`, or GH_TOKEN set to a suitable PAT).
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

for repo in "${REPOS[@]}"; do
    if gh api "repos/$ORG/$repo/branches/$BRANCH" >/dev/null 2>&1; then
        echo "Triggering QA deploy for $repo@$BRANCH"
        gh workflow run qa-deploy.yml --repo "$ORG/$repo" --ref "$BRANCH"
    else
        echo "Skipping $repo (no $BRANCH branch)"
    fi
done
