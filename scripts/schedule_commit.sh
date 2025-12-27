#!/bin/bash

git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add ${LEAGUE}/

# Check for changes in JSON files if FORCE is not true
if [ "$FORCE" = "true" ]; then
    echo "Force commit"
    echo "changes=1" >>"$GITHUB_OUTPUT"
else
    json_changes=$(git diff --cached --name-only --diff-filter=ACM | grep '\.jsonl$')
    if [ -z "$json_changes" ]; then
        echo "No changes to commit"
        echo "changes=0" >>"$GITHUB_OUTPUT"
        exit 0
    fi
fi

timestamp=$(date -u)
git commit -m "Schedule ${LEAGUE}: ${timestamp}" && echo "changes=1" >"$GITHUB_OUTPUT"
# commit_status=$?

git push
