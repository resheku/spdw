attach 'sel.db' as sel;

create table _matches as(select * from read_json_auto('sel*/matches.jsonl', sample_size=-1, union_by_name=true));

-- schedule
CREATE TABLE
    sel.schedule (
        id INTEGER PRIMARY KEY,
        status_id TEXT,
        season INT,
        verified INT,
        name TEXT,
        status_name TEXT,
        league TEXT
    );

INSERT INTO
    sel.schedule (
        id,
        status_id,
        season,
        verified,
        name,
        status_name,
        league
    )
select distinct
    id,
    status_id,
    season,
    verified,
    name->>'$.en' as name,
    status->>'$.name.en' as status_name,
    match_type->>'$.name.en' as league
FROM
    "sel*/*/schedule.jsonl"
order by
    id;


-- matches
create table
    sel.matches as (
        with
            matches as (
                select distinct
                    unnest (match)
                from
                    _matches
            )
        select distinct
            id as match_id,
            attendance,
            card_type_id,
            verified,
            season,
            has_telemetry,
            name->>'$.en' as name,
            shortname->>'$.en' as shortname,
            description->>'$.en' as description,
            strftime (
                timezone (
                    'Europe/Warsaw',
                    to_timestamp (datetime_schedule / 1000)
                ),
                '%Y-%m-%d %H:%M'
            ) AS datetime,
            datetime_schedule,
            round,
            status->>'$.id' as status_id,
            status->>'$.name.en' as status_name,
            broadcaster_schedule->>'$.id' as broadcaster_schedule_id,
            broadcaster_schedule->>'$.title' as broadcaster_schedule_title,
            match_type->>'$.id' as match_type_id,
            match_type->>'$.shortname.en' as match_type_shortname,
            match_type->>'$.name.en' as match_type_name,
            match_type->>'$.team_competition' as team_competition,
            match_type->>'$.has_home_away' as has_home_away,
            match_type->>'$.has_rounds' as has_rounds,
            match_subtype->>'$.id' as match_subtype_id,
            match_subtype->>'$.name.en' as match_subtype_name,
            match_subtype->>'$.shortname.en' as match_subtype_shortname,
            postponed,
            postponed_first,
            track->>'$.id' as track_id,
            track->>'$.city' as track_city,
            track->>'$.fullname' as track_fullname,
            track_commissioner->>'$.id' as track_commissioner_id,
            track_commissioner->>'$.name' as track_commissioner_name,
            track_commissioner->>'$.surname' as track_commissioner_surname,
            referee->>'$.id' as referee_id,
            referee->>'$.name' as referee_name,
            referee->>'$.surname' as referee_surname,
            card_teams->>'$[0].match_score' as home_match_score,
            card_teams->>'$[0].match_tlt_score' as home_match_tlt_score,
            card_teams->>'$[0].team_id' as home_team_id,
            card_teams->>'$[0].team_shortcut' as home_team_shortcut,
            card_teams->>'$[0].team_title' as home_team_title,
            card_teams->>'$[0].coach_id' as home_coach_id,
            card_teams->>'$[0].coach' as home_coach,
            card_teams->>'$[0].manager_id' as home_manager_id,
            card_teams->>'$[0].manager' as home_manager,
            card_teams->>'$[0].team_manager_id' as home_team_manager_id,
            card_teams->>'$[0].team_manager' as home_team_manager,
            card_teams->>'$[1].match_score' as away_match_score,
            card_teams->>'$[1].match_tlt_score' as away_match_tlt_score,
            card_teams->>'$[1].team_id' as away_team_id,
            card_teams->>'$[1].team_shortcut' as away_team_shortcut,
            card_teams->>'$[1].team_title' as away_team_title,
            card_teams->>'$[1].coach_id' as away_coach_id,
            card_teams->>'$[1].coach' as away_coach,
            card_teams->>'$[1].manager_id' as away_manager_id,
            card_teams->>'$[1].manager' as away_manager,
            card_teams->>'$[1].team_manager_id' as away_team_manager_id,
            card_teams->>'$[1].team_manager' as away_team_manager,
        from
            matches
        order by
            match_id
    );

-- -- lineups
create table
    sel.lineup as (
        with
            lineup as (
                select
                    unnest (lineups, recursive := true)
                from
                    _matches
            )
        select distinct
            card_id as match_id,
            id as lineup_id,
            protocol_id,
            type,
            team_id,
            team_no,
            no,
            id_1 as rider_id,
            name as rider_name,
            surname as rider_surname,
            points,
            points_regular,
            bonuses,
            bonuses_regular,
            starts,
            starts_regular,
            CAST(rider_replacement AS BIGINT) as rider_replacement,
            warning_heat_order,
        from
            lineup
        order by
            match_id,
            no
    );


-- -- create heats table
create table
    sel.heats as (
        with
            heats as (
                select distinct
                    match.id as match_id,
                    unnest (heats, recursive := true)
                from
                    _matches
            ),
            results as (
                select
                    * exclude (results),
                    unnest (results, recursive := true),
                from
                    heats
            )
        select
            match_id,
            heat_id,
            canceled,
            no as heat_no,
            restart_id,
            home_heat_score,
            away_heat_score,
            home_match_score,
            away_match_score,
            rider_id,
            rider_no,
            -- name as rider_name,
            -- surname as rider_surname,
            substitute_id,
            substitute_no,
            -- name_3 as substitute_name,
            -- surname_4 as substitute_surname,
            helmet,
            joker,
            gate,
            score,
            case
                when score ~ '^[0-9]+$' then case
                    when joker::int = 1 then (score::double / 2)::int
                    else score::int
                end
                else 0
            end as points,
            bonus,
            warning,
        from
            results
        order by
            match_id,
            heat_no,
            heat_id,
            restart_id,
            gate
    );
    
-- -- telemetry
create table sel.telemetry as (
    with
        telemetry as (
            select
                match.id as match_id,
                unnest(telemetry, recursive := true),
            from
                _matches
        ),
        details as (
            select
                * exclude (details),
                unnest(details, recursive := true)
            from
                telemetry
        )
    select distinct
        match_id,
        rider_id,
        heat_id,
        heat_no,
        distance::double as distance,
        time::double as heat_time,
        reaction::double as reaction,
        max_speed::double as max_speed,
        l1_time::double as l1_time,
        l2_time::double as l2_time,
        l3_time::double as l3_time,
        l4_time::double as l4_time
    from
        details
    order by
        match_id,
        heat_no,
        heat_id,
        rider_id
);


-- Primary Keys
ALTER TABLE sel.matches ADD CONSTRAINT PK_matches_id PRIMARY KEY (match_id);
ALTER TABLE sel.lineup ADD CONSTRAINT PK_lineup_match_lineup PRIMARY KEY (match_id, lineup_id);
ALTER TABLE sel.telemetry ADD CONSTRAINT PK_telemetry_match_rider_heat PRIMARY KEY (match_id, rider_id, heat_id);
CREATE UNIQUE INDEX heat_rider_idx ON sel.heats(heat_id, rider_id);
CREATE UNIQUE INDEX lineup_match_rider_idx ON sel.lineup(match_id, rider_id);
CREATE UNIQUE INDEX heats_match_rider_idx ON sel.heats(match_id, heat_id, rider_id);


-- Data version table for cache control
-- CREATE TABLE IF NOT EXISTS sel.data_version (
--     version_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
-- INSERT INTO sel.data_version DEFAULT VALUES;
