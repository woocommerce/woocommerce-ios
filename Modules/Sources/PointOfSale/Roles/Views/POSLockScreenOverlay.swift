import SwiftUI

struct POSLockScreenOverlay<Content: View>: View {
    private let content: Content
    private let session: POSAccessSession

    init(session: POSAccessSession, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.session = session
    }

    var body: some View {
        content
            .disabled(session.isLocked)
            .accessibilityHidden(session.isLocked)
            .background(POSLockPrivacyCover(session: session))
            .overlay {
                if session.isLocked {
                    POSLockScreenView(session: session)
                }
            }
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
