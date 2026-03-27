# Physical Device Setup for mobile-mcp

This guide covers how to set up a physical iOS device for use with mobile-mcp. Three components are needed:

1. **go-ios** — device detection and tunnel
2. **WebDriverAgent (WDA)** — on-device automation server
3. **Port forwarding** — bridges WDA to localhost

## Prerequisites

- Node.js v22+ (see `.nvmrc`)
- Xcode with command line tools
- A physical iOS device connected via USB
- An Apple ID (free or paid) for code signing

## Step 1: Install go-ios

```bash
npm install -g go-ios
```

Verify it detects your device:

```bash
ios list
```

You should see your device UDID in the output.

## Step 2: Start the go-ios tunnel

Required for iOS 17+ devices. Must stay running in the background.

```bash
ios tunnel start --userspace
```

Keep this running in a terminal tab. If it fails with a permission error, try:

```bash
sudo ios tunnel start
```

## Step 3: Install WebDriverAgent on the device

WDA is the on-device server that mobile-mcp uses to interact with the UI (tap, list elements, screenshots, etc.).

### First-time setup

1. Install Appium and the XCUITest driver (which bundles WDA):
   ```bash
   npm install -g appium
   appium driver install xcuitest
   ```

2. Open the WDA Xcode project:
   ```bash
   appium driver run xcuitest open-wda
   ```

3. In Xcode:
   - Select the **WebDriverAgentRunner** scheme
   - Select your physical device as the destination
   - Go to **Signing & Capabilities** on the **WebDriverAgentRunner** target
   - Check "Automatically manage signing"
   - Set **Team** to your Apple ID (personal or organization)
   - If the bundle identifier causes a provisioning error, change it to something unique (e.g. `com.yourname.WebDriverAgentRunner`)
   - If Xcode shows a credential error, go to **Xcode > Settings > Accounts**, remove and re-add your Apple ID

4. On your device, trust the developer certificate:
   **Settings > General > VPN & Device Management** — find your dev certificate and tap Trust

5. Run **Product > Test** (Cmd+U) to build and launch WDA on the device

### Re-launching WDA (after device restart or profile expiry)

Open the WDA project and run Product > Test again:

```bash
appium driver run xcuitest open-wda
```

Then in Xcode: select **WebDriverAgentRunner** scheme, your device, and Cmd+U.

**Note:** Free Apple ID signing profiles expire after 7 days. You will need to rebuild and redeploy WDA when this happens. Paid Apple Developer accounts have longer-lived profiles.

## Step 4: Forward the WDA port

WDA runs on port 8100 on the device. Forward it to localhost so mobile-mcp can connect:

```bash
ios forward 8100 8100 --udid=<YOUR_DEVICE_UDID>
```

Keep this running in a terminal tab.

## Verify everything works

After all steps are running, mobile-mcp should detect the device:

```
mobile_list_available_devices
```

Should show your device with `"type": "real"`.

Test interaction:

```
mobile_list_elements_on_screen (device: "<YOUR_DEVICE_UDID>")
```

Should return UI elements from whatever is on screen.

## Summary: What needs to be running

Three background processes must be active for mobile-mcp to work with a physical device:

| Process | Command | Purpose |
|---------|---------|---------|
| go-ios tunnel | `ios tunnel start --userspace` | Device communication tunnel (iOS 17+) |
| WDA | Xcode > Product > Test | On-device automation server |
| Port forward | `ios forward 8100 8100 --udid=<UDID>` | Bridges WDA to localhost:8100 |

If any of these stop (terminal closed, device restarted, etc.), restart them in order: tunnel first, then WDA, then port forward.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ios list` doesn't show device | Check USB connection. Try a different cable/port. |
| Tunnel fails with "Operation not permitted" | Use `sudo ios tunnel start` instead of `--userspace` |
| WDA signing fails | Change bundle ID to something unique. Re-add Apple ID in Xcode Settings > Accounts. |
| "Did not find test app" from go-ios | WDA isn't installed. Build it from Xcode with Product > Test. |
| Port forward says "address already in use" | A previous forward is still running. Kill it: `lsof -ti:8100 \| xargs kill` |
| `mobile_list_elements_on_screen` fails | Check all three background processes are running. Try `curl http://localhost:8100/status` to verify WDA is reachable. |
| WDA stops working after ~7 days | Free Apple ID provisioning profile expired. Rebuild WDA from Xcode. |
