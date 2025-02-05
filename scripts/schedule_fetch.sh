#!/bin/bash

for season in $(seq "$START" "$END"); do
    mkdir -p sel/"$season"
    echo "$SCHEDULE_URL/$season"
    curl --fail --no-progress-meter "$SCHEDULE_URL/$season" -o "sel/$season/schedule.html"
done
