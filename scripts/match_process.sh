#!/bin/bash

if [ -f CHANGES ]; then
    while IFS= read -r line; do
        id=$(echo "$line" | jq -r '.id')
        season=$(echo "$line" | jq -r '.season')
        mkdir -p "$LEAGUE/$season/match/json"
        FILE="$LEAGUE/$season/match/html/$id.html"
        if [ -f "$FILE" ]; then
            node "$CODE_BRANCH"/src/index.js match "$FILE" | jq '.' > "$LEAGUE/$season/match/json/$id.json"
        fi
    done <CHANGES
fi
