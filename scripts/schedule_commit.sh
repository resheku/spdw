#!/bin/bash

git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add data/

# Check for changes in JSON files
json_changes=$(git diff --cached --name-only --diff-filter=ACM | grep '\.jsonl$')
if [ -z "$json_changes" ]; then
    echo "No changes in JSON files"
    echo "changes=0" >>"$GITHUB_OUTPUT"
    exit 0
fi

timestamp=$(date -u)
git commit -m "Schedule: ${timestamp}" && echo "changes=0" >"$GITHUB_OUTPUT"
# commit_status=$?
if [ "$FORCE" = "true" ]; then
    echo "changes=1" >>"$GITHUB_OUTPUT"
fi
git push
