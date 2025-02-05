#!/bin/bash

# select all raced matches (status.id is 1)
for season in $(seq "$START" "$END"); do
    jq -c 'select(.status.id == 1)' "sel/$season/schedule.jsonl" | tee -a CHANGES
done
