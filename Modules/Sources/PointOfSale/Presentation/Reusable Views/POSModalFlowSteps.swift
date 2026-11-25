import SwiftUI

enum POSFlowStepDirection: Equatable {
    case forward
    case backward
}

/// Slides between the steps of a full-screen flow on phone. The header Back makes the next step change go backward.
/// Takes a page builder, not a view modifier: a modifier's content always shows the current state, so the page
/// sliding out would already show the new step.
struct POSModalFlowSteps<Step: Hashable, Page: View>: View {
    @Environment(\.isPOSModalFullScreenFlow) private var isFullScreenFlow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.posModalFlowStepNavigation) private var navigation
    @State private var pacer: POSModalFlowStepPacer<Step>
    @State private var shownPage = ShownPage()
    private let step: Step
    private let page: () -> Page

    init(step: Step, @ViewBuilder page: @escaping () -> Page) {
        self.step = step
        self.page = page
        _pacer = State(initialValue: POSModalFlowStepPacer(step: step))
    }

    var body: some View {
        if isFullScreenFlow && UIDevice.current.userInterfaceIdiom == .phone {
            ZStack {
                currentPage
                    .allowsHitTesting(pacer.isSettled)
                    .id(pacer.shown)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(POSFlowStepSlideTransition(direction: { [navigation] in
                        navigation?.direction ?? .forward
                    })))
            }
            .animation(pacer.isSliding ? .easeInOut(duration: POSFlowStepSlideTransition.animationDuration) : nil, value: pacer.shown)
            .onChange(of: step) { _, step in
                pacer.show(step, direction: navigation?.takeDirection() ?? .forward)
                navigation?.follow(pacer)
            }
            .task(id: pacer.slideCount) {
                let duration = pacer.isModalArriving ? POSRootModalViewModifier.animationDuration : POSFlowStepSlideTransition.settleDuration
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else {
                    return
                }
                pacer.motionEnded()
                navigation?.follow(pacer)
            }
        } else {
            page()
        }
    }

    /// While a newer step waits for the running slide, the shown step keeps the page it was last built with.
    private var currentPage: Page {
        guard pacer.shown != step, let heldPage = shownPage.page else {
            let newPage = page()
            shownPage.page = newPage
            return newPage
        }
        return heldPage
    }

    private final class ShownPage {
        var page: Page?
    }
}

/// Steps that change during a slide collapse into the latest one, which slides in when that slide ends.
/// Steps that change while the modal arrives are swapped in on arrival: a page inserted into the moving modal is drawn at its final position.
struct POSModalFlowStepPacer<Step: Hashable> {
    private(set) var shown: Step
    private(set) var direction = POSFlowStepDirection.forward
    private(set) var isSliding = false
    private(set) var slideCount = 0
    private(set) var isModalArriving = true
    private var latest: Step
    private var latestDirection = POSFlowStepDirection.forward

    var isSettled: Bool {
        !isSliding && shown == latest
    }

    init(step: Step) {
        shown = step
        latest = step
    }

    mutating func show(_ step: Step, direction: POSFlowStepDirection = .forward) {
        latest = step
        latestDirection = direction
        if !isModalArriving && !isSliding {
            slideToLatest()
        }
    }

    mutating func motionEnded() {
        isSliding = false
        if isModalArriving {
            isModalArriving = false
            shown = latest
        } else {
            slideToLatest()
        }
    }

    private mutating func slideToLatest() {
        guard latest != shown else {
            return
        }
        shown = latest
        direction = latestDirection
        isSliding = true
        slideCount += 1
    }
}

final class POSModalFlowStepNavigation {
    private(set) var direction = POSFlowStepDirection.forward
    private(set) var isSettled = true
    private var nextDirection = POSFlowStepDirection.forward

    func goBackwardOnNextStep() {
        nextDirection = .backward
    }

    func takeDirection() -> POSFlowStepDirection {
        defer { nextDirection = .forward }
        return nextDirection
    }

    func follow<Step>(_ pacer: POSModalFlowStepPacer<Step>) {
        direction = pacer.direction
        isSettled = pacer.isSettled
    }
}

extension EnvironmentValues {
    @Entry var posModalFlowStepNavigation: POSModalFlowStepNavigation?
}

/// Reads the direction lazily: a removed page keeps the transition of its last render, so a direction stored there
/// would slide the old page out the wrong way on the first change after the direction flips.
struct POSFlowStepSlideTransition: Transition {
    static let animationDuration: CGFloat = 0.3
    /// A page that comes back before its removal has finished would reverse instead of sliding in.
    static let settleDuration = animationDuration + 0.05

    let direction: () -> POSFlowStepDirection

    func body(content: Content, phase: TransitionPhase) -> some View {
        MoveTransition(edge: Self.edge(for: direction(), phase: phase))
            .apply(content: content, phase: phase)
    }

    static func edge(for direction: POSFlowStepDirection, phase: TransitionPhase) -> Edge {
        switch (direction, phase) {
        case (.forward, .willAppear), (.backward, .didDisappear), (_, .identity):
            return .trailing
        case (.forward, .didDisappear), (.backward, .willAppear):
            return .leading
        }
    }
}
