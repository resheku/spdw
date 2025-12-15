#!/bin/bash

# select all raced matches (status.id is 1)
for season in $(seq "$START" "$END"); do
    echo "$season"
    jq -c 'select(.status.id == 1)' "$LEAGUE/$season/schedule.jsonl" | tee -a CHANGES
done
