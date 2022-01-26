#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER SYSTEM SET wal_level = logical;
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
EOSQL

pg_ctl reload