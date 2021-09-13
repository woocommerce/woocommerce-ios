import SwiftUI

/// Lazily loads a `View` using a closure as a builder function.
/// Useful for cases when it's not desired to load the `View` at the view definition time. EG: `NavigationLink`
///
struct LazyView<Wrapped: View>: View {

    /// Builder closure
    ///
    private let wrapped: () -> Wrapped

    /// Creates a wrapper for a view to be instantiated lazily.
    /// - Parameters:
    ///   - wrapped: View builder function.
    init(_ wrapped: @autoclosure @escaping () -> Wrapped) {
        self.wrapped = wrapped
    }

    /// Creates a wrapper for a view to be instantiated lazily.
    /// - Parameters:
    ///   - wrapped: View builder closure.
    init(_ wrapped: @escaping () -> Wrapped) {
        self.wrapped = wrapped
    }

    var  body: Wrapped {
        wrapped()
    }
}
