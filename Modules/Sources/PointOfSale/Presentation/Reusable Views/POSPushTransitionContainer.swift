import SwiftUI

/// Hosts a root screen and a screen pushed over it, and moves between them with the platform push:
/// the pushed screen arrives from the trailing edge while the root drifts under it, and back reverses
/// that, following the finger on a leading-edge swipe.
///
/// Both screens are siblings in one container rather than levels of a `NavigationStack`. POS hides the
/// navigation bar, which switches off the interactive pop, and some roots carry a stack of their own
/// that can't be nested in another.
///
/// With a `sideBySide` layout both screens are shown next to each other and nothing slides. The view
/// tree is the same either way, so a size-class change keeps the screens' state.
struct POSPushTransitionContainer<Item: Equatable, Root: View, Pushed: View>: View {
    struct SideBySideLayout {
        let rootWidth: CGFloat
        let pushedWidth: CGFloat
        let spacing: CGFloat
    }

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var isPushed: Bool
    /// The item that was on screen when a pop started. Without it, the pushed screen would switch to
    /// its `nil` content in the same update that starts sliding it away.
    @State private var poppingItem: Item?
    /// Bumped on every navigation, so a finished animation can tell it has been superseded.
    @State private var navigationGeneration = 0
    /// Bumped whenever a back drag stops being allowed to finish, so the release animation's
    /// completion can't navigate back on stale eligibility.
    @State private var dragGeneration = 0
    /// Distance the in-progress back drag has travelled towards the root, always positive however the
    /// layout runs. Zero whenever no drag is in flight.
    @State private var dragTranslation: CGFloat = 0
    @State private var dragPhase: DragPhase = .idle
    /// Set once an accepted back drag hands over to `onBack`. Changing `item` clears it, so if it is
    /// still set after that update the caller kept the item and the pushed screen has to come back.
    @State private var isAwaitingBackResult = false
    /// Resets itself when the drag ends *or is cancelled*, which is the only signal a cancelled drag
    /// gives us. See `DragPhase`.
    @GestureState private var isDragActive = false

    private let item: Item?
    private let sideBySide: SideBySideLayout?
    private let isBackGestureEnabled: Bool
    private let animatesPop: (Item) -> Bool
    private let onBack: () -> Void
    private let root: Root
    private let pushed: (Item?) -> Pushed

    init(item: Item?,
         sideBySide: SideBySideLayout? = nil,
         isBackGestureEnabled: Bool = true,
         animatesPop: @escaping (Item) -> Bool = { _ in true },
         onBack: @escaping () -> Void,
         @ViewBuilder root: () -> Root,
         @ViewBuilder pushed: @escaping (Item?) -> Pushed) {
        self.item = item
        self.sideBySide = sideBySide
        self.isBackGestureEnabled = isBackGestureEnabled
        self.animatesPop = animatesPop
        self.onBack = onBack
        self.root = root()
        self.pushed = pushed
        _isPushed = State(initialValue: item != nil)
    }

