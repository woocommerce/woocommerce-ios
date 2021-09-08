import SwiftUI

/// Lazily loads a `View` using a closure as a builder function.
/// Useful for cases when it's not desired to load the `View` at the view definition time. EG: `NavigationLink`
///
struct LazyView<Wrapped: View>: View {

    /// Builder closure
    ///
    private let wrapped: () -> Wrapped

    /// Stores the function as a closure using the `@autoclosure` attribute.
    ///
    init(_ wrapped: @autoclosure @escaping () -> Wrapped) {
        self.wrapped = wrapped
    }

    /// Receives the builder closure.
    ///
    init(_ wrapped: @escaping () -> Wrapped) {
        self.wrapped = wrapped
    }

    var  body: Wrapped {
        wrapped()
    }
}
