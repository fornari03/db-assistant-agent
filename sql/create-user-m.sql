-- ============================================================
-- Create restricted read-only user: ai_agent_ro
-- GaussDB compatibility mode: M (MySQL enhanced)
-- GaussDB Centralized only
-- Permissions: SELECT + EXPLAIN only (no DDL/DML)
--
-- Replace :password, :dbname, and :schema with real values.
-- ============================================================

-- Create the user (backtick-quoted names supported in M mode)
CREATE USER `ai_agent_ro` IDENTIFIED BY ':password';

-- Allow connection to the database
GRANT CONNECT ON DATABASE :dbname TO ai_agent_ro;

-- Grant USAGE on schema (REQUIRED — without it, SELECT grants are useless)
GRANT USAGE ON SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA :schema
    GRANT SELECT ON TABLES TO ai_agent_ro;

-- ── MySQL-style GRANT (supported in M mode) ──
-- GRANT SELECT ON :dbname.* TO ai_agent_ro;

-- Note: GRANT on functions/procedures/tablespaces is restricted in M mode.
-- Note: ENCRYPTED/UNENCRYPTED password options and RESOURCE POOL are not allowed.
-- Note: CREATE USER auto-creates a schema with the same name as the user.

-- EXPLAIN: works with just SELECT — no extra privilege needed.
