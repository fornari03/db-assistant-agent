-- ============================================================
-- Create restricted read-only user: ai_agent_ro
-- For GaussDB / openGauss — works across compatibility modes
-- Permissions: SELECT + EXPLAIN only (no DDL/DML)
--
-- Compatibility modes (set at CREATE DATABASE time, cannot change later):
--   'A'  = Oracle
--   'PG' = PostgreSQL
--   'B'  = MySQL
--   'M'  = MySQL enhanced (GaussDB centralized only)
--
-- Replace :password, :dbname, and :schema with real values.
-- ============================================================


-- ============================================================
-- 0. Check current compatibility mode
-- ============================================================

-- Show the mode for a specific database:
SELECT datname, datcompatibility FROM pg_database WHERE datname = ':dbname';

-- Or show the current session's mode:
SHOW sql_compatibility;


-- ============================================================
-- 1. UNIVERSAL SYNTAX — works in ALL modes (A, B, PG, M)
-- ============================================================
-- Both PASSWORD and IDENTIFIED BY are accepted in every mode.

-- Create the user
CREATE USER ai_agent_ro PASSWORD ':password';
-- Alternative (same result, all modes):
-- CREATE USER ai_agent_ro IDENTIFIED BY ':password';

-- Allow connection to the database
GRANT CONNECT ON DATABASE :dbname TO ai_agent_ro;

-- Grant USAGE on the schema (REQUIRED — without this, SELECT grants
-- let the user see table names but cannot actually query them)
GRANT USAGE ON SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all existing tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA :schema TO ai_agent_ro;

-- Grant SELECT on all FUTURE tables created in the schema
ALTER DEFAULT PRIVILEGES IN SCHEMA :schema
    GRANT SELECT ON TABLES TO ai_agent_ro;

-- EXPLAIN: works with just SELECT — no extra privilege needed in any mode.
-- EXPLAIN ANALYZE SELECT also works (it executes the SELECT, which is safe
-- for a read-only user).


-- ============================================================
-- 2. MODE-SPECIFIC EXTENSIONS (optional)
-- ============================================================

-- ---- 'A' (Oracle) mode ----
-- The universal syntax above works as-is.
-- Oracle-style SELECT ANY TABLE is also available (database-scoped):
-- GRANT SELECT ANY TABLE TO ai_agent_ro;
-- Note: SELECT ANY TABLE only applies to the current database, not all databases.

-- ---- 'PG' (PostgreSQL) mode ----
-- The universal syntax above works as-is.
-- Standard PostgreSQL form with WITH clause also works:
-- CREATE USER ai_agent_ro WITH NOSYSADMIN NOCREATEDB LOGIN PASSWORD ':password';

-- ---- 'B' (MySQL) mode ----
-- The universal syntax above works as-is.
-- MySQL-style user@host syntax is available ONLY if this GUC is enabled:
--   gs_guc reload -Z coordinator -Z datanode -N all -I all \
--     -c "b_compatibility_user_host_auth=on"
-- Then you can use:
-- CREATE USER 'ai_agent_ro'@'%' IDENTIFIED BY ':password';
-- GRANT SELECT ON :dbname.* TO 'ai_agent_ro'@'%';
-- Note: users created with user@host can ONLY connect to B-compatible databases.
-- Note: GRANT does NOT auto-create users (unlike MySQL 5.7) — always CREATE USER first.
-- Note: FLUSH PRIVILEGES does NOT exist in GaussDB — it is not needed.

-- ---- 'M' (MySQL enhanced, GaussDB centralized only) ----
-- Similar to B mode. Backtick-quoted usernames are supported:
-- CREATE USER `ai_agent_ro` IDENTIFIED BY ':password';
-- MySQL-style GRANT ON db.* is supported:
-- GRANT SELECT ON :dbname.* TO ai_agent_ro;
-- Note: GRANT on functions/procedures/tablespaces is restricted in M mode.


-- ============================================================
-- 3. VERIFY
-- ============================================================

-- Check the user was created:
SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'ai_agent_ro';

-- Check granted privileges:
SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'ai_agent_ro';

-- Test read access (run as ai_agent_ro):
-- EXPLAIN SELECT * FROM :schema.some_table;
-- SELECT * FROM :schema.some_table LIMIT 1;


-- ============================================================
-- 4. GOTCHAS
-- ============================================================
-- - USAGE ON SCHEMA is mandatory in all modes — without it, SELECT grants
--   are useless (user sees table names but cannot query them).
-- - Compatibility mode is set ONLY at CREATE DATABASE time and cannot change.
-- - Default mode is 'A' (Oracle) if DBCOMPATIBILITY is not specified.
-- - Password complexity is enforced: >= 8 chars, >= 3 character types,
--   must differ from username.
-- - SELECT ANY TABLE is database-scoped, not global.
-- - EXPLAIN ANALYZE executes the statement — safe for SELECT, but
--   EXPLAIN ANALYZE INSERT/UPDATE/DELETE would fail without DML privileges.
-- - CREATE USER auto-creates a schema with the same name as the user.
