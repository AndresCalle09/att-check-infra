
# PostgreSQL and Flyway Validation

## Purpose

This guide explains how to verify PostgreSQL connectivity and inspect the Flyway migration history for the Attendance Control backend.

The validation script is read-only. It does not create, update, or delete database records.

## Requirements

- PostgreSQL running and accessible
- PostgreSQL command-line client (`psql`)
- Database connection credentials
- Bash (Linux, macOS, WSL, or Git Bash on Windows)

## Database configuration

The backend uses the following environment variables:

| Variable | Default value |
|---|---|
| DB_HOST | localhost |
| DB_PORT | 5432 |
| DB_NAME | attendance_control |
| DB_USERNAME | attendance_user |
| DB_PASSWORD | No default password |

Do not commit real database passwords.

## Running on Linux or macOS

From the repository root:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=attendance_control
export DB_USERNAME=attendance_user
export DB_PASSWORD="your-local-password"

bash scripts/check-postgres-flyway.sh
```

## Running on Windows with PowerShell and WSL

From PowerShell, verify that WSL is available:

```powershell
wsl --status
```

Set the database variables and run the script inside WSL:

```powershell
wsl bash -lc 'cd /mnt/c/path/to/att-check-infra && bash scripts/check-postgres-flyway.sh'
```

Replace the example path with the actual repository location.

Environment variables must be configured inside WSL or passed explicitly. PowerShell environment variables are not automatically available to the WSL shell.

## Running on Windows with Git Bash

Open Git Bash in the repository directory.

Configure the database variables:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=attendance_control
export DB_USERNAME=attendance_user
export DB_PASSWORD="your-local-password"
```

Run:

```bash
bash scripts/check-postgres-flyway.sh
```

## Validation checks

The script verifies:

1. PostgreSQL client availability.
2. Database connectivity using `SELECT 1`.
3. Presence of `public.flyway_schema_history`.
4. Absence of failed migration records.
5. Presence of at least one successful migration record.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | PostgreSQL and Flyway history checks passed |
| 1 | PostgreSQL client or connectivity failure |
| 2 | Migration history missing or empty |
| 3 | Failed migrations detected |

## Important limitations

- The script checks migration history in PostgreSQL.
- It does not compare applied migrations against local SQL files.
- Run Flyway validation through the backend to check migration integrity.
- The script assumes that Flyway uses the `public` schema.
- A successful check does not guarantee that the complete backend is operational.

## Current integration status

The inspected backend configuration uses Hibernate `ddl-auto=update` and does not yet include the Flyway dependency.

Flyway must be integrated into the backend before the migration-history check can pass.

Do not interpret a missing history table as a successful Flyway validation.
