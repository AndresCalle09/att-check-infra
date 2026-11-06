
# Mobile Application — Local Development Setup

## Purpose

This guide explains how to run the Attendance Control mobile application locally and verify connectivity with the Spring Boot API.

The mobile application uses Expo, React Native, and TypeScript.

## Prerequisites

- Node.js and npm
- Java 17
- Git
- The `att-check-app` repository
- The `att-check-api` repository
- A configured backend database

Backend database setup is maintained separately by the infrastructure team.

## 1. Start the Backend

Open a terminal in `att-check-api`.

On macOS, select Java 17 if necessary:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"
```

Verify Java:

```bash
java -version
```

Start the API after the required database and environment configuration are available:

```bash
./mvnw spring-boot:run
```

The development API URL is expected to be:

```text
http://localhost:8080
```

The API requires a working database connection.

## 2. Configure the Mobile Application

Open another terminal in `att-check-app`.

Install dependencies:

```bash
npm install
```

Create a local environment configuration:

```bash
cp .env.example .env.local
```

For development in a desktop browser, configure:

```dotenv
EXPO_PUBLIC_API_URL=http://localhost:8080
```

The `.env.local` file must not be committed to Git.

Do not place JWT signing secrets, database credentials, or passwords in Expo public environment variables.

## 3. Start Expo Web

Run:

```bash
npm run web
```

Open the URL displayed by Expo, typically:

```text
http://localhost:8081
```

The mobile application should display the authentication screen.

## 4. Testing on a Physical Phone

A phone cannot use `localhost` to access an API running on the developer's computer.

The computer and phone should be connected to the same local network.

Find the computer's local IPv4 address and configure `.env.local`:

```dotenv
EXPO_PUBLIC_API_URL=http://YOUR_COMPUTER_LAN_IP:8080
```

Replace `YOUR_COMPUTER_LAN_IP` with the actual address.

Ensure the backend listens on an accessible network interface and that the local firewall permits the connection.

Restart Expo after changing the configuration.

For Android emulators, `10.0.2.2` may be used to access the host computer, depending on the emulator setup.

HTTP is intended for local development only. Production deployments must use HTTPS.

## 5. Check Backend Connectivity

From the `att-check-infra` repository, run:

```bash
bash scripts/check-mobile-backend.sh
```

To check a different API URL:

```bash
bash scripts/check-mobile-backend.sh http://localhost:8080
```

The script sends a request to:

```text
GET /api/users/me
```

Without a JWT, the expected response from the secured API is HTTP 401 Unauthorized.

HTTP 401 confirms that the API is responding and that this endpoint requires authentication.

The script does not verify successful login or database operations.

## 6. Authentication Verification

Once the API and database are running:

1. Register a student using the mobile application.
2. Sign in using the registered credentials.
3. Verify that the login response returns a JWT and the STUDENT role.
4. Open the profile screen.
5. Confirm that the profile endpoint returns the authenticated user's information.
6. Sign out and confirm that protected screens are no longer accessible.
7. Verify professor authentication with a properly provisioned professor account.

Public registration must not allow creating professor accounts.

## 7. Troubleshooting

### Connection refused

The API may not be running, or the configured URL or port may be incorrect.

### HTTP 401 Unauthorized

The endpoint requires valid authentication. This is expected when requesting `/api/users/me` without a token.

### HTTP 403 Forbidden

The request was rejected due to authorization rules. Verify the user's role and endpoint permissions.

### Network request failed

Check the API URL, network connectivity, backend availability, and firewall settings.

For browser requests, also verify that the backend CORS configuration allows the Expo development origin.

### Environment configuration not detected

Verify that `.env.local` is located at the root of `att-check-app`.

Restart Expo after changing environment variables.

## 8. Responsibilities

The application team maintains Expo and authentication UI integration.

The API team maintains authentication endpoints, JWT validation, and authorization rules.

The infrastructure team maintains backend deployment, environment configuration, and database services.

This guide documents local mobile connectivity and does not replace deployment documentation.
