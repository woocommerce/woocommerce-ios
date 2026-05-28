import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    @State private var model: POSLockScreenModel

    init(session: POSAccessSession, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._model = State(initialValue: POSLockScreenModel(session: session))
    }

    private var shouldPresentLockScreen: Bool {
        // No-PIN stores have no security boundary to enforce - skip the lock screen entirely
        // so the device admin can operate POS without setup. `.unknown` deliberately keeps the
        // overlay up: until we've confirmed there are zero PINs, the safe default is to gate
        // access (the lock screen renders a retry/loading variant in that branch).
        model.isLocked && model.pinStatus != .absent
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
    .environment(\.posAccessSession, MockPOSAccessSession(isLocked: true))
}
#endif
