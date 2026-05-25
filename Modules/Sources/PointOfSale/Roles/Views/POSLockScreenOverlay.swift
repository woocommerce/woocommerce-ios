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
#Preview("Overlay locked") {
    POSLockScreenOverlay(
        session: MockPOSAccessSession(
            currentOperator: nil,
            isLocked: true,
            hasAnyPINs: true
        )
    ) {
        Color.posSurface
    }
}

#Preview("Overlay unlocked") {
    POSLockScreenOverlay(
        session: MockPOSAccessSession(
            currentOperator: POSOperator(displayName: "Maya", role: "Manager", capabilities: Set(POSCapability.allCases.map(\.rawValue))),
            isLocked: false,
            hasAnyPINs: true
        )
    ) {
        Color.posSurface
    }
}

#Preview("Interactive unlock") {
    POSLockScreenOverlay(
        session: MockPOSAccessSession(
            currentOperator: nil,
            isLocked: true,
            hasAnyPINs: true
        )
    ) {
        Text("Unlocked POS content")
            .font(.posHeadingBold)
            .foregroundStyle(Color.posOnSurface)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.posSurface)
    }
}
#endif
