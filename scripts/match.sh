#!/bin/bash
echo "process changes"
while IFS= read -r line; do
    id=$(echo "$line" | jq -r '.id')
    season=$(echo "$line" | jq -r '.season')
    url="https://ekstraliga.pl/mecz/$id"
    mkdir -p "data/sel/$season/match/html"
    echo "$url"
    curl -f --no-progress-meter "$url" -o "data/sel/$season/match/html/$id.html"
    # Generate a random number between  1 and  500 (to represent milliseconds)
    random_milliseconds=$(( RANDOM %  400 +  100  ))
    # Convert milliseconds to seconds and sleep
    sleep_seconds=$(echo "scale=2; $random_milliseconds /  1000" | bc)
    sleep $sleep_seconds
done < CHANGES
