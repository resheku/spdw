attach 'sel.db' as sel;

create table schedule as(select * from read_json_auto('sel/schedules.jsonl'));
create table matches as(select * from read_json_auto('sel/matches.jsonl'));

-- schedule
CREATE TABLE sel.schedule AS (
    SELECT
        id,
        status_id,
        season,
        verified,
        schedule->>'$.name.en' as name,
        schedule->>'$.status.name.en' as status_name
    FROM schedule
);
-- matches
--   card_teams
--       no
--       card_id
--       position
CREATE TABLE sel.matches AS(
    SELECT match.id as match_id,
        CAST(match->>'$.attendance' AS INT) as attendance,
        CAST(match->>'$.card_type_id' AS INT) as card_type_id,
        CAST(match->>'$.verified' AS INT) as verified,
        CAST(match->>'$.season' AS INT) as season,
        CAST(match->'$.has_telemetry' AS INT) as has_telemetry,
        match->>'$.name.pl' as name,
        match->>'$.shortname.pl' as shortname_pl,
        match->>'$.description.pl' as description_pl,
        strftime(
            timezone(
                'Europe/Warsaw',
                to_timestamp(match.datetime_schedule / 1000)
            ),
            '%Y-%m-%d %H:%M'
        ) AS datetime,
        match->>'$.datetime_schedule' as datetime_schedule,
        CAST(match->>'$.round' AS INT) as round,
        CAST(match->>'$.status.id' AS INT) as status_id,
        match->>'$.status.name.pl' as status_name_pl,
        match->>'$.status.name.en' as status_name_en,
        CAST(match->>'$.broadcaster_schedule.id' AS INT) as broadcaster_schedule_id,
        match->>'$.broadcaster_schedule.title' as broadcaster_schedule_title,
        CAST(match->>'$.match_type.id' AS INT) as match_type_id,
        match->>'$.match_type.shortname.pl' as match_type_shortname_pl,
        match->>'$.match_type.name.pl' as match_type_name_pl,
        match->>'$.match_type.name.en' as match_type_name_en,
        CAST(match->'$.match_type.team_competition' AS INT) as team_competition,
        CAST(match->'$.match_type.has_home_away' AS INT) as has_home_away,
        CAST(match->'$.match_type.has_rounds' AS INT) as has_rounds,
        CAST(match->>'$.match_subtype.id' AS INT) as match_subtype_id,
        match->>'$.match_subtype.name.pl' as match_subtype_name_pl,
        match->>'$.match_subtype.name.en' as match_subtype_name_en,
        match->>'$.match_subtype.shortname.pl' as match_subtype_shortname_pl,
        match->>'$.match_subtype.shortname.en' as match_subtype_shortname_en,
        match->>'$.postponed' as postponed,
        match->>'$.postponed_first' as postponed_first,
        CAST(match->>'$.track_id' AS INT) as track_id,
        match->>'$.track.city' as track_city,
        match->>'$.track.fullname' as track_fullname,
        CAST(match->>'$.track_commissioner.id' AS INT) as track_commissioner_id,
        match->>'$.track_commissioner.name' as track_commissioner_name,
        match->>'$.track_commissioner.surname' as track_commissioner_surname,
        CAST(match->>'$.referee.id' AS INT) as referee_id,
        match->>'$.referee.name' as referee_name,
        match->>'$.referee.surname' as referee_surname,
        CAST(match->>'$.card_teams[0].match_score' AS INT) as home_match_score,
        CAST(
            match->>'$.card_teams[0].match_tlt_score' AS INT
        ) as home_match_tlt_score,
        CAST(match->>'$.card_teams[0].team_id' AS INT) as home_team_id,
        match->>'$.card_teams[0].team_shortcut' as home_team_shortcut,
        match->>'$.card_teams[0].team_title' as home_team_title,
        CAST(match->>'$.card_teams[0].coach_id' AS INT) as home_coach_id,
        match->>'$.card_teams[0].coach' as home_coach,
        CAST(match->>'$.card_teams[0].manager_id' AS INT) as home_manager_id,
        match->>'$.card_teams[0].manager' as home_manager,
        CAST(
            match->>'$.card_teams[0].team_manager_id' AS INT
        ) as home_team_manager_id,
        match->>'$.card_teams[0].team_manager' as home_team_manager,
        CAST(match->>'$.card_teams[1].match_score' AS INT) as away_match_score,
        CAST(
            match->>'$.card_teams[1].match_tlt_score' AS INT
        ) as away_match_tlt_score,
        CAST(match->>'$.card_teams[1].team_id' AS INT) as away_team_id,
        match->>'$.card_teams[1].team_shortcut' as away_team_shortcut,
        match->>'$.card_teams[1].team_title' as away_team_title,
        CAST(match->>'$.card_teams[1].coach_id' AS INT) as away_coach_id,
        match->>'$.card_teams[1].coach' as away_coach,
        CAST(match->>'$.card_teams[1].manager_id' AS INT) as away_manager_id,
        match->>'$.card_teams[1].manager' as away_manager,
        CAST(
            match->>'$.card_teams[1].team_manager_id' AS INT
        ) as away_team_manager_id,
        match->>'$.card_teams[1].team_manager' as away_team_manager
    FROM matches
);
-- lineups
-- user_id -- same as rider_id
-- scores_regular
--         score
--         joker
--         bonus
--         lineup_id
--     scores_additional
CREATE TABLE sel.lineup AS(
    WITH lineup AS (
        SELECT unnest(lineups) as l
        FROM matches
    )
    SELECT l.card_id as match_id,
        l.id as lineup_id,
        l.protocol_id,
        l.type,
        l.team_id,
        l.no,
        l.team_no,
        CAST(l->>'$.rider.id' AS INT) as rider_id,
        l->>'$.rider.name' as rider_name,
        l->>'$.rider.surname' as rider_surname,
        l.points,
        l.points_regular,
        l.bonuses,
        l.bonuses_regular,
        l.starts,
        l.starts_regular,
        l.starts_additional,
        CAST(l.rider_replacement AS INT) as rider_replacement,
        l->>'$.average_order' as average_order,
        CAST(l->>'$.warning_heat_order' AS DOUBLE) as warning_heat_order,
        l->>'$.position' as position,
        CAST(l.status AS INT) as "status",
        CAST(l.affiliation_id AS INT) as affiliation_id
        FROM lineup
);
-- create heats table
CREATE TABLE sel.heats AS(
    WITH heat AS (
        SELECT match.id as match_id,
            unnest(heats) as h
        FROM matches
    ),
    results AS (
        SELECT match.id as match_id,
            unnest(heats->'$[*].results[*]') as r
        FROM matches
    )
    SELECT m.match.id as match_id,
        h.id as heat_id,
        CAST(h.canceled AS INT) as canceled,
        h.no as heat_no,
        h.restart_id,
        CAST(h->>'$.home_heat_score' AS INT) as home_heat_score,
        CAST(h->>'$.away_heat_score' AS INT) as away_heat_score,
        CAST(h->>'$.home_match_score' AS INT) as home_match_score,
        CAST(h->>'$.away_match_score' AS INT) as away_match_score,
        CAST(r->>'$.rider_id' AS INT) as rider_id,
        CAST(r->>'$.rider_no' AS INT) as rider_no,
        r->>'$.helmet' as helmet,
        CAST(r->'$.joker' AS INT) as joker,
        r->>'$.gate' as gate,
        r->>'$.score' as score,
        CASE
            WHEN score ~ '^[0-9]+$' THEN
                CASE
                    WHEN CAST(joker AS INT) = 1 THEN CAST(CAST(score AS DOUBLE) / 2 AS INT)
                    ELSE CAST(score AS INT)
                END
            ELSE 0
        END AS points,
        CAST(r->'$.bonus' AS INT) as bonus,
        CAST(r->>'$.substitute_id' AS INT) as substitute_id,
        CAST(r->>'$.substitute_no' AS INT) as substitute_no,
        CAST(r->>'$.warning' AS INT) as warning -- home_heat_score
    FROM heat
        JOIN matches m ON heat.match_id = m.match.id
        JOIN results ON r.heat_id = h.id
    order by m.match.id,
        h.no,
        h.id,
        h.restart_id,
        r.gate
);
-- telemetry
--     general
--       rider_id
--       no
--       name
--       surname
--       team_shortcut
--       best_reaction
--       best_reaction_heat_no
--       best_time
--       best_time_heat_no
--       best_max_speed
--       best_max_speed_heat_no
CREATE TABLE sel.telemetry AS(
    WITH details AS (
        SELECT match.id as match_id,
            unnest(telemetry->'$[*].details[*]') as d
        FROM matches
    )
    SELECT DISTINCT details.match_id,
        CAST(d->>'$.rider_id' AS INT) as rider_id,
        CAST(d->>'$.heat_id' AS INT) as heat_id,
        CAST(d->>'$.heat_no' AS INT) as heat_no,
        CAST(d->>'$.distance' AS DOUBLE) as distance,
        CAST(d->>'$.time' AS DOUBLE) as heat_time,
        CAST(d->>'$.reaction' AS DOUBLE) as reaction,
        CAST(d->>'$.max_speed' AS DOUBLE) as max_speed,
        CAST(d->>'$.l1_time' AS DOUBLE) as l1_time,
        CAST(d->>'$.l2_time' AS DOUBLE) as l2_time,
        CAST(d->>'$.l3_time' AS DOUBLE) as l3_time,
        CAST(d->>'$.l4_time' AS DOUBLE) as l4_time
    FROM details
    ORDER BY details.match_id,
        heat_no
);

-- Primary Keys
ALTER TABLE sel.schedule ADD CONSTRAINT PK_schedule_id PRIMARY KEY (id);
ALTER TABLE sel.matches ADD CONSTRAINT PK_matches_id PRIMARY KEY (match_id);
ALTER TABLE sel.lineup ADD CONSTRAINT PK_lineup_match_lineup PRIMARY KEY (match_id, lineup_id);
ALTER TABLE sel.telemetry ADD CONSTRAINT PK_telemetry_match_rider_heat PRIMARY KEY (match_id, rider_id, heat_id);
CREATE UNIQUE INDEX heat_rider_idx ON sel.heats(heat_id, rider_id);
CREATE UNIQUE INDEX matches_id_idx ON sel.matches(match_id);
CREATE UNIQUE INDEX lineup_id_idx ON sel.lineup(match_id, lineup_id);
CREATE UNIQUE INDEX lineup_match_rider_idx ON sel.lineup(match_id, rider_id);
CREATE UNIQUE INDEX heats_match_rider_idx ON sel.heats(match_id, heat_id, rider_id);


-- Data version table for cache control
CREATE TABLE IF NOT EXISTS sel.data_version (
    version_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO sel.data_version DEFAULT VALUES;
