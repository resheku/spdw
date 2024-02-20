#!/bin/bash
git config user.name "Automated"
git config user.email "actions@users.noreply.github.com"
git add data/
timestamp=$(date -u)
git commit -m "Latest data: ${timestamp}" && echo "changes=1" >> $GITHUB_OUTPUT
git push
