---
name: pos-prototype
description: Work with the POS Prototype environment - create scenarios, prototype UI, drive payment states, and iterate with hot-reload
user-invocable: true
allowed-tools: "Bash, Read, Write, Edit, Grep, Glob, Agent"
---

# POS Prototype Environment

A lightweight prototyping app that runs real PointOfSale views with mock services, a scenario picker, and hot-reload for rapid iteration.

## Quick Start

1. Open Xcode via InjectionNext ("Launch Xcode" from menu bar)
2. Open `WooCommerce.xcworkspace` from the worktree
3. Select **POSPrototype** scheme, pick a simulator (iPad or iPhone)
4. Cmd+R to build and run
5. Select a scenario from the picker

## Project Structure

```
POSPrototype/
  Sources/
    App/
      POSPrototypeApp.swift              # @main, registers scenarios
      ScenarioPickerView.swift           # Lists scenarios, launches selected
      PrototypeContainerView.swift       # Wires PointOfSaleEntryPointView with mocks
      PrototypeControlPanel.swift        # Floating control station (FAB -> sheet)
    Core/
      POSPrototypeScenario.swift         # Protocol all scenarios implement
      MockConfiguration.swift            # All mock parameters
      PaymentSequence.swift              # Payment flow state machine
    Mocks/
      StatefulPaymentService.swift       # CardPresentPaymentFacade with manual/auto mode
      StatefulOrderService.swift         # Computes realistic totals from cart
      StatefulItemService.swift          # Returns scenario product catalog
      PrototypeMockControllers.swift     # Fetch strategies, search, barcode
      PrototypeSupportMocks.swift        # Receipt, settings, plugins, refunds, etc.
      PrototypeDependencyProvider.swift  # POSDependencyProviding impl
    Scenarios/
      SmallCafeScenario.swift            # All scenario definitions
      PrototypeCatalog.swift             # Mock product catalogs
```

## Hot-Reload with InjectionNext

### Setup (one-time)
1. Install InjectionNext from the Xcode26.3 branch: `https://github.com/johnno1962/InjectionNext/pull/125`
2. Place in `/Applications/InjectionNext.app`
3. The Inject library is configured to look at InjectionNext's bundle path (set in `POSPrototypeApp.init()`)

### Usage
1. **Quit Xcode** completely
2. Open **InjectionNext.app** (appears in menu bar)
3. Click InjectionNext menu bar icon -> **"Launch Xcode"**
4. Open workspace, select POSPrototype scheme, Cmd+R
5. Console should show: `InjectionNext connected to app, waiting for commands`
6. Edit any .swift file, save (Cmd+S) -> view updates live

### Key nuance: triggering reload from Claude Code
When Claude Code edits files via the Edit tool, Xcode doesn't detect the change. After each edit, run:
```bash
osascript -e 'tell application "Xcode" to activate' -e 'delay 0.1' -e 'tell application "System Events" to keystroke "s" using command down'
```
This simulates Cmd+S in Xcode which triggers InjectionNext's file watcher.

### What can be hot-reloaded (just save)
- View body content (layout, colors, fonts, spacing)
- Computed properties and method bodies
- Animation parameters, text content
- Constants (like card sizes, spacing values)

### What requires rebuild (Cmd+R)
- Adding/removing stored properties (@State, @Binding, @Environment)
- Changing function signatures
- Adding new files
- Changing type definitions (struct/class/enum shape)

### Architecture note
`@ObserveInjection` + `.enableInjection()` is on `PrototypeContainerContent` in the prototype target. This re-renders the entire POS view tree when ANY POS file is injected. No PointOfSale module files need injection annotations.

## Control Station

The blue floating button (bottom-right) opens a control station with three tabs:

### Payment Tab
- **Manual/Auto toggle**: Manual mode pauses at "Validating Order" and waits for you to step through each state. Auto mode runs the scenario's configured sequence.
- **Step buttons**: Validating, Preparing, Tap/Swipe, Inserted, Processing
- **Resolve buttons**: Success (completes payment), Fail (triggers error), Cancel, Reset

### Reader Tab
- Connected (normal battery), Connected (low battery), Disconnected, Disconnecting, Cancelling Connection

