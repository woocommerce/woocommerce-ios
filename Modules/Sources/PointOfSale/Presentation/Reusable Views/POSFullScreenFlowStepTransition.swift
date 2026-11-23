import SwiftUI

enum POSFlowStepDirection: Equatable {
    case forward
    case backward
}

/// Takes a page builder, not a view modifier: a modifier's content always shows the current state, so the page
/// sliding out would already show the new step.
struct POSFullScreenFlowSteps<ID: Hashable, Page: View>: View {
    @Environment(\.isPOSModalFullScreenFlow) private var isFullScreenFlow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let id: ID
    private let direction: () -> POSFlowStepDirection
    private let page: () -> Page

    init(id: ID, direction: @escaping () -> POSFlowStepDirection, @ViewBuilder page: @escaping () -> Page) {
        self.id = id
        self.direction = direction
        self.page = page
    }

    var body: some View {
        if isFullScreenFlow && UIDevice.current.userInterfaceIdiom == .phone {
            ZStack {
                page()
                    .id(id)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(POSFlowStepSlideTransition(direction: direction)))
            }
            .animation(.easeInOut(duration: POSFlowStepSlideTransition.animationDuration), value: id)
        } else {
            page()
        }
    }
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
