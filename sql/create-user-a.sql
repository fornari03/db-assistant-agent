-- ============================================================
-- Create restricted read-only user: ai_agent_ro
-- GaussDB compatibility mode: A (Oracle)
-- Permissions: SELECT + EXPLAIN only (no DDL/DML)
--
-- Replace :password, :dbname, and :schema with real values.
-- ============================================================

-- Create the user (Oracle-compatible syntax)
CREATE USER ai_agent_ro IDENTIFIED BY ':password';

-- Allow connection to the database
GRANT CONNECT ON DATABASE :dbname TO ai_agent_ro;

-- Grant USAGE on schema (REQUIRED — without it, SELECT grants are useless)
GRANT USAGE ON SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA :schema
    GRANT SELECT ON TABLES TO ai_agent_ro;

-- Alternative: SELECT ANY TABLE (database-scoped, not global)
-- GRANT SELECT ANY TABLE TO ai_agent_ro;

-- EXPLAIN: works with just SELECT — no extra privilege needed.
-- Unlike native Oracle, no INSERT on a plan table is required.
