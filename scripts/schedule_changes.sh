#!/bin/bash

echo "CHANGED FILES"
for file in $(git diff --name-only --diff-filter=M HEAD^ HEAD); do
    # check if the file exists and is a json file
    if [[ -e "$file" && "$file" == "${LEAGUE}/*/schedule.jsonl" ]]; then
        echo "$file"
        # get the hashes of the commits that modified the file except the most recent one
        hash=$(git log -n 2 --pretty=format:%h -- "$file" | tail -n 1)
        # compare the previous version of the file with the current one
        diff -e <(git show "$hash:$file" | jq -c 'select(.status.id == 1)') \
            <(jq -c 'select(.status.id == 1)' "$file") |
            grep '^{' | tee -a CHANGES
    fi
done

echo ""
echo "ADDED FILES"
for file in $(git diff --name-only --diff-filter=A HEAD^ HEAD); do
    if [[ -e "$file" && "$file" == "${LEAGUE}/*/schedule.jsonl" ]]; then
        echo "$file"
        jq -c 'select(.status.id == 1)' "$file" | tee -a CHANGES
    fi
done

# If no schedule changes found, process all schedule files
if ! git diff --name-only --diff-filter=AM HEAD^ HEAD | grep -q "${LEAGUE}/.*/schedule.jsonl"; then
    echo ""
    echo "No schedule changes in diff - processing all matches"
    for file in ${LEAGUE}/*/schedule.jsonl; do
        if [[ -e "$file" ]]; then
            echo "$file"
            jq -c 'select(.status.id == 1)' "$file" | tee -a CHANGES
        fi
    done
fi
