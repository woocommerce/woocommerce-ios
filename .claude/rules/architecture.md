# Architecture Rules

## Layer Boundaries
- **WooCommerce** (UI) ONLY interacts with business logic through **Yosemite**
- **Yosemite** interacts with **Networking** and **Storage**. It is the ONLY layer that can mutate Storage entities
- **Networking** models are immutable structs re-exported as Yosemite types
- The main app must NEVER import Networking or Storage directly (except for existing type aliases)

## Action Dispatch Pattern
Create an Action enum case with required parameters and a completion closure. Dispatch via `ServiceLocator.stores.dispatch(action)`. Stores process actions and call the completion handler with `Result<T, Error>`.

```swift
let action = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { result in
    switch result {
    case .success(let product): // handle
    case .failure(let error): // handle
    }
}
ServiceLocator.stores.dispatch(action)
```

## Adding a New Feature
1. If new API endpoint: add Remote method in `Modules/Sources/Networking/Remote/`
2. If new action: add case to the relevant Action enum in `Modules/Sources/Yosemite/Actions/`
3. Handle the action in the corresponding Store in `Modules/Sources/Yosemite/Stores/`
4. If new model: add to Networking (struct), Storage (NSManagedObject), and mapping between them
5. If new UI: create ViewModel + View in `WooCommerce/Classes/ViewRelated/`
6. If new navigation: use or extend a Coordinator

## Dependency Injection
- Prefer constructor injection over ServiceLocator for new code
- Declare dependencies at the top of each class and inject via init with protocol types
- ServiceLocator is acceptable for top-level bootstrapping only

## Coordinators
- Manage navigation flow and own child coordinators
- Should not contain business logic — delegate to ViewModels

## ViewModels
- Prefer `Observation` framework with `@Observable` for new view models
- For existing `ObservableObject` view models, expose state via `@Published` properties or Combine publishers
- Dispatch Yosemite actions and handle results
- Should be testable without UI dependencies
- See `Modules/Tests/CLAUDE.md` for `@Observable` testing patterns using `withObservationTracking`

## Immutability
- Networking/Yosemite model entities are immutable (read-only structs)
- Use `copy()` (GeneratedCopiable + Sourcery) to create modified copies
- Mutable entities exist only in Storage layer

## Code Generation
- `GeneratedCopiable`: conform your struct/class, then run codegen to get `copy()` methods
- `GeneratedFakeable`: conform then run codegen to get `.fake()` test factory methods
- Run codegen: `pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && swift package plugin --allow-writing-to-directory .. --allow-writing-to-package-directory sourcery-command --disableCache && popd`

---

## Point of Sale (POS) Module

The POS module (`Modules/Sources/PointOfSale/`) uses a **different architecture** from the main app. See `Modules/Sources/PointOfSale/README.md` for full architectural details and `AGENTS.md` for build/test commands and source layout.

**Do not apply main app patterns to POS code or vice versa.** POS uses Aggregate Model (not Flux/Redux), SwiftUI-only (not UIKit), and `@Environment` injection (not ServiceLocator).

### Key Rules
- **`PointOfSaleAggregateModel`** is the single coordinator of globally shared POS state
- **Controllers** manage domain-specific shared state using Services - they are NOT ViewModels
- **Services** are stateless wrappers around Yosemite/external resources
- **Views** act as their own view models (`@State` for local, `@Environment` for shared state)
- **ViewHelpers** must be stateless - pass data in, never store it
- For leaf views, prefer passing required state directly rather than accessing the full aggregate model
- Expose state as enums covering all valid possibilities rather than raw model objects
- POS does NOT use `ServiceLocator` - dependencies come through `POSDependencyProviding` + `@Environment`
- Use POS design tokens for UI: `POSPadding`, `POSSpacing`, `POSFontStyle`, and `Color+POSColorPalette` - no hardcoded values

### POS Design System
POS has its own design tokens. When building POS UI, use these instead of app-wide or hardcoded values:
- **`POSPadding`** - padding constants (`.xSmall` through `.xxLarge`)
- **`POSSpacing`** - spacing constants (`.xSmall` through `.xxLarge`)
- **`POSFontStyle`** - typography (`.posHeadingBold`, `.posBodyLargeRegular()`, etc.) applied via `.font(.posBodyMediumBold)`
- **`Color+POSColorPalette`** - semantic colors (`.posPrimary`, `.posSurface`, `.posError`, etc.) defined in `Colors/Color+POSColorPalette.swift`

