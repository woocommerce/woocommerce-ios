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
    @Environment(\.layoutDirection) private var layoutDirection
    @Binding private var selection: SelectionValue?
    @State private var detailNavigationPath = NavigationPath()
    @State private var compactBackDragOffset: CGFloat = 0

    private let sidebar: (Binding<SelectionValue?>) -> Sidebar
    private let detail: (SelectionValue, Binding<NavigationPath>) -> Detail
    private let detailPlaceholderView: () -> DetailPlaceholder
    private let setDefaultValue: (() -> Void)?
    private let isCompactBackGestureEnabled: Bool

    init(
        selection: Binding<SelectionValue?> = .constant(nil),
        isCompactBackGestureEnabled: Bool = true,
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
        self.isCompactBackGestureEnabled = isCompactBackGestureEnabled
    }

    private var isRegular: Bool {
        horizontalSizeClass == .regular
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
            HStack(spacing: 0) {
                sidebar(sidebarSelection)
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
            .offset(x: compactOffset(for: geometry.size.width) + compactBackDragOffset)
            .simultaneousGesture(
                compactBackGesture(
                    totalWidth: geometry.size.width,
                    globalFrame: geometry.frame(in: .global)
                ),
                isEnabled: isCompactBackGestureActive
            )
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
        return -totalWidth * edgeSwipePolicy.direction
    }

    private var isCompactBackGestureActive: Bool {
        !isRegular && selection != nil && detailNavigationPath.isEmpty && isCompactBackGestureEnabled
    }

    private func compactBackGesture(totalWidth: CGFloat, globalFrame: CGRect) -> some Gesture {
        DragGesture(
            minimumDistance: POSEdgeSwipePolicy.minimumDragDistance,
            coordinateSpace: .global
        )
        .onChanged { value in
            guard startsAtLeadingEdge(value.startLocation.x, globalFrame: globalFrame) else { return }
            compactBackDragOffset = edgeSwipePolicy.clampedTranslation(
                value.translation.width,
                totalWidth: totalWidth
            ) * edgeSwipePolicy.direction
        }
        .onEnded { value in
            guard startsAtLeadingEdge(value.startLocation.x, globalFrame: globalFrame) else { return }
            let shouldNavigateBack = edgeSwipePolicy.shouldComplete(
                translation: value.translation.width,
                predictedEndTranslation: value.predictedEndTranslation.width,
                totalWidth: totalWidth
            )

            if shouldNavigateBack {
                withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                    compactBackDragOffset = totalWidth * edgeSwipePolicy.direction
                } completion: {
                    var transaction = Transaction(animation: nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selection = nil
                        compactBackDragOffset = 0
                    }
                }
            } else {
                withAnimation(.snappy) {
                    compactBackDragOffset = 0
                }
            }
        }
    }

    private var edgeSwipePolicy: POSEdgeSwipePolicy {
        POSEdgeSwipePolicy(layoutDirection: layoutDirection)
    }

    private func startsAtLeadingEdge(_ xPosition: CGFloat, globalFrame: CGRect) -> Bool {
        switch layoutDirection {
        case .leftToRight:
            xPosition <= globalFrame.minX + POSEdgeSwipePolicy.activationWidth
        case .rightToLeft:
            xPosition >= globalFrame.maxX - POSEdgeSwipePolicy.activationWidth
        @unknown default:
            xPosition <= globalFrame.minX + POSEdgeSwipePolicy.activationWidth
        }
    }
}

private enum Constants {
    static let sidebarWidthFraction: CGFloat = 0.35
}
