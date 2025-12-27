#!/bin/bash

for season in $(seq "$START" "$END"); do
    echo "${season}"
    node "$CODE_BRANCH"/src/index.js schedule "$LEAGUE/$season/schedule.html" | jq '.' > "$LEAGUE/$season/schedule.jsonl"
done
