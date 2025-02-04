#!/bin/bash

for season in $(seq "$START" "$END"); do
    mkdir -p data/sel/"$season"
    echo "$SCHEDULE_URL/$season"
    curl --fail --no-progress-meter "$SCHEDULE_URL/$season" -o "data/sel/$season/schedule.html"
done
