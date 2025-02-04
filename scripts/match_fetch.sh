#!/bin/bash

while IFS= read -r line; do
    id=$(echo "$line" | jq -r '.id')
    season=$(echo "$line" | jq -r '.season')
    mkdir -p "sel/$season/match/html"
    echo "$MATCH_URL/$id"
    curl --fail --no-progress-meter "$MATCH_URL/$id" -o "sel/$season/match/html/$id.html"
    # Generate a random number between  1 and  500 (to represent milliseconds)
    random_milliseconds=$((RANDOM % 400 + 100))
    # Convert milliseconds to seconds and sleep
    sleep_seconds=$(echo "scale=2; $random_milliseconds /  1000" | bc)
    sleep "$sleep_seconds"
done <CHANGES
