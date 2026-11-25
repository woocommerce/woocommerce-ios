import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    private let session: POSAccessSession

    private let locksInBackground: () -> Bool

    init(session: POSAccessSession, locksInBackground: @escaping () -> Bool, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.session = session
        self.locksInBackground = locksInBackground
    }

    var body: some View {
        content
            .disabled(session.isLocked)
            .accessibilityHidden(session.isLocked)
            // Keep POS mounted; hide its covered rendering without animating the lock-state change.
            .opacity(session.isLocked ? 0 : 1)
            .animation(nil, value: session.isLocked)
            .background(POSLockPresentationHost(session: session,
                                                 locksInBackground: locksInBackground,
                                                 lockContent: POSLockScreenView(session: session).id(ObjectIdentifier(session))))
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
    let locksInBackground: () -> Bool

    func body(content: Content) -> some View {
        POSLockScreenOverlay(session: session, locksInBackground: locksInBackground) {
            content
        }
    }
}

extension View {
    func posLockScreenOverlay(locksInBackground: @escaping () -> Bool = { false }) -> some View {
        modifier(POSLockScreenOverlayModifier(locksInBackground: locksInBackground))
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
