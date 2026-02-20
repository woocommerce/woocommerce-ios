# WooCommerce iOS

WooCommerce iOS is the official mobile client for WooCommerce stores, developed by Automattic. Large-scale Swift app using MVVM + Coordinators, SwiftUI and UIKit, Combine, and a Flux/Redux-inspired business logic layer (Yosemite).

## Repository Layout

```
WooCommerce.xcworkspace          # Open this to build
WooCommerce/
  Classes/                       # Main app source
    ViewRelated/                 # Views, ViewControllers, SwiftUI views
    ServiceLocator/              # Global dependency provider
    Analytics/                   # WooAnalyticsEvent extensions
    Authentication/              # Login flows
    Model/                       # App-level model types
    Copiable/                    # Generated copy() methods
    Extensions/                  # Swift extensions
    POS/                         # Point of Sale feature
    Notifications/               # Push notifications
  WooCommerceTests/              # Unit tests for main app
    Mocks/                       # Hand-written mock classes

Modules/
  Package.swift                  # SPM package (23+ internal targets, 40+ external deps)
  Sources/
    Yosemite/                    # Business logic (Flux/Redux: Actions, Stores, Dispatcher)
    Networking/                  # REST API layer (Alamofire-based Remotes, Mappers, Models)
    Storage/                     # CoreData persistence (NSManagedObject subclasses, model versions)
    WooFoundation/               # Shared utilities (currency, formatting)
    WooFoundationCore/           # Analytics protocols, WooAnalyticsStat enum
    Hardware/                    # Stripe Terminal card reader integration
    Experiments/                 # Feature flags, A/B testing
    Fakes/                       # Generated .fake() methods (test-only)
    TestKit/                     # XCTest helper extensions (test-only)
    PointOfSale/                 # POS-specific module code
    Codegen/                     # Copiable/Fakeable protocol definitions
  Tests/
    YosemiteTests/
    NetworkingTests/
    StorageTests/
    PointOfSaleTests/
    WooFoundationTests/

BuildTools/                      # SwiftLint + Sourcery SPM plugin package
Rakefile                         # Build automation tasks
fastlane/                        # Deployment automation
docs/                            # Architecture docs, style guides, conventions
RELEASE-NOTES.txt                # Release notes (specific format)
CONTRIBUTING.md                  # PR merge policy
.swiftlint.yml                   # SwiftLint configuration (opt-in rules only)
```

## Bootstrap (Required Once)

Use this to make builds and tests runnable from a clean checkout:

```bash
# Ensure Xcode 14+ is installed and selected.
# Ensure Ruby matches .ruby-version.
bundle install && bundle exec rake dependencies
```

## Build Commands

```bash
# Build
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator build

# Run all unit tests
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator build test

# Run single test class
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"WooCommerceTests/SomeTestClass"

# Run single test method
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"WooCommerceTests/SomeTestClass/test_method_name"

# Run module tests (e.g. Yosemite)
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"YosemiteTests"

# Lint (SwiftLint via BuildTools plugin)
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory swiftlint --working-directory .. --quiet && popd

# Lint with autocorrect
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory swiftlint --working-directory .. --quiet --fix && popd

# Code generation (Sourcery for Copiable/Fakeable)
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory sourcery-command --disableCache && popd
```

If the simulator `iPhone 16` is not available, discover what's installed: `xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5`

## Architecture

```
WooCommerce (UI: ViewControllers, SwiftUI Views, ViewModels, Coordinators)
     |
     +----> PointOfSale (Standalone SwiftUI module, Aggregate Model architecture)
     |
     v
Yosemite (Business Logic: Stores, Actions, Dispatcher)
     |
     +----> Networking (REST API: Remotes, Mappers, Models)
     +----> Storage (CoreData: StorageManager, NSManagedObject subclasses)
```

**Key rule**: The WooCommerce app target ONLY interacts with business logic through Yosemite. Never import Networking or Storage directly from app code (except for existing type aliases).

### Action Dispatch Pattern (Flux/Redux)
```swift
let action = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { result in
    switch result {
    case .success(let product): // handle
    case .failure(let error): // handle
    }
}
ServiceLocator.stores.dispatch(action)
```

### Entity Flow
1. **Networking models**: Immutable `struct`s conforming to `Decodable`
2. **Storage models**: `NSManagedObject` subclasses (mutable, internal to Storage/Yosemite)
3. **Yosemite re-exports** Networking models as read-only types for the UI
4. Use `copy()` (GeneratedCopiable + Sourcery) to create modified copies
5. Use `.fake()` (GeneratedFakeable + Sourcery) to create test data

### Dependency Injection
- Prefer constructor injection over ServiceLocator for new code
- Declare dependencies at the top of each class and inject via init with protocol types
- ServiceLocator acceptable for top-level bootstrapping

### Navigation
- Coordinators manage navigation flow and own child coordinators
- Coordinators should not contain business logic — delegate to ViewModels

### ViewModels
- Prefer `Observation` framework with `@Observable` for new view models
- For existing `ObservableObject` view models, expose state via `@Published` properties or Combine publishers
- Dispatch Yosemite actions and handle results
- Should be testable without UI dependencies
- See `Modules/Tests/CLAUDE.md` for `@Observable` testing patterns using `withObservationTracking`

