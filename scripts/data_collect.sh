#!/bin/bash

rm data/schedules.jsonl
for file in data/sel/*/schedule.jsonl; do
    cat "$file" >>data/schedules.jsonl
done

# rm data/matches.jsonl
# for match in data/sel/*/match/json/*.json; do
#     cat "$match" >>data/matches.jsonl
# done
