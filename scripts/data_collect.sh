#!/bin/bash

rm -f sel/schedules.jsonl
for file in sel/*/schedule.jsonl; do
    cat "$file" >>sel/schedules.jsonl
done

# rm matches.jsonl
# for match in sel/*/match/json/*.json; do
#     cat "$match" >>sel/matches.jsonl
# done
