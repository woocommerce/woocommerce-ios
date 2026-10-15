---
name: mocks
description: Start or stop the WireMock API mock server for UI testing and E2E verification.
user-invocable: true
allowed-tools: "Bash"
argument-hint: "[start|stop] [port]"
---

# WireMock Mock Server

Manage the WireMock mock server that serves API responses for UI tests and E2E verification.

Requires **Java** (`brew install openjdk` if missing).

## Start

Check whether the requested port is occupied and which checkout supplies its mappings.
Reuse only a server with the required fixtures. Otherwise start on a free port and record
its port and PID as task-owned resources. Set `<port>` to the selected port; use 8282 when it is free.

```bash
./API-Mocks/scripts/start.sh <port> &
MOCKS_WRAPPER_PID=$!
echo "WireMock wrapper PID: $MOCKS_WRAPPER_PID"
sleep 3
lsof -nP -iTCP:<port> -sTCP:LISTEN
```

Record the Java listener PID shown by `lsof`. Check its parent PID and command with
`ps -p <listener-pid> -o pid,ppid,command` against the wrapper PID and this checkout.
Verify it's running:
```bash
curl --fail --silent http://localhost:<port>/__admin/mappings > /dev/null
```

If Java is not installed, report the prerequisite and stop.

## Stop

Stop only a server this task started. Recheck its recorded listener PID, parent, command, and port
before shutdown; the start wrapper PID is not the Java listener PID.

```bash
./API-Mocks/scripts/stop.sh <port>
```

The stop script requests graceful shutdown. Confirm that the task PID exited and the
port is free. If shutdown fails, terminate only the recorded task-owned PID.
Preserve servers owned by other tasks.

## Details

- **Port**: 8282 (default)
- **Mappings**: `Modules/Sources/APIMocks/Resources/mappings/`
- **Response files**: `Modules/Sources/APIMocks/Resources/__files/`
- **Start script**: `API-Mocks/scripts/start.sh`
- **WireMock**: auto-downloaded on first run (version configured in `start.sh`)
