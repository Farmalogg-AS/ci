#!/usr/bin/env bash
# Prints the lines of a tag annotation that describe the workflow run: the deployed image (if $IMAGE is set),
# what triggered the run, and a link to it. Reads the runner's default GITHUB_* environment variables.
set -euo pipefail

case "$GITHUB_EVENT_NAME" in
    push) TRIGGER="push to $GITHUB_REF_NAME" ;;
    workflow_dispatch) TRIGGER="manual run on $GITHUB_REF_NAME" ;;
    *) TRIGGER="$GITHUB_EVENT_NAME on $GITHUB_REF_NAME" ;;
esac

if [ -n "${IMAGE:-}" ]; then echo "Image: $IMAGE"; fi
echo "Trigger: $TRIGGER by $GITHUB_ACTOR"
echo "Run: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/attempts/$GITHUB_RUN_ATTEMPT"
