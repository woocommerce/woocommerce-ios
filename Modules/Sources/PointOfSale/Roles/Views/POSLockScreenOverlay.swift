import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._model = State(initialValue: POSLockScreenModel(session: session))
    }

    private var shouldPresentLockScreen: Bool {
        // The lock screen presents only when we have a confirmed PIN to enter. `.unknown`
        // and `.absent` are handled by the entry point (loading view, staff-error view,
        // or no overlay at all), so by the time this evaluates, `.present` is the only
        // case that should trigger the numpad.
        model.isLocked && model.pinStatus == .present
    }

    var body: some View {
        content
            .disabled(shouldPresentLockScreen)
            .accessibilityHidden(shouldPresentLockScreen)
            .overlay {
                if shouldPresentLockScreen {
                    POSLockScreenView(model: model)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: POSLockScreenOverlayConstants.animationDuration),
                       value: shouldPresentLockScreen)
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
    .environment(\.posAccessSession, MockPOSAccessSession(isLocked: true, pinStatus: .present))
}
#endif
