CREATE SECRET (
    TYPE postgres,
    HOST getenv('POSTGRES_HOST'),
    PORT getenv('POSTGRES_PORT'),
    DATABASE getenv('POSTGRES_DB'),
    USER getenv('POSTGRES_USER'),
    PASSWORD getenv('POSTGRES_PASSWORD')
);


ATTACH '' AS pg (TYPE postgres, SCHEMA 'sel');

-- Start transaction to ensure atomicity
BEGIN TRANSACTION;

-- Create temporary tables with data (no constraints on temp tables)
CREATE TEMP TABLE temp_schedule AS SELECT * FROM sel.schedule;
CREATE TEMP TABLE temp_matches AS SELECT * FROM sel.matches;
CREATE TEMP TABLE temp_lineup AS SELECT * FROM sel.lineup;
CREATE TEMP TABLE temp_heats AS SELECT * FROM sel.heats;
CREATE TEMP TABLE temp_telemetry AS SELECT * FROM sel.telemetry;
CREATE TEMP TABLE temp_stats AS SELECT * FROM sel.stats;
CREATE TEMP TABLE temp_data_version AS SELECT * FROM sel.data_version;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS pg.telemetry;
DROP TABLE IF EXISTS pg.heats;
DROP TABLE IF EXISTS pg.lineup;
DROP TABLE IF EXISTS pg.matches;
DROP TABLE IF EXISTS pg.schedule;
DROP TABLE IF EXISTS pg.stats;
DROP TABLE IF EXISTS pg.data_version;

-- Create new tables from temporary tables
CREATE TABLE pg.schedule AS SELECT * FROM temp_schedule;
CREATE TABLE pg.matches AS SELECT * FROM temp_matches;
CREATE TABLE pg.lineup AS SELECT * FROM temp_lineup;
CREATE TABLE pg.heats AS SELECT * FROM temp_heats;
CREATE TABLE pg.telemetry AS SELECT * FROM temp_telemetry;
CREATE TABLE pg.stats AS SELECT * FROM temp_stats;
CREATE TABLE pg.data_version AS SELECT * FROM temp_data_version;

-- Clean up temporary tables
DROP TABLE temp_telemetry;
DROP TABLE temp_heats;
DROP TABLE temp_lineup;
DROP TABLE temp_matches;
DROP TABLE temp_schedule;
DROP TABLE temp_stats;
DROP TABLE temp_data_version;

-- Commit transaction
COMMIT;