
#!/usr/bin/env bash
set -euo pipefail

# Attendance Control - API Security Smoke Tests

API_URL="${API_URL:-http://localhost:8080}"
API_URL="${API_URL%/}"

PASSED=0
FAILED=0

# --------------------------------------------------
# Requirements and configuration
# --------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required."
    exit 1
fi

if [[ ! "$API_URL" =~ ^https?://[^[:space:]]+$ ]]; then
    echo "ERROR: API_URL must be a valid HTTP or HTTPS URL."
    exit 1
fi

# Prevent accidental use of plain HTTP with remote hosts.
if [[ "$API_URL" == http://* ]]; then
    host="${API_URL#http://}"
    host="${host%%[:/]*}"

    case "$host" in
        localhost|127.0.0.1|::1|\[::1\])
            ;;
        *)
            echo "ERROR: HTTPS is required for non-local API URLs."
            exit 1
            ;;
    esac
fi

# --------------------------------------------------
# Authentication token
# --------------------------------------------------

if [[ -z "${STUDENT_TOKEN:-}" ]]; then
    printf "Enter student JWT: "
    IFS= read -r -s STUDENT_TOKEN
    printf '\n'
fi

if [[ -z "$STUDENT_TOKEN" ]]; then
    echo "ERROR: A student JWT is required."
    exit 1
fi

# Validate the compact JWT structure.
# This prevents special characters from entering
# the curl configuration supplied through stdin.
if [[ ! "$STUDENT_TOKEN" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
    echo "ERROR: Invalid JWT format."
    exit 1
fi

# --------------------------------------------------
# Security helpers
# --------------------------------------------------

check_status() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: $name (HTTP $actual)"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL: $name (expected $expected, got $actual)"
        FAILED=$((FAILED + 1))
    fi
}

request_status() {
    local path="$1"
    local auth_mode="${2:-none}"
    local header_token=""
    local result=""

    case "$auth_mode" in
        student)
            header_token="$STUDENT_TOKEN"
            ;;
        invalid)
            header_token="invalid.jwt.token"
            ;;
        none)
            ;;
        *)
            echo "ERROR: Unsupported authentication mode." >&2
            return 1
            ;;
    esac

    # Pass the Authorization header through stdin,
    # not through curl command-line arguments.
    if [[ -n "$header_token" ]]; then
        if result=$(
            printf 'header = "Authorization: Bearer %s"\n' \
                "$header_token" |
            curl \
                --config - \
                --silent \
                --show-error \
                --connect-timeout 5 \
                --max-time 15 \
                --output /dev/null \
                --write-out "%{http_code}" \
                "$API_URL$path"
        ); then
            printf '%s' "$result"
        else
            return 1
        fi
    else
        if result=$(
            curl \
                --silent \
                --show-error \
                --connect-timeout 5 \
                --max-time 15 \
                --output /dev/null \
                --write-out "%{http_code}" \
                "$API_URL$path"
        ); then
            printf '%s' "$result"
        else
            return 1
        fi
    fi
}

run_check() {
    local name="$1"
    local expected="$2"
    local path="$3"
    local auth_mode="${4:-none}"
    local status=""

    if status=$(request_status "$path" "$auth_mode"); then
        check_status "$name" "$expected" "$status"
    else
        echo "FAIL: $name (request failed)"
        FAILED=$((FAILED + 1))
    fi
}

# --------------------------------------------------
# Security test execution
# --------------------------------------------------

echo "==================================="
echo "Attendance Control - Security Tests"
echo "==================================="
echo "API: $API_URL"
echo

echo "Running security checks..."
echo

# Test 1: A protected endpoint must reject
# requests without an authentication token.
run_check \
    "Protected endpoint without token" \
    "401" \
    "/api/attendance/history" \
    "none"

# Test 2: A protected endpoint must reject
# an invalid authentication token.
run_check \
    "Invalid JWT rejection" \
    "401" \
    "/api/attendance/history" \
    "invalid"

# Test 3: A student must not access
# professor-only resources.
run_check \
    "Student cannot manage courses" \
    "403" \
    "/api/courses" \
    "student"

# Test 4: An authenticated student must
# be able to access their attendance history.
run_check \
    "Student can access attendance history" \
    "200" \
    "/api/attendance/history" \
    "student"

# --------------------------------------------------
# Results
# --------------------------------------------------

echo
echo "==================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "==================================="

# Remove the token from the shell variable
# before the script exits.
unset STUDENT_TOKEN

if [[ "$FAILED" -gt 0 ]]; then
    echo "Security checks completed with failures."
    exit 1
fi

echo "All security checks passed."
exit 0
