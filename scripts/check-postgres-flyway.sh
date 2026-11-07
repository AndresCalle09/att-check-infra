
#!/usr/bin/env bash

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-attendance_control}"
DB_USERNAME="${DB_USERNAME:-attendance_user}"

echo "Attendance Control - PostgreSQL and Flyway Check"
echo "------------------------------------------------"
echo "Host: ${DB_HOST}"
echo "Port: ${DB_PORT}"
echo "Database: ${DB_NAME}"
echo "User: ${DB_USERNAME}"
echo

if ! command -v psql >/dev/null 2>&1; then
    echo "ERROR: PostgreSQL client (psql) is required."
    exit 1
fi

export PGHOST="${DB_HOST}"
export PGPORT="${DB_PORT}"
export PGDATABASE="${DB_NAME}"
export PGUSER="${DB_USERNAME}"

if [ -n "${DB_PASSWORD:-}" ]; then
    export PGPASSWORD="${DB_PASSWORD}"
fi

export PGCONNECT_TIMEOUT=5

echo "[1/3] Checking PostgreSQL connectivity..."

if ! psql -X -v ON_ERROR_STOP=1 -Atqc "SELECT 1" \
    | grep -qx "1"; then
    echo "ERROR: PostgreSQL connection failed."
    exit 1
fi

echo "SUCCESS: PostgreSQL is reachable."
echo

echo "[2/3] Checking Flyway schema history..."

HISTORY_TABLE=$(psql -X -v ON_ERROR_STOP=1 -Atqc \
    "SELECT to_regclass('public.flyway_schema_history')")

if [ -z "${HISTORY_TABLE}" ]; then
    echo "WARNING: Flyway schema history was not found."
    echo "Flyway may not be installed or migrations may not have run."
    exit 2
fi

echo "SUCCESS: Flyway schema history exists."
echo

echo "[3/3] Checking migration status..."

FAILED_COUNT=$(psql -X -v ON_ERROR_STOP=1 -Atqc \
    "SELECT COUNT(*) FROM public.flyway_schema_history WHERE success = false")

if [ "${FAILED_COUNT}" -gt 0 ]; then
    echo "ERROR: ${FAILED_COUNT} failed migration(s) detected."
    exit 3
fi

APPLIED_COUNT=$(psql -X -v ON_ERROR_STOP=1 -Atqc \
    "SELECT COUNT(*) FROM public.flyway_schema_history WHERE success = true")

echo "Applied migration records: ${APPLIED_COUNT}"
echo "Failed migrations: 0"
echo

if [ "${APPLIED_COUNT}" -eq 0 ]; then
    echo "WARNING: No successful migration records were found."
    exit 2
fi

echo "SUCCESS: PostgreSQL and Flyway history checks passed."
