import SwiftUI

extension View {
    /// Renders a view if the provided  `condition` is met.
    /// If the `condition` is not met, an `nil`  will be used in place of the receiver view.
    ///
    func renderedIf(_ condition: Bool) -> Self? {
        guard condition else {
            return nil
        }
        return self
    }
}
