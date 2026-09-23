-- ============================================================
-- Create restricted read-only user: ai_agent_ro
-- GaussDB compatibility mode: B (MySQL)
-- Permissions: SELECT + EXPLAIN only (no DDL/DML)
--
-- Replace :password, :dbname, and :schema with real values.
-- ============================================================

-- Create the user (base syntax — works without extra GUC settings)
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

-- ── MySQL-style extensions (optional) ──
-- Requires GUC: b_compatibility_user_host_auth = on
--   gs_guc reload -Z coordinator -Z datanode -N all -I all \
--     -c "b_compatibility_user_host_auth=on"
--
-- MySQL-style user@host creation:
-- CREATE USER 'ai_agent_ro'@'%' IDENTIFIED BY ':password';
--
-- MySQL-style GRANT:
-- GRANT SELECT ON :dbname.* TO 'ai_agent_ro'@'%';
--
-- Note: users created with user@host can ONLY connect to B-compatible databases.
-- Note: GRANT does NOT auto-create users (unlike MySQL 5.7).
-- Note: FLUSH PRIVILEGES does NOT exist in GaussDB — not needed.

-- EXPLAIN: works with just SELECT — no extra privilege needed.
