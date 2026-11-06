
#!/usr/bin/env bash

set -eu

API_URL="${1:-${EXPO_PUBLIC_API_URL:-http://localhost:8080}}"
API_URL="${API_URL%/}"

ENDPOINT="${API_URL}/api/users/me"

echo "Attendance Control — API Connectivity Check"
echo "Checking: ${ENDPOINT}"
echo

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required."
    exit 1
fi

if ! HTTP_CODE=$(curl \
    --silent \
    --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    --connect-timeout 3 \
    --max-time 8 \
    "$ENDPOINT"); then
    echo
    echo "ERROR: Could not connect to the backend."
    echo "Check whether Spring Boot is running and the API URL is correct."
    exit 1
fi

echo "HTTP status: ${HTTP_CODE}"

case "$HTTP_CODE" in
    401)
        echo "SUCCESS: API is reachable."
        echo "The protected profile endpoint requires authentication."
        exit 0
        ;;
    200)
        echo "WARNING: API is reachable, but the profile endpoint"
        echo "returned 200 without a JWT. Review endpoint security."
        exit 2
        ;;
    403)
        echo "WARNING: API is reachable but returned 403."
        echo "Verify the expected authentication behavior."
        exit 2
        ;;
    404)
        echo "ERROR: Profile endpoint not found."
        echo "Verify the API URL and endpoint path."
        exit 2
        ;;
    *)
        echo "ERROR: Unexpected HTTP response: ${HTTP_CODE}"
        echo "Review backend logs and configuration."
        exit 2
        ;;
esac
