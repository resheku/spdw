attach 'sel.db' as sel;

create table matches as(select * from read_json_auto('sel*/matches.jsonl', sample_size=-1, union_by_name=true));

-- schedule
CREATE TABLE
    sel.schedule (
        id INTEGER PRIMARY KEY,
        status_id VARCHAR,
        season INTEGER,
        verified INTEGER,
        name VARCHAR,
        status_name VARCHAR,
        league VARCHAR
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
    match_type->>'$.shortname.en' as league
FROM
    "sel*/*/schedule.jsonl"
order by
    id;


-- matches
CREATE TABLE
    sel.matches (
        match_id BIGINT PRIMARY KEY,
        attendance BIGINT,
        card_type_id BIGINT,
        verified BIGINT,
        season BIGINT,
        has_telemetry BOOLEAN,
        name VARCHAR,
        shortname VARCHAR,
        description VARCHAR,
        datetime VARCHAR,
        datetime_schedule BIGINT,
        round BIGINT,
        status_id BIGINT,
        status_name VARCHAR,
        broadcaster_schedule_id BIGINT,
        broadcaster_schedule_title VARCHAR,
        match_type_id BIGINT,
        match_type_shortname VARCHAR,
        match_type_name VARCHAR,
        team_competition BOOLEAN,
        has_home_away BOOLEAN,
        has_rounds BOOLEAN,
        match_subtype_id BIGINT,
        match_subtype_name VARCHAR,
        match_subtype_shortname VARCHAR,
        postponed VARCHAR,
        postponed_first VARCHAR,
        track_id BIGINT,
        track_city VARCHAR,
        track_fullname VARCHAR,
        track_commissioner_id BIGINT,
        track_commissioner_name VARCHAR,
        track_commissioner_surname VARCHAR,
        referee_id BIGINT,
        referee_name VARCHAR,
        referee_surname VARCHAR,
        home_match_score BIGINT,
        home_match_tlt_score BIGINT,
        home_team_id BIGINT,
        home_team_shortcut VARCHAR,
        home_team_title VARCHAR,
        home_coach_id BIGINT,
        home_coach VARCHAR,
        home_manager_id BIGINT,
        home_manager VARCHAR,
        home_team_manager_id BIGINT,
        home_team_manager VARCHAR,
        away_match_score BIGINT,
        away_match_tlt_score BIGINT,
        away_team_id BIGINT,
        away_team_shortcut VARCHAR,
        away_team_title VARCHAR,
        away_coach_id BIGINT,
        away_coach VARCHAR,
        away_manager_id BIGINT,
        away_manager VARCHAR,
        away_team_manager_id BIGINT,
        away_team_manager VARCHAR
    );

INSERT INTO
    sel.matches (
        match_id,
        attendance,
        card_type_id,
        verified,
        season,
        has_telemetry,
        name,
        shortname,
        description,
        datetime,
        datetime_schedule,
        round,
        status_id,
        status_name,
        broadcaster_schedule_id,
        broadcaster_schedule_title,
        match_type_id,
        match_type_shortname,
        match_type_name,
        team_competition,
        has_home_away,
        has_rounds,
        match_subtype_id,
        match_subtype_name,
        match_subtype_shortname,
        postponed,
        postponed_first,
        track_id,
        track_city,
        track_fullname,
        track_commissioner_id,
        track_commissioner_name,
        track_commissioner_surname,
        referee_id,
        referee_name,
        referee_surname,
        home_match_score,
        home_match_tlt_score,
        home_team_id,
        home_team_shortcut,
        home_team_title,
        home_coach_id,
        home_coach,
        home_manager_id,
        home_manager,
        home_team_manager_id,
        home_team_manager,
        away_match_score,
        away_match_tlt_score,
        away_team_id,
        away_team_shortcut,
        away_team_title,
        away_coach_id,
        away_coach,
        away_manager_id,
        away_manager,
        away_team_manager_id,
        away_team_manager
    )
with
    matches as (
        select distinct
            unnest (match)
        from
            matches
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
    postponed,--no data
    postponed_first,--no data
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
    card_teams->>'$[1].team_manager' as away_team_manager
from
    matches
order by
    match_id;

-- lineups
CREATE TABLE
    sel.lineup (
        match_id BIGINT,
        lineup_id BIGINT,
        protocol_id BIGINT,
        type BIGINT,
        team_id BIGINT,
        team_no BIGINT,
        no BIGINT,
        rider_id BIGINT,
        rider_name VARCHAR,
        rider_surname VARCHAR,
        points BIGINT,
        points_regular BIGINT,
        bonuses BIGINT,
        bonuses_regular BIGINT,
        starts BIGINT,
        starts_regular BIGINT,
        rider_replacement BIGINT,
        warning_heat_order VARCHAR,
        PRIMARY KEY(match_id, lineup_id)
    );

INSERT INTO
    sel.lineup (
        match_id,
        lineup_id,
        protocol_id,
        type,
        team_id,
        team_no,
        no,
        rider_id,
        rider_name,
        rider_surname,
        points,
        points_regular,
        bonuses,
        bonuses_regular,
        starts,
        starts_regular,
        rider_replacement,
        warning_heat_order
    )
with
    lineup as (
        select
            unnest (lineups, recursive := true)
        from
            matches
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
    TRY_CAST(rider_replacement AS BIGINT) as rider_replacement,
    warning_heat_order
from
    lineup
order by
    match_id,
    no;


-- heats
CREATE TABLE
    sel.heats (
        match_id BIGINT,
        heat_id BIGINT,
        canceled INTEGER,
        heat_no BIGINT,
        restart_id BIGINT,
        home_heat_score BIGINT,
        away_heat_score BIGINT,
        home_match_score BIGINT,
        away_match_score BIGINT,
        rider_id BIGINT,
        rider_no BIGINT,
        substitute_id BIGINT,
        substitute_no BIGINT,
        helmet VARCHAR,
        joker INTEGER,
        gate VARCHAR,
        score VARCHAR,
        points INTEGER,
        bonus INTEGER,
        warning BIGINT
    );

INSERT INTO
    sel.heats (
        match_id,
        heat_id,
        canceled,
        heat_no,
        restart_id,
        home_heat_score,
        away_heat_score,
        home_match_score,
        away_match_score,
        rider_id,
        rider_no,
        substitute_id,
        substitute_no,
        helmet,
        joker,
        gate,
        score,
        points,
        bonus,
        warning
    )
with
    heats as (
        select distinct
            match.id as match_id,
            unnest (heats, recursive := true)
        from
            matches
    ),
    results as (
        select
            * exclude (results),
            unnest (results, recursive := true)
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
    substitute_id,
    substitute_no,
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
    warning
from
    results
order by
    match_id,
    heat_no,
    heat_id,
    restart_id,
    gate;
    
-- telemetry
CREATE TABLE
    sel.telemetry (
        match_id BIGINT,
        rider_id BIGINT,
        heat_id BIGINT,
        heat_no BIGINT,
        distance DOUBLE,
        heat_time DOUBLE,
        reaction DOUBLE,
        max_speed DOUBLE,
        l1_time DOUBLE,
        l2_time DOUBLE,
        l3_time DOUBLE,
        l4_time DOUBLE,
        PRIMARY KEY(match_id, rider_id, heat_id)
    );

INSERT INTO
    sel.telemetry (
        match_id,
        rider_id,
        heat_id,
        heat_no,
        distance,
        heat_time,
        reaction,
        max_speed,
        l1_time,
        l2_time,
        l3_time,
        l4_time
    )
with
    telemetry as (
        select
            match.id as match_id,
            unnest(telemetry, recursive := true)
        from
            matches
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
    distance as distance,
    time as heat_time,
    reaction as reaction,
    max_speed as max_speed,
    l1_time as l1_time,
    l2_time as l2_time,
    l3_time as l3_time,
    l4_time as l4_time
from
    details
order by
    match_id,
    heat_no,
    heat_id,
    rider_id;


-- Indexes
CREATE UNIQUE INDEX heat_rider_idx ON sel.heats(heat_id, rider_id);
CREATE UNIQUE INDEX lineup_match_rider_idx ON sel.lineup(match_id, rider_id);
CREATE UNIQUE INDEX heats_match_rider_idx ON sel.heats(match_id, heat_id, rider_id);


-- Data version table for cache control
CREATE TABLE IF NOT EXISTS sel.data_version (
    version_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO sel.data_version DEFAULT VALUES;