    private var displayedItem: Item? {
        POSPushTransitionHelper.displayedItem(item: item, poppingItem: poppingItem, isSideBySide: sideBySide != nil)
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let progress = pushProgress(totalWidth: totalWidth)

            HStack(spacing: sideBySide?.spacing ?? 0) {
                root
                    .frame(width: sideBySide?.rootWidth ?? totalWidth)
                    .offset(x: policy.outgoingParallaxOffset(progress: progress, totalWidth: totalWidth))
                    // The panes lay out inside the safe area, so a dim that stops there leaves undimmed
                    // bands above and below it, which reads as banding rather than one screen sliding
                    // under another.
                    .overlay {
                        Color.black
                            .opacity(Constants.rootDimOpacity * progress)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    .allowsHitTesting(progress < 1)
                    .accessibilityHidden(progress == 1)

                pushed(displayedItem)
                    .frame(width: sideBySide?.pushedWidth ?? totalWidth)
                    .overlay(alignment: .leading) {
                        leadingEdgeShadow(progress: progress)
                    }
                    .accessibilityHidden(sideBySide == nil && !isPushed)
            }
            .offset(x: policy.incomingOffset(progress: progress, totalWidth: totalWidth))
            .frame(width: totalWidth, height: geometry.size.height, alignment: .leading)
            // Clips the offscreen pane horizontally. While sliding, each pane's background has to reach under
            // the status bar and home indicator and move with it, otherwise those strips change color at once
            // for the whole width. Side by side, the caller paints those strips instead.
            .clipShape(VerticallyExtendedRectangle(top: sideBySide == nil ? geometry.safeAreaInsets.top : 0,
                                                   bottom: sideBySide == nil ? geometry.safeAreaInsets.bottom : 0))
            .simultaneousGesture(backGesture(totalWidth: totalWidth), isEnabled: isBackGestureActive)
        }
        // Anchors the gesture's coordinates to this view rather than to the window, which is only the
        // same thing when the window fills the screen.
        .coordinateSpace(.named(Constants.coordinateSpaceName))
        .onChange(of: isDragActive) { _, isActive in
            // A cancelled drag delivers no `onEnded`, so nothing else will put the panes back.
            // Still `.dragging` here means `onEnded` never ran and this is that case.
            guard !isActive, dragPhase == .dragging else { return }
            dragPhase = .idle
            withAnimation(Constants.transition) {
                dragTranslation = 0
            }
        }
        .onChange(of: item) { oldValue, newValue in
            isAwaitingBackResult = false
            dragGeneration += 1
            navigate(from: oldValue, to: newValue)
        }
        .task(id: isAwaitingBackResult) {
            // Starts only after the update in which `onBack` ran has finished, so when the caller
            // cleared the item, `onChange(of: item)` has already settled the drag by now.
            guard isAwaitingBackResult else { return }
            isAwaitingBackResult = false
            guard dragPhase == .completing else { return }
            dragPhase = .idle
            withAnimation(Constants.transition) {
                dragTranslation = 0
            }
        }
        .onChange(of: canNavigateBack) { oldValue, newValue in
            // A release animation can still be running when checkout locks (a card is inserted) or a
            // compact window expands to side by side. Its completion must not navigate back then.
            guard POSPushTransitionHelper.invalidatesInFlightDrag(couldNavigateBack: oldValue,
                                                                  canNavigateBack: newValue) else { return }
            dragGeneration += 1
            guard dragPhase != .idle else { return }
            dragPhase = .idle
            withAnimation(Constants.transition) {
                dragTranslation = 0
            }
        }
    }

