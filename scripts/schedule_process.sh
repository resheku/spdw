#!/bin/bash

for season in $(seq "$START" "$END"); do
    node "$CODE_BRANCH"/src/index.js schedule "sel/$season/schedule.html" | jq '.' >"sel/$season/schedule.jsonl"
done
