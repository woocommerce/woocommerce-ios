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
    private let step: Step
    private let page: () -> Page

    init(step: Step, @ViewBuilder page: @escaping () -> Page) {
        self.step = step
        self.page = page
    }

    var body: some View {
        if isFullScreenFlow && UIDevice.current.userInterfaceIdiom == .phone {
            let _ = navigation?.show(step: step)
            ZStack {
                page()
                    .id(step)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(POSFlowStepSlideTransition(direction: { [navigation] in
                        navigation?.direction ?? .forward
                    })))
            }
            .animation(.easeInOut(duration: POSFlowStepSlideTransition.animationDuration), value: step)
        } else {
            page()
        }
    }
}

final class POSModalFlowStepNavigation {
    private(set) var direction = POSFlowStepDirection.forward
    private var nextDirection = POSFlowStepDirection.forward
    private var step: AnyHashable?

    func goBackwardOnNextStep() {
        nextDirection = .backward
    }

    func show(step newStep: AnyHashable) {
        guard newStep != step else {
            return
        }
        direction = step == nil ? .forward : nextDirection
        nextDirection = .forward
        step = newStep
    }
}

extension EnvironmentValues {
    @Entry var posModalFlowStepNavigation: POSModalFlowStepNavigation?
}

/// Reads the direction lazily: a removed page keeps the transition of its last render, so a direction stored there
/// would slide the old page out the wrong way on the first change after the direction flips.
struct POSFlowStepSlideTransition: Transition {
    static let animationDuration: CGFloat = 0.3

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