Do not use hardcoded spacing/padding values or system fonts directly in POS views.

### POS Dependency Injection
POS does NOT use `ServiceLocator`. Dependencies are injected at module entry via `POSDependencyProviding` and accessed through SwiftUI environment values:
```swift
@Environment(\.posAnalytics) private var analytics
@Environment(\.posExternalNavigation) private var navigation
```

### SwiftUI Previews
POS is an **iPad-first** interface using `horizontalSizeClass` for layout adaptation. When creating POS views:
- Always add `#Preview` blocks to verify iPad layout
- Use `POSPreviewHelpers.makePreviewAggregateModel(...)` from `Utils/PreviewHelpers.swift` to set up preview state
- Preview helpers include mock implementations for all controller and service protocols (guarded with `#if DEBUG`)

```swift
#Preview("Card Reader Connected") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}
```

### Card Present Payments Flow

Card payments in POS flow through several layers using a facade pattern and Combine publishers.

**Architecture layers:**
```
Views (observe POSPaymentModel state)
  ↓
POSPaymentModel (@Observable controller - owns payment state + logic)
  ↓
CardPresentPaymentFacade (protocol in PointOfSale module)
  ↓
CardPresentPaymentService (concrete impl in WooCommerce/Classes/POS/Adaptors/)
  ↓
CardPresentPaymentAction (Yosemite action dispatch)
  ↓
Hardware module (Stripe Terminal SDK integration)
```

**Key types:**

- **`CardPresentPaymentFacade`** (`Card Present Payments/CardPresentPaymentFacade.swift`) - protocol defining the payment interface. Exposes three long-lived Combine publishers (`paymentEventPublisher`, `readerConnectionStatusPublisher`, `cardReaderUpdateStatePublisher`) and async methods (`connectReader`, `collectPayment`, `cancelPayment`, `disconnectReader`)
- **`CardPresentPaymentService`** (`WooCommerce/Classes/POS/Adaptors/Card Present Payments/`) - concrete implementation in the app target. Dispatches `CardPresentPaymentAction` to Yosemite stores and bridges to the app target's `CollectOrderPaymentUseCase` via `CardPresentPaymentCollectOrderPaymentUseCaseAdaptor`
- **`POSPaymentModel`** (`Controllers/POSPaymentModel.swift`) - `@Observable` `@MainActor` controller that owns all payment state. Subscribes to facade publishers and maps `CardPresentPaymentEvent` stream into UI-consumable state
- **`PointOfSalePaymentState`** (`Models/PointOfSalePaymentState.swift`) - top-level state containing `card` (`PointOfSaleCardPaymentState`) and `cash` (`PointOfSaleCashPaymentState`) sub-states

**Card payment state flow:**
```
idle -> validatingOrder -> preparingReader -> acceptingCard -> cardInserted -> processingPayment -> cardPaymentSuccessful
                ↘ validatingOrderError     ↘ paymentIntentCreationError      ↘ paymentError
```

**Event-driven communication:**
1. `CardPresentPaymentService` publishes `CardPresentPaymentEvent` values (idle, show(eventDetails), showOnboarding)
2. `CardPresentPaymentEventDetails` cases cover reader scanning, connection, payment processing, results, and firmware updates
3. `POSPaymentModel` subscribes with two scopes:
   - **Always-on** (`cancellables`): reader connection status, update state, onboarding, alerts
   - **Session-scoped** (`paymentSessionCancellables`): payment state, inline messages - prevents cross-flow contamination between payments

**Order provision pattern:**
- `POSPaymentOrderProviding` protocol abstracts where the order comes from
- `POSCartPaymentOrderProvider` - provides order from cart controller
- `POSBookingPaymentOrderProvider` - provides order from booking controller
- This allows the same `POSPaymentModel` to serve both cart and bookings flows via different configurations (`POSPaymentFlowConfiguration`)

**Cash payments** follow a simpler path via `POSCashPaymentHandling` protocol with cart/booking implementations that mark orders as paid without hardware interaction.

### Adding a New POS Feature
1. If new shared state: add a Controller in `Controllers/`, wire it into `PointOfSaleAggregateModel`
2. If new Yosemite interaction: add a Service that wraps Yosemite actions in an async interface
3. If new UI: add SwiftUI views in `Presentation/`, include `#Preview` blocks using `POSPreviewHelpers`
4. If external dependency needed: extend `POSDependencyProviding` and add adaptor in `WooCommerce/Classes/POS/`
5. Tests go in `Modules/Tests/PointOfSaleTests/`
