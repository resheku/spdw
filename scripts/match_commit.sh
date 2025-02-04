#!/bin/bash

git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add data/

# Check for changes in JSON files
json_changes=$(git diff --cached --name-only --diff-filter=ACM | grep '\.json$')
if [ -z "$json_changes" ]; then
    echo "No changes in JSON files"
    exit 0
fi

timestamp=$(date -u)
git commit -m "Match: ${timestamp}" || true
git push
