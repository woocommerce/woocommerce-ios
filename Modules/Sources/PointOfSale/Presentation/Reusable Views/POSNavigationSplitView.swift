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
    /// Distance the in-progress back drag has travelled towards the sidebar, always positive
    /// however the layout runs. Zero whenever no drag is in flight.
    @State private var dragTranslation: CGFloat = 0
    @State private var dragPhase: DragPhase = .idle
    /// Resets itself when the drag ends *or is cancelled*, which is the only signal a cancelled
    /// drag gives us. See `DragPhase`.
    @GestureState private var isDragActive = false

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
            let totalWidth = geometry.size.width
            let progress = detailProgress(for: totalWidth)

            HStack(spacing: 0) {
                sidebar(sidebarSelection)
                    .frame(width: sidebarWidth(for: totalWidth))
                    .offset(x: edgeSwipePolicy.outgoingParallaxOffset(progress: progress, totalWidth: totalWidth))
                    // The panes lay out inside the safe area, so anything drawn over them stops at
                    // the status bar and the home indicator. A dim that stops short of those leaves
                    // undimmed bands of list showing above and below it, which reads as banding
                    // rather than as one screen sliding under another.
                    .overlay {
                        Color.black
                            .opacity(Constants.sidebarDimOpacity * progress)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }

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
                    // Cross-fading the placeholder into the detail only makes sense side by side,
                    // where the merchant is looking at the pane while it changes. In compact the
                    // pane is off-screen until it slides in, so the fade would only make the
                    // arriving screen translucent for the length of the slide.
                    .animation(isRegular ? .default : nil, value: selection != nil)
                    .navigationBarHidden(true)
                }
                .frame(width: detailWidth(for: totalWidth))
                // The stack has no backdrop of its own, so without this any moment where the
                // detail is not yet drawn shows the host's background instead. It has to reach into
                // the safe areas too, because the sidebar now passes behind this pane rather than
                // leaving the screen, and would otherwise show through above and below it.
                .background(Color.posSurface.ignoresSafeArea())
                .overlay(alignment: .leading) {
                    leadingEdgeShadow(progress: progress)
                }
            }
            .offset(x: edgeSwipePolicy.incomingOffset(progress: progress, totalWidth: totalWidth))
            .simultaneousGesture(
                compactBackGesture(totalWidth: totalWidth),
                isEnabled: isCompactBackGestureActive
            )
        }
        // Anchors the gesture's coordinates to this view rather than to the window. `.global` is
        // only the same thing as "this split view" when the window fills the screen, which is why
        // measuring the edge against it worked on a phone and failed in a collapsed iPad window.
        .coordinateSpace(.named(Constants.coordinateSpaceName))
        .animation(Constants.paneTransition, value: selection != nil)
        .onChange(of: isDragActive) { _, isActive in
            // A cancelled drag delivers no `onEnded`, so nothing else will put the panes back.
            // Still `.dragging` here means `onEnded` never ran and this is that case; any other
            // phase means it did run and has already decided what happens next.
            guard !isActive, dragPhase == .dragging else { return }
            dragPhase = .idle
            withAnimation(Constants.paneTransition) {
                dragTranslation = 0
            }
        }
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

    /// How far the detail pane has travelled over the sidebar: `1` when it covers it, `0` when the
    /// sidebar is fully back. Zero in regular width, where both panes are on screen at once and
    /// nothing slides — which makes every transition modifier above inert there.
    private func detailProgress(for totalWidth: CGFloat) -> CGFloat {
        guard !isRegular, selection != nil else { return 0 }
        return edgeSwipePolicy.incomingProgress(dragTranslation: dragTranslation, totalWidth: totalWidth)
    }

    /// A soft edge on the detail pane's leading side, drawn just outside it so it falls on the
    /// sidebar. A `shadow` on the pane itself would blur a full-screen view on every frame of a drag.
    ///
    /// Kept in the hierarchy at all times and faded by `progress`, rather than inserted and removed.
    /// A view removed part-way through a transition gets a removal transition of its own, and SwiftUI
    /// stops updating its position while that plays — so a fast swipe left the shadow behind, hanging
    /// mid-screen and fading out on its own while the pane carried on without it.
    private func leadingEdgeShadow(progress: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, .black.opacity(Constants.leadingEdgeShadowOpacity)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: Constants.leadingEdgeShadowWidth)
        .offset(x: -Constants.leadingEdgeShadowWidth * edgeSwipePolicy.direction)
        .opacity(progress)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Where a back drag is in its life cycle.
    ///
    /// `onEnded` is not guaranteed to arrive: a drag that is cancelled rather than ended delivers
    /// no callback at all. Tracking the phase lets a cancelled drag be told apart from one that
    /// `onEnded` has already taken responsibility for, so the panes are never left stranded
    /// part-way across.
    private enum DragPhase {
        case idle
        case dragging
        case completing
    }

    private var isCompactBackGestureActive: Bool {
        !isRegular && selection != nil && detailNavigationPath.isEmpty && isCompactBackGestureEnabled
    }

    private func compactBackGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(
            minimumDistance: POSEdgeSwipePolicy.minimumDragDistance,
            coordinateSpace: .named(Constants.coordinateSpaceName)
        )
        .updating($isDragActive) { _, isActive, _ in
            isActive = true
        }
        .onChanged { value in
            guard edgeSwipePolicy.startsAtLeadingEdge(value.startLocation.x, totalWidth: totalWidth),
                  edgeSwipePolicy.isPredominantlyHorizontal(value.translation) else {
                return
            }
            dragPhase = .dragging
            dragTranslation = edgeSwipePolicy.clampedTranslation(
                value.translation.width,
                totalWidth: totalWidth
            )
        }
        .onEnded { value in
            guard edgeSwipePolicy.startsAtLeadingEdge(value.startLocation.x, totalWidth: totalWidth) else { return }
            let shouldNavigateBack = edgeSwipePolicy.isPredominantlyHorizontal(value.translation)
                && edgeSwipePolicy.shouldComplete(
                    translation: value.translation.width,
                    predictedEndTranslation: value.predictedEndTranslation.width,
                    totalWidth: totalWidth
                )

            if shouldNavigateBack {
                dragPhase = .completing
                withAnimation(Constants.paneTransition, completionCriteria: .logicallyComplete) {
                    dragTranslation = totalWidth
                } completion: {
                    // Clearing the selection is what actually ends the navigation, but it also
                    // resets the progress the animation just drove to zero. Doing both without a
                    // transaction would animate the panes a second time, back the way they came.
                    var transaction = Transaction(animation: nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        selection = nil
                        dragTranslation = 0
                    }
                    dragPhase = .idle
                }
            } else {
                dragPhase = .idle
                withAnimation(Constants.paneTransition) {
                    dragTranslation = 0
                }
            }
        }
    }

    private var edgeSwipePolicy: POSEdgeSwipePolicy {
        POSEdgeSwipePolicy(layoutDirection: layoutDirection)
    }
}

private enum Constants {
    /// Names this split view's own coordinate space, so the back gesture can measure the leading
    /// edge against the view it belongs to instead of against the window.
    static let coordinateSpaceName = "POSNavigationSplitView"
    static let sidebarWidthFraction: CGFloat = 0.35
    static let sidebarDimOpacity: CGFloat = 0.12
    static let leadingEdgeShadowWidth: CGFloat = 12
    static let leadingEdgeShadowOpacity: CGFloat = 0.18
    /// Shared by the tap-driven push and by the release of an interactive drag, so a pane that
    /// arrives from a tap and one that arrives from a swipe travel at the same rate.
    ///
    /// A spring rather than an ease: it front-loads the movement, which is what makes a platform
    /// push feel immediate. `.default` here read as sluggish next to the pushes inside the detail
    /// pane, which are real `NavigationStack` transitions.
    static let paneTransition: Animation = .snappy(duration: 0.3)
}
