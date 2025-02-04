#!/bin/bash

for season in $(seq "$START" "$END"); do
    node "$CODE_BRANCH"/src/index.js schedule "data/sel/$season/schedule.html" | jq '.' >"data/sel/$season/schedule.jsonl"
done
