#!/bin/bash
for i in 2023; do
    mkdir -p data/sel/$i
    echo https://stats.speedwayekstraliga.pl/api/v1/matches/schedule?s=$i
    curl -f --no-progress-meter https://stats.speedwayekstraliga.pl/api/v1/matches/schedule?s=$i -o data/sel/$i/schedule.json
done