## Point of Sale (POS) Module

The POS module (`Modules/Sources/PointOfSale/`) is a **self-contained SwiftUI module** with its own architecture, distinct from the main app. It is reachable as a dedicated tab via `POSTabCoordinator`. See `Modules/Sources/PointOfSale/README.md` for full architectural documentation and `.claude/rules/architecture.md` for POS-specific rules.

**Key differences from the main app:**

| Aspect | Main App | PointOfSale Module |
|--------|----------|-------------------|
| Presentation | SwiftUI + UIKit | SwiftUI only |
| State management | Combine + Yosemite Flux/Redux | Aggregate Model + @Observable Controllers |
| Dependency injection | ServiceLocator + constructor injection | `POSDependencyProviding` protocol + `@Environment` |
| Navigation | UIKit Coordinators | SwiftUI state-driven navigation |
| Testing framework | Mixed XCTest / Swift Testing | Primarily Swift Testing |

### POS Build and Test Commands
When working on POS, you can build and test the module in isolation for faster feedback:
```bash
# Build PointOfSale module only
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  build-for-testing -only-testing:"PointOfSaleTests"

# Run POS tests only
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests"

# Run a specific POS test class
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests/SomeTestClass"
```

### POS Source Layout
```
Modules/Sources/PointOfSale/
  Controllers/            # Business logic (order, items, coupons, order list)
  Models/                 # State definitions (aggregate model, payment state, order stage)
  Presentation/           # SwiftUI views organized by feature
  ViewHelpers/            # Stateless view logic extracted for testability
  Protocols/              # Public interfaces (POSDependencyProviding)
  Card Present Payments/  # Stripe Terminal integration
  Analytics/              # POS-specific event tracking
  Utils/                  # Helpers (PreviewHelpers, audio, etc.)
  Resources/              # Assets (images, colors)
Modules/Tests/PointOfSaleTests/  # POS unit tests
WooCommerce/Classes/POS/         # App-target POS integration (POSTabCoordinator, adaptors)
```

## Git Conventions

- **Main branch**: `trunk`
- **Feature branches**: `WOOMOB-XXXX-description` or `issue/XXXX-description`
- **Commit messages**: Capitalized verb + description. Examples:
  - `Add push notification support`
  - `Fix product type filters issue`
  - `Update Stripe SDK to 5.1.1`
  - `Remove redundant MainActor annotation`
- **PR merge policy**: Merge commits (not squash). 1 reviewer required. PR author merges own PR.
- **PR size**: Keep non-test diff under 300 lines (enforced by Danger)
- **Labels and milestones**: Required on non-draft PRs

## Release Notes

Entries in `RELEASE-NOTES.txt` use this format:
```
- [*] Short description of the change [PR_URL]
- [**] Higher priority change [PR_URL]
- [Internal] Internal-only change [PR_URL]
```
Stars indicate priority. `[Internal]` for changes not visible to users.

## Testing

- **Prefer Swift Testing** (`@Test`, `#expect()`) for new test files
- When adding to existing XCTest classes, follow that class's framework
- **Naming**: snake_case — `test_<operation>_when_<condition>_then_<expected_result>()`
- **Structure**: Given / When / Then blocks with comments
- **Mocks**: Hand-written, named `Mock<ServiceName>`, in `Mocks/` subdirectories
- **Test data**: Use `.fake()` from Fakes module and `.copy()` from Copiable
- **Test plan**: `WooCommerce/WooCommerceTests/UnitTests.xctestplan`
- See `Modules/Tests/CLAUDE.md` for detailed async testing patterns
- UI tests require a local mock server: run `rake mocks` and use the `WooCommerceUITests` scheme

## Localization

- Use `NSLocalizedString` with reverse-DNS keys, `value:`, and `comment:` parameters
- **Never** use `LocalizedStringKey` (SwiftLint error)
- **Never** use string interpolation in localized strings (SwiftLint error)
- Use positional placeholders: `%1$@` not `%@`
- Group constants in `enum Localization { }` within the class/struct
- When changing a string value, always update the key too

## Analytics

- Event names: cases in `WooAnalyticsStat` enum (`Modules/Sources/WooFoundationCore/Analytics/WooAnalyticsStat.swift`)
- Events with properties: `WooAnalyticsEvent` static factory methods in `WooCommerce/Classes/Analytics/WooAnalyticsEvent+*.swift`
- Track via injected `analytics: Analytics` (default: `ServiceLocator.analytics`)
- Import with: `import protocol WooFoundation.Analytics`

## SwiftLint

Opt-in only rules configured in `.swiftlint.yml`:
- Line length: 163 max
- control_statement: no parentheses (error)
- vertical_whitespace: max 3 empty lines (error)
- weak_delegate (error)
- Custom rules: no LocalizedStringKey (error), no string interpolation in NSLocalizedString (error), natural alignment for RTL

## Module Dependencies

See `Modules/Package.swift` for the definitive list of supported platforms, internal module targets, and external dependencies. Key architectural constraints:
- WooCommerce app must only import Yosemite for business logic (never Networking or Storage directly)
- Yosemite bridges Networking and Storage
