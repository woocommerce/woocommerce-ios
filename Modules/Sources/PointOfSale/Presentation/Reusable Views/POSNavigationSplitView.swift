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
    @State private var hasHorizontalSafeAreaInset = false
    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue, Binding<NavigationPath>) -> Detail
    private let detailPlaceholderView: () -> DetailPlaceholder
    private let setDefaultValue: (() -> Void)?
    private let pushedDetailBackgroundColor: Color

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        pushedDetailBackgroundColor: Color = .posSurface,
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
        self.pushedDetailBackgroundColor = pushedDetailBackgroundColor
    }

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    private var ignoresBottomContainerInset: Bool {
        // Match the dashboard's iOS 26+ workaround when the system bar occupies a side.
        // Ordinary bottom system bars keep their safe area.
        if #available(iOS 26, *) {
            return isRegular && hasHorizontalSafeAreaInset
        }
        return false
    }

    private var visibleDetailBackgroundColor: Color {
        detailNavigationPath.isEmpty ? .posSurface : pushedDetailBackgroundColor
    }

    private var sidebarSelection: Binding<SelectionValue?> {
        Binding {
            selection
        } set: { newValue in
            if let currentSelection = selection,
               currentSelection.id == newValue?.id {
                detailNavigationPath = NavigationPath()
            }
            selection = newValue
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = POSBookPoseLayout(geometry: geometry, defaultLeadingFraction: Constants.sidebarWidthFraction)

            POSPushTransitionContainer(
                item: selection,
                sideBySide: isRegular ? .init(rootWidth: layout.leadingWidth,
                                              pushedWidth: layout.trailingWidth,
                                              spacing: layout.spacing) : nil,
                // A non-empty detail path means a sub-screen is pushed and owns its own back affordance,
                // so the container must not also swipe the whole pane away.
                isBackGestureEnabled: detailNavigationPath.isEmpty,
                onBack: { selection = nil }
            ) {
                sidebar(sidebarSelection)
            } pushed: { displayedSelection in
                NavigationStack(path: $detailNavigationPath) {
                    VStack {
                        if let displayedSelection {
                            detail(displayedSelection, $detailNavigationPath)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else {
                            detailPlaceholderView()
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                    }
                    // Cross-fading the placeholder into the detail only makes sense side by side,
                    // where the merchant is looking at the pane while it changes. In compact the
                    // pane is off-screen until it slides in, so the fade would only make the
                    // arriving screen translucent for the length of the slide.
                    .animation(isRegular ? .default : nil, value: selection != nil)
                    .navigationBarHidden(true)
                    .posIgnoresHiddenKeyboardSafeArea()
                    .ignoresSafeArea(.container, edges: ignoresBottomContainerInset ? .bottom : [])
                }
                // The stack has no backdrop of its own, so without this any moment where the
                // detail is not yet drawn shows the host's background instead. It has to reach into
                // the safe areas too, because the sidebar passes behind this pane rather than
                // leaving the screen, and would otherwise show through above and below it.
                .background(Color.posSurface.ignoresSafeArea())
            }
            .background {
                if isRegular {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: layout.backgroundLeadingWidth)
                            .background(Color.posSurfaceBright.ignoresSafeArea(.all, edges: [.top, .bottom, .leading]))
                        Color.clear
                            .background(visibleDetailBackgroundColor.ignoresSafeArea(.all, edges: [.top, .bottom, .trailing]))
                    }
                    .background(Color.posSurface)
                } else {
                    (selection == nil ? Color.posSurfaceBright : visibleDetailBackgroundColor)
                        .ignoresSafeArea()
                }
            }
            .posBookPoseAnimation(layout)
            .environment(\.posContentPaddingContext, layout.contentPadding)
        }
        .onGeometryChange(for: Bool.self) { geometry in
            // A landscape phone notch reserves both sides equally; keep its bottom home-indicator inset.
            geometry.safeAreaInsets.leading != geometry.safeAreaInsets.trailing
        } action: { hasHorizontalSafeAreaInset = $0 }
        .ignoresSafeArea(.container, edges: ignoresBottomContainerInset ? .bottom : [])
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
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
