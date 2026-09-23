-- ============================================================
-- Create restricted read-only user: ai_agent_ro
-- GaussDB compatibility mode: PG (PostgreSQL)
-- Permissions: SELECT + EXPLAIN only (no DDL/DML)
--
-- Replace :password, :dbname, and :schema with real values.
-- ============================================================

-- Create the user (PostgreSQL-native syntax)
CREATE USER ai_agent_ro WITH PASSWORD ':password';

-- Allow connection to the database
GRANT CONNECT ON DATABASE :dbname TO ai_agent_ro;

-- Grant USAGE on schema (REQUIRED — without it, SELECT grants are useless)
GRANT USAGE ON SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA :schema
    GRANT SELECT ON TABLES TO ai_agent_ro;

-- EXPLAIN: works with just SELECT — no extra privilege needed.
-- EXPLAIN ANALYZE SELECT is also safe for a read-only user.
