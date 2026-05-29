import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._model = State(initialValue: POSLockScreenModel(session: session))
    }

    var body: some View {
        content
            .disabled(model.isLocked)
            .accessibilityHidden(model.isLocked)
            .overlay {
                if model.isLocked {
                    POSLockScreenView(model: model)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: POSLockScreenOverlayConstants.animationDuration), value: model.isLocked)
    }
}

private struct POSLockScreenOverlayModifier: ViewModifier {
    @Environment(\.posAccessSession) private var session

    func body(content: Content) -> some View {
        POSLockScreenOverlay(session: session) {
            content
        }
    }
}

extension View {
    func posLockScreenOverlay() -> some View {
        modifier(POSLockScreenOverlayModifier())
    }
}

private enum POSLockScreenOverlayConstants {
    static let animationDuration: TimeInterval = 0.2
}

#if DEBUG
#Preview("Modifier over dashboard") {
    NavigationStack {
        PointOfSaleDashboardView()
            .environment(POSPreviewHelpers.makePreviewAggregateModel())
            .environmentObject(POSModalManager())
            .posLockScreenOverlay()
    }
    .environment(\.posAccessSession, MockPOSAccessSession(isLocked: true))
}
#endif
