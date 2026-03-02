---
name: mocks
description: Start or stop the WireMock API mock server for UI testing and E2E verification.
user-invocable: true
allowed-tools: "Bash"
argument-hint: "[start|stop]"
---

# WireMock Mock Server

Manage the WireMock mock server that serves API responses for UI tests and E2E verification.

Requires **Java** (`brew install openjdk` if missing).

## Start

```bash
./API-Mocks/scripts/start.sh 8282 &
sleep 3
```

Verify it's running:
```bash
curl -s http://localhost:8282/__admin/ > /dev/null && echo "WireMock running on port 8282" || echo "WireMock failed to start"
```

If Java is not installed, report the prerequisite and stop.

## Stop

```bash
./API-Mocks/scripts/stop.sh 8282
```

Uses WireMock's graceful shutdown endpoint. Falls back to kill-by-port if the shutdown endpoint is unreachable:
```bash
kill $(lsof -ti:8282) 2>/dev/null
```

## Details

- **Port**: 8282 (default)
- **Mappings**: `Modules/Sources/APIMocks/Resources/mappings/`
- **Response files**: `Modules/Sources/APIMocks/Resources/__files/`
- **Start script**: `API-Mocks/scripts/start.sh`
- **WireMock**: auto-downloaded on first run (version configured in `start.sh`)
