import SwiftUI

/// An alternative split view implementation that gives more control of the split view design,
/// including the sidebar and content arrangement and separator colors.
/// Just as NavigationSplitView, it adapts to a list -> details navigation on smaller screens.
///
/// Both sidebar and detail are always in the view tree — layout adapts via frame widths and offset,
/// never conditional branches on size class. This prevents view destruction (and loss of @State,
/// presented sheets, @Environment objects) when horizontalSizeClass flickers during background transitions.
struct POSNavigationSplitView<Sidebar: View, Detail: View, DetailPlaceholder: View, SelectionValue: Hashable & Identifiable>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var selection: SelectionValue?
    @State private var detailNavigationPath = NavigationPath()

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

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                sidebar($selection)
                    .frame(width: sidebarWidth(for: geometry.size.width))

                NavigationStack(path: $detailNavigationPath) {
                    VStack {
                        if let selection {
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
                .frame(width: detailWidth(for: geometry.size.width))
            }
            .offset(x: compactOffset(for: geometry.size.width))
        }
        .animation(.default, value: selection != nil)
        .onAppear {
            if isRegular, selection == nil {
                setDefaultValue?()
            }
        }
        .onChange(of: horizontalSizeClass) { _, newValue in
            if newValue == .regular, selection == nil {
                setDefaultValue?()
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            guard oldValue?.id != newValue?.id else { return }
            detailNavigationPath = NavigationPath()
        }
    }

    // MARK: - Layout

    private func sidebarWidth(for totalWidth: CGFloat) -> CGFloat {
        isRegular ? totalWidth * Constants.sidebarWidthFraction : totalWidth
    }

    private func detailWidth(for totalWidth: CGFloat) -> CGFloat {
        isRegular ? totalWidth * (1 - Constants.sidebarWidthFraction) : totalWidth
    }

    private func compactOffset(for totalWidth: CGFloat) -> CGFloat {
        guard !isRegular, selection != nil else { return 0 }
        return -totalWidth
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
