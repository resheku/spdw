#!/bin/bash

git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add ${LEAGUE}/

# Check for changes in JSON files if FORCE is not true
if [ "$FORCE" = "true" ]; then
    echo "Force commit"
else
    # Check for changes in JSON files
    json_changes=$(git diff --cached --name-only --diff-filter=ACM | grep '\.json$')
    if [ -z "$json_changes" ]; then
        echo "No changes in JSON files"
        exit 0
    fi
fi

timestamp=$(date -u)
git commit -m "Match ${LEAGUE}: ${timestamp}" || true
git push
