drop table if exists stats;
create table stats as
with warn_subquery as (
    select
        h.match_id, h.heat_no, h.heat_id, coalesce(h.substitute_id, h.rider_id) as rider_id,
        max(h.warning) over (
            partition by h.match_id, h.heat_no, coalesce(h.substitute_id, h.rider_id)
            order by h.match_id, h.heat_no, h.rider_id
        ) as warn
    from heats h
),
telemetry as (
    select
        m.season,
        s.league,
        t.rider_id,
        round(max(t.max_speed), 2) as max_speed
    from
        sel.telemetry t
        join sel.matches m on t.match_id = m.match_id
        join sel.schedule s on s.id = m.match_id
    where
        t.max_speed is not null
        and t.max_speed != 0
    group by
        m.season,
        s.league,
        t.rider_id
    order by
        m.season,
        s.league,
        t.rider_id
),
ranked_heats as (
    select
        case
            when l.team_id = m.home_team_id then m.home_team_shortcut
            when l.team_id = m.away_team_id then m.away_team_shortcut
            else null
        end as team_shortcut,
        case 
            when l.team_id = m.home_team_id then 1 else 0
        end as home,
        m.season,
        h.match_id,
        l.rider_name, l.rider_surname, l.team_id, team_shortcut,
        h.score, h.bonus,
        warn,
        coalesce(h.substitute_id, h.rider_id) as rider,
        h.points,
        row_number() over (partition by h.match_id, h.heat_no, coalesce(h.substitute_id, h.rider_id) order by case when h.score ~ '^[0-9]+$' then 1 else 2 end, h.heat_id) as rn,
        t.max_speed,
        s.league
    from heats h
    left join matches m on m.match_id = h.match_id
    left join lineup l on h.match_id = l.match_id and coalesce(h.substitute_id, h.rider_id) = l.rider_id
    join warn_subquery w
        on h.match_id = w.match_id
        and coalesce(h.substitute_id, h.rider_id) = w.rider_id
        and h.heat_id = w.heat_id
    left join schedule s on s.id = m.match_id
    left join telemetry t
        on m.season = t.season
        and s.league = t.league
        and coalesce(h.substitute_id, h.rider_id) = t.rider_id
    where h.score is not null
        and h.score != '-'
        and m.match_subtype_id != 7
    order by h.match_id, h.heat_no, h.gate, h.canceled desc, score desc
)
select 
    season as "Season",
    concat(rider_name, ' ', rider_surname) as Name,
    string_agg(distinct team_shortcut, '/' order by team_shortcut) as Team,
    round((sum(points)+sum(bonus)) / count(*), 3) as Average,
    cast(count(distinct match_id) as int) as Match, 
    cast(count(*) as int) as Heats , 
    cast(sum(points) as int) as Points,
    cast(sum(bonus) as int) as Bonus,
    round((sum(points) filter (where home = 1) + sum(bonus) filter (where home = 1)) / count(*) filter (where home = 1), 3) as 'Home Avg.',
    round((sum(points) filter (where home = 0) + sum(bonus) filter (where home = 0)) / count(*) filter (where home = 0), 3) as 'Away Avg.',
    cast(count(*) filter (where points = 3) as int) AS "I",
    cast(count(*) filter (where points = 2) as int) AS "II",
    cast(count(*) filter (where points = 1) as int) AS "III",
    cast(count(*) filter (where score = '0') as int) AS "IV",
    cast(count(*) filter (where score = 'D') as int) AS "R",
    cast(count(*) filter (where score = 'T') as int) AS "T",
    cast(count(*) filter (where score = 'M') as int) AS "M",
    cast(count(*) filter (where score = 'W') as int) AS "X",
    cast(count(*) filter (where score = 'U') as int) AS "F",
    cast(coalesce(sum(warn), 0) as int) as Warn,
    max(max_speed) as "Max Speed",
    league as League
from ranked_heats
where rn = 1 
group by season, rider, concat(rider_name, ' ', rider_surname), league
order by average desc, points desc, heats desc, concat(rider_name, ' ', rider_surname);

-- Track stats historical (as-of race date)
-- One row per match_id: track mean and stddev computed from all telemetry
-- at the same track_city with datetime_schedule <= this match's datetime_schedule.
DROP TABLE IF EXISTS spdw_telemetry_stats;
CREATE TABLE spdw_telemetry_stats AS
WITH match_telemetry AS (
    -- Aggregate per match: sum and sum-of-squares of max_speed for efficient running stats
    SELECT
        m.match_id,
        m.track_city,
        m.datetime_schedule,
        COUNT(t.max_speed)              AS cnt,
        SUM(t.max_speed)                AS sum_speed,
        SUM(t.max_speed * t.max_speed)  AS sum_sq_speed
    FROM sel.telemetry t
    JOIN sel.matches m ON t.match_id = m.match_id
    WHERE t.max_speed IS NOT NULL
      AND t.max_speed > 0
      AND m.datetime_schedule IS NOT NULL
    GROUP BY m.match_id, m.track_city, m.datetime_schedule
),
running AS (
    -- Cumulative window: include all matches at the same track up to and including
    -- the current match's scheduled datetime (RANGE semantics so ties are included).
    SELECT
        match_id,
        track_city,
        SUM(cnt)          OVER w AS total_cnt,
        SUM(sum_speed)    OVER w AS total_sum,
        SUM(sum_sq_speed) OVER w AS total_sum_sq
    FROM match_telemetry
    WINDOW w AS (
        PARTITION BY track_city
        ORDER BY datetime_schedule
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
)
SELECT
    match_id,
    track_city,
    total_sum / total_cnt AS track_mean_asof,
    CASE
        WHEN total_cnt <= 1 THEN NULL
        ELSE SQRT((total_sum_sq - total_sum * total_sum / total_cnt) / (total_cnt - 1))
    END AS track_stddev_asof,
    total_cnt AS n_obs
FROM running;
