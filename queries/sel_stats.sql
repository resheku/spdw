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
    season,
    h.match_id,
    rider_name, rider_surname, team_id, team_shortcut,
    score, bonus,
    warn,
    coalesce(h.substitute_id, h.rider_id) as rider,
    h.points,
    row_number() over (partition by h.match_id, h.heat_no, coalesce(h.substitute_id, h.rider_id) order by case when h.score ~ '^[0-9]+$' then 1 else 2 end, h.heat_id) as rn
  from heats h
  left join matches m on m.match_id = h.match_id
  left join lineup l on h.match_id = l.match_id and coalesce(h.substitute_id, h.rider_id) = l.rider_id
  join warn_subquery w
  on h.match_id = w.match_id
  and coalesce(h.substitute_id, h.rider_id) = w.rider_id
  and h.heat_id = w.heat_id
  where h.score is not null
    and h.score != '-'
    order by h.match_id, h.heat_no, h.gate, h.canceled desc, score desc
)
select 
  season as 'Season',
  concat(rider_name, ' ', rider_surname) as Name,
  team_shortcut as Team,
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
  cast(coalesce(sum(warn), 0) as int) as Warn
from ranked_heats
where rn = 1 
group by season, rider, concat(rider_name, ' ', rider_surname), team_shortcut
order by average desc, points desc, heats desc, concat(rider_name, ' ', rider_surname);
