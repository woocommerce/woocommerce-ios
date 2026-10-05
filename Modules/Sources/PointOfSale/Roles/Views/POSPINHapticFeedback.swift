import UIKit

@MainActor
struct POSPINHapticFeedback {
    func digitEntered() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func attemptFailed() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
