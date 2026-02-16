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
- Expose state via `@Published` properties or Combine publishers
- Dispatch Yosemite actions and handle results
- Should be testable without UI dependencies

## Immutability
- Networking/Yosemite model entities are immutable (read-only structs)
- Use `copy()` (GeneratedCopiable + Sourcery) to create modified copies
- Mutable entities exist only in Storage layer

## Code Generation
- `GeneratedCopiable`: conform your struct/class, then run codegen to get `copy()` methods
- `GeneratedFakeable`: conform then run codegen to get `.fake()` test factory methods
- Run codegen: `pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && swift package plugin --allow-writing-to-directory .. --allow-writing-to-package-directory sourcery-command --disableCache && popd`