### Errors Tab
- Browsable catalog of all real `CardPresentPaymentEventDetails` error cases
- Grouped: Scanning, Connection, Payment, Firmware
- Tap any error to publish it immediately

## Creating a New Scenario

Add a struct conforming to `POSPrototypeScenario` in `POSPrototype/Sources/Scenarios/`:

```swift
import Foundation
import PointOfSale

struct MyScenario: POSPrototypeScenario {
    var id: String { "my-scenario" }
    var name: String { "My Scenario" }
    var description: String { "Description for the picker" }
    var icon: String { "sf.symbol.name" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.smallCafe,  // or custom products
            productLoadDelay: 0.2,
            paymentSequence: .successAfterDelay(1.5),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.92)
            ),
            orderSyncDelay: 0.3,
            taxRate: 0.08,
            storeName: "My Store"
        )
    }
}
```

Then register it in `POSPrototypeApp.swift`:
```swift
private let scenarios: [any POSPrototypeScenario] = [
    SimpleStoreScenario(),
    MyScenario(),  // add here
    ...
]
```

## Creating Custom Product Catalogs

Add to `PrototypeCatalog.swift`:
```swift
static let myProducts: [POSItem] = [
    makeSimple(id: 1, name: "Product Name", price: "9.99"),
    // ...
]
```

## MockConfiguration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| products | [POSItem] | [] | Product catalog for the scenario |
| productLoadDelay | TimeInterval | 0.3 | Delay before products appear |
| paymentSequence | PaymentSequence | .successAfterDelay(2.0) | Auto payment behavior |
| initialReaderConnectionStatus | ...ReaderConnectionStatus | .disconnected | Reader state at launch |
| orderSyncDelay | TimeInterval | 0.5 | Delay for order sync |
| orderSyncShouldFail | Bool | false | Force order sync failure |
| taxRate | Decimal | 0.08 | Tax rate for mock orders |
| storeName | String | "Prototype Store" | Shown in POS header |
| isBookingsEligible | Bool | false | Show bookings tab |

## PaymentSequence Options

- `.successAfterDelay(TimeInterval)` - auto-progress through all steps
- `.failAtStep(PaymentStep, message: String)` - progress then fail at specific step
- `.readerDisconnectsDuring(PaymentStep)` - progress then disconnect
- `.cashOnly` - card payment throws error

## Prototyping New UI

1. Create views in `Modules/Sources/PointOfSale/Presentation/` (they live in the real module)
2. Create a scenario in `POSPrototype/Sources/Scenarios/` that sets up the right state
3. Build and run (Cmd+R)
4. Iterate with hot-reload (edit view, Cmd+S)
5. When done, the views are already in the right place - just wire into real navigation

## Cleanup After Prototyping

Prototype views that don't make the cut should be deleted from `Modules/Sources/PointOfSale/`. The prototype target files (scenarios, mocks) can stay indefinitely - they don't affect the main app.

To revert all prototype experiments:
```bash
git checkout -- Modules/Sources/PointOfSale/
```

## Build Commands

```bash
# Build POSPrototype only (~5s incremental)
xcodebuild -workspace WooCommerce.xcworkspace -scheme POSPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -sdk iphonesimulator build

# Install and launch on simulator
xcrun simctl install <UDID> ~/Library/Developer/Xcode/DerivedData/WooCommerce-*/Build/Products/Debug-iphonesimulator/POSPrototype.app
xcrun simctl launch <UDID> com.automattic.posprototype

# Run POS tests (verify no regressions)
xcodebuild -workspace WooCommerce.xcworkspace -scheme PointOfSale \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -sdk iphonesimulator test
```

## Known Issues

- **AsyncPaginationTracker crash**: Fixed with NSLock in this branch. If you see crashes in `resetInternalState()`, the fix is in `Modules/Sources/Yosemite/Tools/AsyncPaginationTracker.swift`.
- **SVG asset crash**: Intermittent simulator bug in CoreSVG when loading POS vector assets. Not our code - retry or switch simulator runtime.
- **InjectionNext Xcode 26**: Requires the Xcode26.3 branch build of InjectionNext (PR #125). Stock releases don't work with Xcode 26.
