import SwiftUI

/// `NavigationLink` wrapper that instantiates  the `DestinationView`  when the navigation occurs.
///
struct LazyNavigationLink<Destination: View, Label: View>: View {

    /// Destination view builder
    ///
    private let destination: () -> Destination

    /// Set it to `true` to proceed with the desired navigation. Set it to `false` to remove the view from the navigation context.
    ///
    var isActive: Binding<Bool>?

    /// `NavigationLink` label
    ///
    private let label: () -> Label

    /// Creates a navigation link that creates and presents the destination view when active.
    /// - Parameters:
    ///   - destination: A view for the navigation link to present.
    ///   - isActive: An optional binding to a Boolean value that indicates whether `destination` is currently presented.
    ///   - label: A view builder to produce a label describing the `destination` to present.
    init(destination: @autoclosure @escaping () -> Destination, isActive: Binding<Bool>? = nil, label: @escaping () -> Label) {
        self.destination = destination
        self.isActive = isActive
        self.label = label
    }

    var body: some View {
        if let isActive = isActive {
            NavigationLink(destination: LazyView(destination), isActive: isActive, label: label)
        } else {
            NavigationLink(destination: LazyView(destination), label: label)
        }
    }
}
