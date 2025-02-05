#!/bin/bash

git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add sel.db sel/

# Check for changes in match JSON files
json_changes=$(git diff --cached --name-only --diff-filter=ACM | grep 'matches.jsonl$')
if [ -z "$json_changes" ]; then
    echo "No changes."
    echo "changes=0" >>"$GITHUB_OUTPUT"
    exit 0
fi

timestamp=$(date -u)
git commit -m "Data: ${timestamp}" && echo "changes=1" >"$GITHUB_OUTPUT"
git push
