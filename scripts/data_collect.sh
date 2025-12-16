#!/bin/bash

# Collect schedules for sel and sel2
for league in sel sel2; do
    rm -f ${league}/schedules.jsonl
    for file in ${league}/*/schedule.jsonl; do
        cat "$file" >>${league}/schedules.jsonl
    done
done

# rm matches.jsonl
# for match in sel/*/match/json/*.json; do
#     cat "$match" >>sel/matches.jsonl
# done
