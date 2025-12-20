-- schema
.schema

-- count items
select distinct count(match_id) from matches;
select distinct count(id) from schedule;

--  check missing matches
select
    ROW_NUMBER() OVER (ORDER BY s.season, s.id) as row_num,
    s.id,
    s.name,
    s.season,
    s.status_id,
    s.status_name,
    s.verified,
    m.match_id,
    m.datetime,
    s.league
from
    schedule as s
    left join matches as m on s.id = m.match_id
where
    m.match_id is null
order by
    s.season,
    s.id;
-- schedule leagues
select
    league,
    list(distinct season order by season) as seasons
from schedule
group by league
order by league;
-- teams
select distinct
    team_id::BIGINT as team_id,
    team_shortcut,
    -- team_title
from (
    select distinct
        home_team_id as team_id,
        home_team_shortcut as team_shortcut,
        -- home_team_title as team_title
    from matches
    where home_team_id is not null

    union all

    select distinct
        away_team_id as team_id,
        away_team_shortcut as team_shortcut,
        -- away_team_title as team_title
    from matches
    where away_team_id is not null
)
order by team_id;
