#!/bin/bash

for season in $(seq "$START" "$END"); do
    mkdir -p "$LEAGUE/$season"
    echo "$SCHEDULE_URL/$season"
    curl --fail --no-progress-meter "$SCHEDULE_URL/$season" -o "$LEAGUE/$season/schedule.html" || {
        echo "Warning: Could not fetch schedule for season $season, skipping"
    }
done
