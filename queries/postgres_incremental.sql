-- Incremental PostgreSQL sync - only updates changed/deleted data
CREATE SECRET (
    TYPE postgres,
    HOST getenv('POSTGRES_HOST'),
    PORT getenv('POSTGRES_PORT'),
    DATABASE getenv('POSTGRES_DB'),
    USER getenv('POSTGRES_USER'),
    PASSWORD getenv('POSTGRES_PASSWORD')
);

ATTACH '' AS pg (TYPE postgres, SCHEMA 'sel');

BEGIN TRANSACTION;

-- Delete updated/deleted matches and cascading records (telemetry, heats, lineup)
DELETE FROM pg.telemetry 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
    UNION 
    SELECT p.match_id FROM pg.matches p LEFT JOIN sel.matches m ON p.match_id = m.match_id WHERE m.match_id IS NULL
);

DELETE FROM pg.heats 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
    UNION 
    SELECT p.match_id FROM pg.matches p LEFT JOIN sel.matches m ON p.match_id = m.match_id WHERE m.match_id IS NULL
);

DELETE FROM pg.lineup 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
    UNION 
    SELECT p.match_id FROM pg.matches p LEFT JOIN sel.matches m ON p.match_id = m.match_id WHERE m.match_id IS NULL
);

DELETE FROM pg.matches 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
    UNION 
    SELECT p.match_id FROM pg.matches p LEFT JOIN sel.matches m ON p.match_id = m.match_id WHERE m.match_id IS NULL
);

-- Delete updated/deleted schedule records
DELETE FROM pg.schedule 
WHERE id IN (
    SELECT s.id FROM sel.schedule s INNER JOIN pg.schedule p ON s.id = p.id
    UNION 
    SELECT p.id FROM pg.schedule p LEFT JOIN sel.schedule s ON p.id = s.id WHERE s.id IS NULL
);

-- Insert new and updated schedule records
INSERT INTO pg.schedule 
SELECT * FROM sel.schedule 
WHERE id IN (
    SELECT s.id FROM sel.schedule s LEFT JOIN pg.schedule p ON s.id = p.id WHERE p.id IS NULL
    UNION
    SELECT s.id FROM sel.schedule s INNER JOIN pg.schedule p ON s.id = p.id
);

-- Insert new and updated match records
INSERT INTO pg.matches 
SELECT * FROM sel.matches 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m LEFT JOIN pg.matches p ON m.match_id = p.match_id WHERE p.match_id IS NULL
    UNION
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
);

-- Insert lineup for new and updated matches
INSERT INTO pg.lineup 
SELECT * FROM sel.lineup 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m LEFT JOIN pg.matches p ON m.match_id = p.match_id WHERE p.match_id IS NULL
    UNION
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
);

-- Insert heats for new and updated matches
INSERT INTO pg.heats 
SELECT * FROM sel.heats 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m LEFT JOIN pg.matches p ON m.match_id = p.match_id WHERE p.match_id IS NULL
    UNION
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
);

-- Insert telemetry for new and updated matches
INSERT INTO pg.telemetry 
SELECT * FROM sel.telemetry 
WHERE match_id IN (
    SELECT m.match_id FROM sel.matches m LEFT JOIN pg.matches p ON m.match_id = p.match_id WHERE p.match_id IS NULL
    UNION
    SELECT m.match_id FROM sel.matches m INNER JOIN pg.matches p ON m.match_id = p.match_id
);

-- Update pg.stats for new/updated/deleted rows (use Season+Name as key)
-- Delete rows in pg.stats that are updated (exist in both but may have changed)
DELETE FROM pg.stats
WHERE ("Season", "Name") IN (
    SELECT s."Season", s."Name" FROM sel.stats s INNER JOIN pg.stats p ON s."Season" = p."Season" AND s."Name" = p."Name"
    UNION
    SELECT p."Season", p."Name" FROM pg.stats p LEFT JOIN sel.stats s ON p."Season" = s."Season" AND p."Name" = s."Name" WHERE s."Name" IS NULL
);

-- Insert new and updated stats rows from sel.stats
INSERT INTO pg.stats
SELECT * FROM sel.stats s
WHERE (s."Season", s."Name") IN (
    SELECT s2."Season", s2."Name" FROM sel.stats s2 LEFT JOIN pg.stats p2 ON s2."Season" = p2."Season" AND s2."Name" = p2."Name" WHERE p2."Name" IS NULL
    UNION
    SELECT s2."Season", s2."Name" FROM sel.stats s2 INNER JOIN pg.stats p2 ON s2."Season" = p2."Season" AND s2."Name" = p2."Name"
);

-- Update data_version with timestamp
DROP TABLE IF EXISTS pg.data_version;
CREATE TABLE pg.data_version AS 
SELECT 
    CURRENT_TIMESTAMP as last_updated,
    'incremental' as sync_type;

COMMIT;

