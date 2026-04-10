# Woo Point of Sale

This folder contains the Woo Point of Sale (POS). This is a development feature.

## Architecture

The POS uses an Aggregate Model architecture, also known as Model View. 

Initially, we used MVVM, so you will find leftovers of that in some leaf nodes and smaller views, such as the payment messages, modals, and errors.

New code should follow our Aggregate Model architecture. Some principles in brief:

- State should have a single source of truth.
- The minimum possible state for the view to do its work should be exposed.
- The `PointOfSaleAggregateModel` coordinates globally shared state.
- Each `View` is considered to be a view model, and can hold local state.
- Each `Controller` handles a piece of globally shared state, often using `Services`.
- `Services` exist to provide a stateless interface to external resources.

### Architectural Elements

#### Aggregate Model

From the `View` perspective, shared state is provided by the aggregate model. It's injected into the views using `@EnvironmentObject`.

The aggregate model minimises dependencies between state, by using themed `Controller` classes to manage the state.

The controllers also help to keep the aggregate model lean.

The state it exposes should be really minimal. 

For example, the TotalsView only needs three strings from the order, the cart total, tax total, and order total. We expose those only when they're needed (i.e., when the order is loaded), and we don't expose the underlying order. See `PointOfSaleOrderState`, exposed as `orderState` on the aggregate model for the example. 

#### View(Model)s

SwiftUI `View` can be considered a view model, because it can hold state and translate that to and from the view. It just happens to also have a definition of the view in its body property.

Add `@State` accordingly, when it isn't shared, and consider `Binding` when it is. If it's globally shared, then the aggregate model is your friend.

View logic can be extracted to a `ViewHelper`, to make it easier to unit test, where that's needed. These helpers should always be stateless, and have any data they need passed in when called, to avoid having more than one source of truth. This is usually the appropriate choice if more than one state item is needed to decide something, especially if one or both are local view state.

Consider making helper functions static; we've not done this yet in case they need to be mocked in future when testing the Views, but that may be a dead end.

As an alternative to a helper, if only one state item is involved, consider defining a private extension on the model class which provides a convenient interface from the view.

If a leaf node view only depends on a small part of the aggregate model to do its work, and it's convenient to do so, consider passing the required state or using a binding, rather than accessing the environment object on that view. When you do this, the resulting view is easier to reason about and reuse, as it can access less of the shared state.

#### Controllers

Each `Controller` handles a piece of global shared state, and provides the interface for interacting with it. 

Often, the best way to do that is to expose a single enum covering all valid possibilities for that state, rather than exposing model objects. We've not achieved that in all the controllers yet, and some global state hasn't been encapsulated in a controller successfully yet, for example card payments.

#### Services

Ideally each `Service` should be stateless, and owned by a controller which handles the state in between service calls, where needed.

Services are for interacting with the network, hardware, and in future, storage. In practice, they often wrap Yosemite actions and stores in an async interface. Sometimes, they adapt existing code from the main app target to simplify its use in POS.

## Future Goal - Observation

We intend to move to the `Observation` framework, rather than using `@Published` and `ObservableObject` on the aggregate model.

To support this, try to avoid adding subscriptions to the aggregate model's published properties. Often it's sufficient to just use a computed var. 

When any published property changes, any view which has an `@EnvironmentObject` var for the aggregate model will be redrawn anyway – this is part of the reason for moving to observation! 


## PointOfSale Module

The `PointOfSale` module contains all POS-specific functionality, extracted from the main Woo app target. It was introduced to improve compilation and preview speed, simplify testing, and support future architectural flexibility.

### Purpose

The module enables POS to evolve as an independent feature area, while maintaining integration with the main app through a controlled set of interfaces.
This approach improves development speed and test isolation, while keeping the codebase aligned with the Woo app’s shared architecture.

### Structure

The `PointOfSale` module depends on shared internal modules (e.g. `WooFoundation`, `Yosemite`) and on adaptor protocols that are injected from the main app.

* **`PointOfSaleEntryPointView`** — The main POS entry point, exposed publicly to the main app target.
* **`POSDependencyProviding`** — The protocol defining all dependencies injected from the main app (e.g. analytics, feature flags, navigation).
* **`POSTabCoordinator`** — Acts as a factory of PointOfSaleEntryPointView and injects the main app target dependencies.
* **Adaptors Layer** — Implementations of the dependency protocols, located in the Woo app target, bridging POS to main app functionality.
* **Environment Integration** — Dependencies are injected through environment values, providing access in SwiftUI views without using singletons directly.

### Dependency Injection

Direct access to the `ServiceLocator` was removed in favor of dependency injection at module entry.
Services such as analytics, currency, and connectivity are now provided via environment wrappers:

```swift
@Environment(.posAnalytics) private var analytics

analytics.track(.pointOfSaleItemsFetched)
```

This approach removes tight coupling with the main app and enables testing POS in isolation.

### External Integrations

For complex or tightly coupled components — such as support forms, navigation, or payment flows — POS uses type-erased adaptors.
These expose necessary Woo app functionality while keeping dependencies transparent and replaceable:

```swift
@Environment(.posExternalViews) private var externalViews

externalViews.createSupportFormView(isPresented: $showSupport)
```

Navigation back to the main app follows the same pattern:

```swift
@Environment(.posExternalNavigation) private var navigation
navigation.navigateToCreateOrder()
```

### Migration Strategy

The modularization was completed incrementally:

1. Define an empty `PointOfSale` module and test target.
2. Abstract direct `ServiceLocator` usages behind dependency protocols.
3. Move shared utilities to `WooFoundation` or `Yosemite`, refactor and split some dependencies if needed.
4. Move POS-specific files into the new module.
5. Expose only the entry point and dependency protocols publicly.
