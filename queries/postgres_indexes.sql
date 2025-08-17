SET search_path TO sel;

-- Add primary key constraints
ALTER TABLE schedule ADD CONSTRAINT PK_schedule_id PRIMARY KEY (id);
ALTER TABLE matches ADD CONSTRAINT PK_matches_id PRIMARY KEY (match_id);
ALTER TABLE lineup ADD CONSTRAINT PK_lineup_match_lineup PRIMARY KEY (match_id, lineup_id);
ALTER TABLE telemetry ADD CONSTRAINT PK_telemetry_match_rider_heat PRIMARY KEY (match_id, rider_id, heat_id);

-- Create additional unique indexes
CREATE UNIQUE INDEX IF NOT EXISTS heat_rider_idx ON heats(heat_id, rider_id);
CREATE UNIQUE INDEX IF NOT EXISTS matches_id_idx ON matches(match_id);
CREATE UNIQUE INDEX IF NOT EXISTS lineup_id_idx ON lineup(match_id, lineup_id);
CREATE UNIQUE INDEX IF NOT EXISTS lineup_match_rider_idx ON lineup(match_id, rider_id);
CREATE UNIQUE INDEX IF NOT EXISTS heats_match_rider_idx ON heats(match_id, heat_id, rider_id);
