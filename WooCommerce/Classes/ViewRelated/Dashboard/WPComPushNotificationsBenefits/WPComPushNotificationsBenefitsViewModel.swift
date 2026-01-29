import Foundation
import protocol WooFoundation.Analytics

final class WPComPushNotificationsBenefitsViewModel {

    private let analytics: Analytics
    private let onDismiss: () -> Void

    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void) {
        self.analytics = analytics
        self.onDismiss = onDismiss
    }

    func updateCoordinator(_ coordinator: WooPushNotificationSetupCoordinator) {
        self.pushNotificationSetupCoordinator = coordinator
    }

    func onAppear() {
        // TODO: Track modal shown event
    }

    func continueTapped() {
        // TODO: Track continue tapped event
        pushNotificationSetupCoordinator?.start()
    }

    func notNowTapped() {
        // TODO: Track not now tapped event
        onDismiss()
    }

    func whatIsWPComTapped() {
        // TODO: Track link tapped event
    }
}
