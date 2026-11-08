
#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:8080}"
API_URL="${API_URL%/}"

PASSED=0
FAILED=0

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
    curl --silent --show-error \
        --connect-timeout 5 \
        --max-time 15 \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$@"
}

echo "==================================="
echo "Attendance Control - Security Tests"
echo "==================================="
echo "API: $API_URL"
echo

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required."
    exit 1
fi

if [[ -z "${STUDENT_TOKEN:-}" ]]; then
    read -r -s -p "Enter student JWT: " STUDENT_TOKEN
    echo
fi

if [[ -z "$STUDENT_TOKEN" ]]; then
    echo "ERROR: A student JWT is required."
    exit 1
fi

echo "Running security checks..."
echo

# Test 1: Protected endpoint without a JWT.
status=$(request_status \
    "$API_URL/api/attendance/history")

check_status \
    "Protected endpoint without token" \
    "401" \
    "$status"

# Test 2: Protected endpoint with an invalid JWT.
status=$(request_status \
    -H "Authorization: Bearer invalid.jwt.token" \
    "$API_URL/api/attendance/history")

check_status \
    "Invalid JWT rejection" \
    "401" \
    "$status"

# Test 3: Student accessing a professor-only endpoint.
status=$(request_status \
    -H "Authorization: Bearer $STUDENT_TOKEN" \
    "$API_URL/api/courses")

check_status \
    "Student cannot manage courses" \
    "403" \
    "$status"

# Test 4: Student accessing their own attendance history.
status=$(request_status \
    -H "Authorization: Bearer $STUDENT_TOKEN" \
    "$API_URL/api/attendance/history")

check_status \
    "Student can access attendance history" \
    "200" \
    "$status"

echo
echo "==================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "==================================="

if [[ "$FAILED" -gt 0 ]]; then
    exit 1
fi

echo "All security checks passed."
