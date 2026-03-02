import SwiftUI

/// An alternative split view implementation that gives more control of the split view design,
/// including the sidebar and content arrangement and separator colors.
/// Just as NavigationSplitView, it adapts to a list -> details navigation on smaller screens.
struct POSNavigationSplitView<Sidebar: View, Detail: View, DetailPlaceholder: View, SelectionValue: Hashable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var selection: SelectionValue?
    @State private var detailNavigationPath = NavigationPath()
    /// Debounced size class that filters out transient changes iOS 18 fires
    /// during background/foreground transitions.
    @State private var stableHorizontalSizeClass: UserInterfaceSizeClass?

    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue, Binding<NavigationPath>) -> Detail
    private let detailPlaceholderView: () -> DetailPlaceholder
    private let setDefaultValue: (() -> Void)?

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        @ViewBuilder sidebar: @escaping (Binding<SelectionValue?>) -> Sidebar,
        @ViewBuilder detail: @escaping (SelectionValue, Binding<NavigationPath>) -> Detail,
        @ViewBuilder detailPlaceholderView: @escaping () -> DetailPlaceholder,
        setDefaultValue: (() -> Void)? = nil
    ) {
        self._selection = selection
        self.sidebar = sidebar
        self.detail = detail
        self.detailPlaceholderView = detailPlaceholderView
        self.setDefaultValue = setDefaultValue
    }

    var body: some View {
        Group {
            switch stableHorizontalSizeClass ?? horizontalSizeClass {
            case .regular:
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        sidebar($selection)
                            .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                        NavigationStack(path: $detailNavigationPath) {
                            VStack {
                                if let selection = selection {
                                    detail(selection, $detailNavigationPath)
                                        .frame(maxWidth: .infinity)
                                        .transition(.opacity)
                                } else {
                                    detailPlaceholderView()
                                        .frame(maxWidth: .infinity)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.default, value: selection != nil)
                            .navigationBarHidden(true)
                        }
                    }
                }
            default:
                NavigationStack(path: $detailNavigationPath) {
                    sidebar($selection)
                        .navigationDestination(for: SelectionValue.self) { selectedValue in
                            detail(selectedValue, $detailNavigationPath)
                        }
                }
            }
        }
        .onAppear {
            stableHorizontalSizeClass = horizontalSizeClass
            if horizontalSizeClass == .regular {
                if selection == nil {
                    setDefaultValue?()
                }
            } else if detailNavigationPath.isEmpty, let selection {
                detailNavigationPath.append(selection)
            }
        }
        .task(id: horizontalSizeClass) {
            // Debounce: iOS 18 devices fire transient horizontalSizeClass
            // changes during background/foreground transitions. By waiting
            // briefly, we let the transient change revert (cancelling this
            // task) so the layout never swaps and the path is untouched.
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }

            let previous = stableHorizontalSizeClass
            stableHorizontalSizeClass = horizontalSizeClass

            // On genuine size class change, adapt the navigation path for
            // the new layout's path semantics (compact prepends SelectionValue;
            // regular does not).
            if let previous, previous != horizontalSizeClass {
                detailNavigationPath = NavigationPath()
                if horizontalSizeClass != .regular, let selection {
                    detailNavigationPath.append(selection)
                }
                if horizontalSizeClass == .regular, selection == nil {
                    setDefaultValue?()
                }
            }
        }
        .onChange(of: selection) { _, newSelection in
            detailNavigationPath = NavigationPath()
            let isCompact = (stableHorizontalSizeClass ?? horizontalSizeClass) != .regular
            if isCompact, let newSelection {
                detailNavigationPath.append(newSelection)
            }
        }
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
