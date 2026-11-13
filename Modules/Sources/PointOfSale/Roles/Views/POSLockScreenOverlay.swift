import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    private let session: POSAccessSession
    private let onLock: @MainActor () -> Void

    init(session: POSAccessSession, onLock: @escaping @MainActor () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.session = session
        self.onLock = onLock
    }

    var body: some View {
        content
            .disabled(session.isLocked)
            .accessibilityHidden(session.isLocked)
            .background(POSLockPrivacyCover(session: session).id(ObjectIdentifier(session)))
            .background(POSLockPresentationHost(session: session,
                                                 lockContent: POSLockScreenView(session: session).id(ObjectIdentifier(session)), onLock: onLock))
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
    let onLock: @MainActor () -> Void

    func body(content: Content) -> some View {
        POSLockScreenOverlay(session: session, onLock: onLock) {
            content
        }
    }
}

extension View {
    func posLockScreenOverlay(onLock: @escaping @MainActor () -> Void = {}) -> some View {
        modifier(POSLockScreenOverlayModifier(onLock: onLock))
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
