#!/bin/bash

rm -f data/schedules.jsonl
for file in data/sel/*/schedule.jsonl; do
    cat "$file" >>data/sel/schedules.jsonl
done

# rm data/matches.jsonl
# for match in data/sel/*/match/json/*.json; do
#     cat "$match" >>data/sel/matches.jsonl
# done
