-- Postgres init script for the veil-web-db accessory (docker-entrypoint-initdb.d).
-- Runs ONCE, on a fresh data volume, as POSTGRES_USER (a superuser).
-- The primary database (veil_web_production) is created by POSTGRES_DB itself,
-- so only the Solid Cache / Queue / Cable databases are created here.
-- NOTE: Postgres has no CREATE DATABASE IF NOT EXISTS — plain statements are
-- correct here because init scripts only ever run against an empty cluster.
CREATE DATABASE veil_web_production_cache;
CREATE DATABASE veil_web_production_queue;
CREATE DATABASE veil_web_production_cable;
