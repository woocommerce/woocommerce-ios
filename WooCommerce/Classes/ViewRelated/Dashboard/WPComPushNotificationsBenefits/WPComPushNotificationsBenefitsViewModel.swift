import Foundation
import protocol WooFoundation.Analytics

@MainActor
final class WPComPushNotificationsBenefitsViewModel {

    enum Variant {
        case connect
        case pluginUpdate
    }

    let variant: Variant
    let pluginVersion: String

    private let analytics: Analytics
    private let onDismiss: () -> Void

    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(variant: Variant = .connect,
         pluginVersion: String = "",
         analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void) {
        self.variant = variant
        self.pluginVersion = pluginVersion
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
        switch variant {
        case .connect:
            pushNotificationSetupCoordinator?.start()
        case .pluginUpdate:
            pushNotificationSetupCoordinator?.showPluginUpdateSetup(pluginVersion: pluginVersion)
        }
    }

    func notNowTapped() {
        // TODO: Track not now tapped event
        onDismiss()
    }

    func whatIsWPComTapped() {
        // TODO: Track link tapped event
    }
}
