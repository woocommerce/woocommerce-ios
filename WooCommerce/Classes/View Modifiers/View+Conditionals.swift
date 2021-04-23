import SwiftUI

extension View {
    /// Renders a view if the provided  `condition` is met.
    /// If the `condition` is not met, an instance of `EmptyView` will be used in place of the receiver view.
    ///
    func renderedIf(_ condition: Bool) -> some View {
        guard condition else {
            return AnyView(EmptyView())
        }
        return AnyView(self)
    }
}
