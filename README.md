# att-check-infra
Infrastructure and orchestration for Attendance Check.

## Run locally with Docker

Requirements: Docker Desktop and Docker Compose.

Clone `att-check-api` next to `att-check-infra`.

1. Copy `.env.example` to `.env` and set local secrets.
2. Run `docker compose config --quiet`.
3. Run `docker compose up -d --build`.
4. Run `docker compose ps`.
5. Check API logs with `docker compose logs --tail=50 api`.

The API is available at http://localhost:8080.
PostgreSQL is exposed locally on port 5433.
Inside Docker, the API connects to database host `db` on port 5432.

The API runs Flyway migrations at startup.

To stop the containers, run `docker compose down`.
Do not use `docker compose down -v` unless you intend to delete local database data.

Never commit `.env` or real credentials.
