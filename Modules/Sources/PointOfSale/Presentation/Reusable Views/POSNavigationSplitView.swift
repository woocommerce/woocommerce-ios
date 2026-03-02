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
                    ZStack {
                        if let selection {
                            detail(selection, $detailNavigationPath)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.move(edge: .trailing))
                        } else {
                            sidebar($selection)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.move(edge: .leading))
                        }
                    }
                    .animation(.default, value: selection != nil)
                    .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            stableHorizontalSizeClass = horizontalSizeClass
            if horizontalSizeClass == .regular, selection == nil {
                setDefaultValue?()
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

            if let previous, previous != horizontalSizeClass,
               horizontalSizeClass == .regular, selection == nil {
                setDefaultValue?()
            }
        }
        .onChange(of: selection) { _, _ in
            detailNavigationPath = NavigationPath()
        }
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
