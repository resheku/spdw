#!/bin/bash

if [ -f CHANGES ]; then
    while IFS= read -r line; do
        id=$(echo "$line" | jq -r '.id')
        season=$(echo "$line" | jq -r '.season')
        mkdir -p "data/sel/$season/match/json"
        FILE="data/sel/$season/match/html/$id.html"
        if [ -f "$FILE" ]; then
            node "$CODE_BRANCH"/src/index.js match "$FILE" | jq '.' >"data/sel/$season/match/json/$id.json"
        fi
    done <CHANGES
fi
