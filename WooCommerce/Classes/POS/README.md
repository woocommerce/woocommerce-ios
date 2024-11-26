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

### Architectural elements

#### Aggregate model

From the `View` perspective, shared state is provided by the aggregate model.

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

#### Controllers

Each `Controller` handles a piece of global shared state, and provides the interface for interacting with it. 

Often, the best way to do that is to expose a single enum covering all valid possibilities for that state, rather than exposing model objects. We've not achieved that in all the controllers yet, and some global state hasn't been encapsulated in a controller successfully yet, for example card payments.

#### Services

Ideally each `Service` should be stateless, and owned by a controller which handles the state in between service calls, where needed.

Services are for interacting with the network, hardware, and in future, storage. In practice, they often wrap Yosemite actions and stores in an async interface. Sometimes, they adapt existing code from the main app target to simplify its use in POS.

## Future goal - Observation

We intend to move to the `Observation` framework, rather than using `@Published` and `ObservableObject` on the Aggregate model.

To support this, try to avoid adding subscriptions to the aggregate model's published properties. Often it's sufficient to just use a computed var. 

When any published property changes, any view which has an `@EnviromentObject` var for the aggregate model will be redrawn anyway – this is part of the reason for moving to observation! 
