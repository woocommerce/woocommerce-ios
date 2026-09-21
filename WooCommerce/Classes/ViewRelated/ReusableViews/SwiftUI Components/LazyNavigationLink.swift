import SwiftUI

/// `NavigationLink` wrapper that instantiates the `DestinationView` when the navigation occurs.
///
struct LazyNavigationLink<Destination: View, Label: View>: View {

    /// Destination view builder
    ///
    private let destination: () -> Destination

    /// `NavigationLink` label
    ///
    private let label: () -> Label

    /// Creates a navigation link that creates and presents the destination view when selected.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - label: A view builder to produce a label describing the `destination` to present.
    init(destination: @autoclosure @escaping () -> Destination, label: @escaping () -> Label) {
        self.destination = destination
        self.label = label
    }

    var body: some View {
        NavigationLink(destination: LazyView(destination), label: label)
    }
}