    private func navigate(from oldValue: Item?, to newValue: Item?) {
        navigationGeneration += 1
        let generation = navigationGeneration

        switch POSPushTransitionHelper.navigation(from: oldValue,
                                                  to: newValue,
                                                  isCompletingDrag: dragPhase == .completing,
                                                  animatesPop: oldValue.map(animatesPop) ?? true) {
        case .push:
            poppingItem = nil
            if dragPhase == .completing {
                // A new item arrived while a back drag was finishing, so that drag no longer applies.
                dragPhase = .idle
                withAnimation(Constants.transition) {
                    dragTranslation = 0
                }
            }
            guard !isPushed else { return }
            withAnimation(Constants.transition) {
                isPushed = true
            }
        case .settleCompletedDrag, .popWithoutAnimation:
            // Animating this would move the panes a second time, back the way they came.
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isPushed = false
                dragTranslation = 0
            }
            dragPhase = .idle
        case .pop(let retainedItem):
            poppingItem = retainedItem
            withAnimation(Constants.transition, completionCriteria: .logicallyComplete) {
                isPushed = false
            } completion: {
                guard generation == navigationGeneration else { return }
                poppingItem = nil
            }
        }
    }

    // MARK: - Layout

    /// How far the pushed screen has travelled over the root: `1` when it covers it, `0` when the root
    /// is fully back. Always zero side by side, which makes every transition modifier inert there.
    private func pushProgress(totalWidth: CGFloat) -> CGFloat {
        guard sideBySide == nil, isPushed else { return 0 }
        return policy.incomingProgress(dragTranslation: dragTranslation, totalWidth: totalWidth)
    }

    /// A soft edge drawn just outside the pushed screen, so it falls on the root. A `shadow` on the
    /// screen itself would blur a full-screen view on every frame of a drag.
    ///
    /// Kept in the hierarchy and faded by `progress` rather than inserted and removed: a view removed
    /// part-way through a transition stops following the pane and is left hanging mid-screen.
    private func leadingEdgeShadow(progress: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, .black.opacity(Constants.leadingEdgeShadowOpacity)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: Constants.leadingEdgeShadowWidth)
        .offset(x: -Constants.leadingEdgeShadowWidth)
        .opacity(progress)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Back gesture

    /// Where a back drag is in its life cycle. `onEnded` is not guaranteed to arrive: a cancelled drag
    /// delivers no callback at all, so the phase tells it apart from one `onEnded` has taken over.
    private enum DragPhase {
        case idle
        case dragging
        case completing
    }

    /// Leaves out `item`: clearing it is how an accepted back ends, which must not count as the drag
    /// losing its eligibility.
    private var canNavigateBack: Bool {
        sideBySide == nil && isBackGestureEnabled
    }

    private var isBackGestureActive: Bool {
        canNavigateBack && item != nil
    }

    private func backGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(
            minimumDistance: POSEdgeSwipePolicy.minimumDragDistance,
            coordinateSpace: .named(Constants.coordinateSpaceName)
        )
        .updating($isDragActive) { _, isActive, _ in
            isActive = true
        }
        .onChanged { value in
            guard policy.startsAtLeadingEdge(value.startLocation.x, totalWidth: totalWidth),
                  policy.isPredominantlyHorizontal(value.translation) else {
                return
            }
            dragPhase = .dragging
            dragTranslation = policy.clampedTranslation(value.translation.width, totalWidth: totalWidth)
        }
        .onEnded { value in
            guard policy.startsAtLeadingEdge(value.startLocation.x, totalWidth: totalWidth) else { return }
            let shouldNavigateBack = policy.isPredominantlyHorizontal(value.translation)
                && policy.shouldComplete(
                    translation: value.translation.width,
                    predictedEndTranslation: value.predictedEndTranslation.width,
                    totalWidth: totalWidth
                )

            guard shouldNavigateBack else {
                dragPhase = .idle
                withAnimation(Constants.transition) {
                    dragTranslation = 0
                }
                return
            }

            dragPhase = .completing
            let generation = dragGeneration
            withAnimation(Constants.transition, completionCriteria: .logicallyComplete) {
                dragTranslation = totalWidth
            } completion: {
                guard generation == dragGeneration else { return }
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction, onBack)
                // An accepted back clears the item, and `navigate` settles the drag. If the caller
                // kept the item, nothing else would bring the pushed screen back on screen.
                isAwaitingBackResult = true
            }
        }
    }

    private var policy: POSEdgeSwipePolicy {
        POSEdgeSwipePolicy(layoutDirection: layoutDirection)
    }
}

private enum Constants {
    static let coordinateSpaceName = "POSPushTransitionContainer"
    static let rootDimOpacity: CGFloat = 0.12
    static let leadingEdgeShadowWidth: CGFloat = 12
    static let leadingEdgeShadowOpacity: CGFloat = 0.18
    /// Shared by the tap-driven push and by the release of an interactive drag, so a screen that
    /// arrives from a tap and one that arrives from a swipe travel at the same rate.
    ///
    /// A spring rather than an ease: it front-loads the movement, which is what makes a platform push
    /// feel immediate.
    static let transition: Animation = .snappy(duration: 0.3)
}

private struct VerticallyExtendedRectangle: Shape {
    let top: CGFloat
    let bottom: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY - top, width: rect.width, height: rect.height + top + bottom))
    }
}
