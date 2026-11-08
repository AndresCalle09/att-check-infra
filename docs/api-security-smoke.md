
# API Security Smoke Tests

## Purpose

This document describes the security smoke tests for the Attendance Control REST API.

The tests verify authentication and role-based authorization for selected protected endpoints.

## Prerequisites

- A running Spring Boot API
- A configured PostgreSQL development database
- Git Bash
- curl
- A valid JWT issued to a STUDENT account

The default API URL is `http://localhost:8080`.

## Running the Tests

Start the backend from the `att-check-api` repository:

```bash
./mvnw spring-boot:run
```

Make sure the required local environment variables are configured before starting the API.

From the `att-check-infra` repository, execute:

```bash
bash scripts/check-api-security.sh
```

The script prompts for a STUDENT JWT if the `STUDENT_TOKEN` environment variable is not set.

A student account can be registered through:

```text
POST /api/auth/register
```

Use the `token` returned by the authentication response.

Do not commit, print, or share real JWTs, passwords, or signing secrets.

## Security Checks

| Check | Endpoint | Expected HTTP |
|---|---|---|
| Missing JWT | GET /api/attendance/history | 401 |
| Invalid JWT | GET /api/attendance/history | 401 |
| Student accessing professor resources | GET /api/courses | 403 |
| Student accessing own attendance history | GET /api/attendance/history | 200 |

## Local Validation

Validation date: November 8, 2026.

Environment: Local Spring Boot API with a PostgreSQL development database.

Results:

- Missing JWT: PASS (401)
- Invalid JWT: PASS (401)
- Unauthorized student access: PASS (403)
- Authorized student history: PASS (200)

Total: 4 passed, 0 failed.

## Security Considerations

JWT signing secrets and database credentials must remain outside version control.

The script does not include hardcoded credentials or real tokens.

The backend is responsible for validating JWT signatures, token expiration, and user roles.

These checks verify selected authentication and authorization behaviors. They do not constitute a complete security audit.

## Troubleshooting

If the API is unreachable, confirm that Spring Boot is running and that the API URL is correct.

If the authorized student request returns 401, obtain a new JWT from the currently running backend.

If the student request to `/api/courses` does not return 403, review the backend role-based authorization configuration.
