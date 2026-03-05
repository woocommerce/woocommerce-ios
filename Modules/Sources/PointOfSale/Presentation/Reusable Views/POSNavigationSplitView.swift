import SwiftUI

/// An alternative split view implementation that gives more control of the split view design,
/// including the sidebar and content arrangement and separator colors.
/// Just as NavigationSplitView, it adapts to a list -> details navigation on smaller screens.
struct POSNavigationSplitView<Sidebar: View, Detail: View, DetailPlaceholder: View, SelectionValue: Hashable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var selection: SelectionValue?

    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue) -> Detail
    private let detailPlaceholderView: () -> DetailPlaceholder
    private let setDefaultValue: (() -> Void)?

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        @ViewBuilder sidebar: @escaping (Binding<SelectionValue?>) -> Sidebar,
        @ViewBuilder detail: @escaping (SelectionValue) -> Detail,
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
        switch horizontalSizeClass {
        case .regular:
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    sidebar($selection)
                        .frame(width: geometry.size.width * Constants.sidebarWidthFraction)

                    VStack {
                        if let selection = selection {
                            detail(selection)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else {
                            detailPlaceholderView()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                    }
                    .animation(.default, value: selection != nil)
                }
            }
            .onAppear {
                if selection == nil {
                    setDefaultValue?()
                }
            }
        default:
            NavigationStack {
                sidebar($selection)
                    .navigationDestination(isPresented: Binding(
                        get: { selection != nil },
                        set: { if !$0 { selection = nil } }
                    )) {
                        if let selection = selection {
                            detail(selection)
                        }
                    }
            }
        }
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
