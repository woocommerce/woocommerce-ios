import Foundation
import protocol WooFoundation.Analytics

final class WPComPushNotificationsBenefitsViewModel {
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func onAppear() {
        // TODO: Track modal shown event
    }

    func continueTapped() {
        // TODO: Track continue tapped event
    }

    func notNowTapped() {
        // TODO: Track not now tapped event
        onDismiss()
    }

    func whatIsWPComTapped() {
        // TODO: Track link tapped event
    }
}
