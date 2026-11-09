
# API Security Smoke Tests

## Purpose

This document describes the security smoke tests for the Attendance Control REST API.

The tests verify JWT authentication and role-based authorization for selected protected endpoints.

These checks help confirm that unauthorized requests are rejected and authenticated students can access their permitted resources.

## Prerequisites

- Java 17
- A running Spring Boot API
- A configured PostgreSQL development database
- Bash
- curl
- A valid JWT issued to a STUDENT account

The default API URL is `http://localhost:8080`.

Tests must be performed in a local development or authorized testing environment.

## Running the Tests

### 1. Start the Backend

Open a terminal in the `att-check-api` repository.

Verify the Java version:

```bash
java -version
```

Start the Spring Boot application:

```bash
./mvnw spring-boot:run
```

Ensure PostgreSQL is running and the required environment variables are configured.

### 2. Verify API Connectivity

Execute:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  http://localhost:8080/api/users/me
```

Expected response:

```text
HTTP 401
```

This indicates that the API is reachable and that the profile endpoint requires authentication.

### 3. Obtain a Student JWT

Register or sign in using a development STUDENT account.

Authentication endpoints:

```text
POST /api/auth/register
POST /api/auth/login
```

The authentication response provides a JWT in the `token` field.

Use a temporary development account. Never commit, print, publish, or share real authentication tokens or credentials.

### 4. Execute the Security Script

From the `att-check-infra` repository, execute:

```bash
bash scripts/check-api-security.sh
```

The script requests a student JWT when `STUDENT_TOKEN` is not defined.

The token input is hidden while typing.

## Security Checks

The script performs four security checks.

| Test | Endpoint | Expected HTTP | Purpose |
|---|---|---|---|
| Missing JWT | GET /api/attendance/history | 401 | Reject unauthenticated requests |
| Invalid JWT | GET /api/attendance/history | 401 | Reject invalid authentication tokens |
| Student accessing professor resources | GET /api/courses | 403 | Enforce role-based authorization |
| Student accessing attendance history | GET /api/attendance/history | 200 | Allow authorized access |

## Local Validation

**Validation date:** November 8, 2026.

**Environment:**

- macOS development environment
- Java 17.0.21
- Spring Boot REST API
- PostgreSQL 16 running in Docker
- Local API URL: `http://localhost:8080`

### Test Results

| Security Check | Expected HTTP | Actual HTTP | Status |
|---|---|---|---|
| Missing JWT | 401 | 401 | PASS |
| Invalid JWT | 401 | 401 | PASS |
| Student accessing professor resources | 403 | 403 | PASS |
| Student accessing attendance history | 200 | 200 | PASS |

**Total: 4 passed, 0 failed.**

### Execution Summary

```text
===================================
Attendance Control - Security Tests
===================================
API: http://localhost:8080

Running security checks...

PASS: Protected endpoint without token (HTTP 401)
PASS: Invalid JWT rejection (HTTP 401)
PASS: Student cannot manage courses (HTTP 403)
PASS: Student can access attendance history (HTTP 200)

===================================
Passed: 4
Failed: 0
===================================
All security checks passed.
```

The four security checks completed successfully in the local development environment.

These results confirm only the tested scenarios and do not constitute a complete security audit.

## Security Considerations

### JWT Protection

The backend is responsible for:

- Validating JWT signatures.
- Checking token expiration.
- Verifying user roles.
- Enforcing authorization rules.
- Rejecting unauthorized requests.

### Secure Token Handling

The security script supplies authorization headers to curl through standard input instead of command-line arguments.

This reduces the risk of exposing JWT values through operating system process listings.

The script also:

- Checks the basic compact JWT format.
- Avoids printing authentication tokens.
- Reports HTTP status codes without exposing response bodies.
- Uses connection and request timeouts.
- Reports failed security checks.
- Clears its local token variable after execution.

These measures reduce accidental exposure but do not guarantee complete token secrecy.

### Environment Variables

JWT signing secrets and database credentials must remain outside version control.

Sensitive configuration values include:

- `JWT_SECRET`
- `DB_PASSWORD`
- `STUDENT_TOKEN`

Never place database passwords, JWT signing secrets, or private credentials in Expo public environment variables.

### HTTPS

HTTP is permitted for local development on localhost.

Production deployments must use HTTPS to protect authentication information during transmission.

### Security Testing Limitations

These four smoke tests do not verify every security requirement.

Additional tests should cover:

- Expired JWT rejection.
- JWT signature tampering.
- Unauthorized access to resources owned by other users.
- Session expiration.
- Profile update and account deletion permissions.
- Sensitive information exposure in application logs.

These scenarios require separate validation.

## Troubleshooting

### API Not Reachable

Confirm that Spring Boot is running and that the API URL and port are correct.

### HTTP 401 Unauthorized

Protected endpoints require valid authentication.

If a valid student request returns HTTP 401, obtain a new JWT from the current backend.

### HTTP 403 Forbidden

The authenticated account does not have permission to access the requested resource.

Student accounts must not access professor-only endpoints.

### Database Connection Failure

Verify PostgreSQL availability and database configuration.

Check running containers:

```bash
docker ps
```

### Invalid JWT Format

Ensure that the JWT was copied correctly.

Do not include the `Bearer` prefix when entering the token into the script.

### Unexpected HTTP Status

Review JWT validation, Spring Security configuration, user roles, and endpoint authorization.

Do not disable authentication controls to bypass failed tests.

## Conclusion

The Attendance Control API passed all four documented security smoke tests in the local development environment on November 8, 2026.

The tested endpoints correctly enforced the expected authentication and role-based authorization responses.

Additional security verification is recommended before production deployment.
