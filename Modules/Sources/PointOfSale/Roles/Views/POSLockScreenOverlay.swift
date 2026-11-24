import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    private let session: POSAccessSession
    private let recovery: POSPINRecoveryProviding?

    init(session: POSAccessSession, recovery: POSPINRecoveryProviding? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.session = session
        self.recovery = recovery
    }

    var body: some View {
        content
            .disabled(session.isLocked)
            .accessibilityHidden(session.isLocked)
            // Keep POS mounted; hide its covered rendering without animating the lock-state change.
            .opacity(session.isLocked ? 0 : 1)
            .animation(nil, value: session.isLocked)
            .background(POSLockPresentationHost(session: session,
                                                 lockContent: POSLockScreenView(session: session, recovery: recovery).id(ObjectIdentifier(session))))
            .overlay {
                if session.isLocked {
                    // Keep the source opaque before its scene window is attached.
                    Color.posSurfaceContainerLow.ignoresSafeArea()
                }
            }
    }
}

private struct POSLockScreenOverlayModifier: ViewModifier {
    @Environment(\.posAccessSession) private var session
    @Environment(\.posPINRecovery) private var recovery

    func body(content: Content) -> some View {
        POSLockScreenOverlay(session: session, recovery: recovery) {
            content
        }
    }
}

extension View {
    func posLockScreenOverlay() -> some View {
        modifier(POSLockScreenOverlayModifier())
    }
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
