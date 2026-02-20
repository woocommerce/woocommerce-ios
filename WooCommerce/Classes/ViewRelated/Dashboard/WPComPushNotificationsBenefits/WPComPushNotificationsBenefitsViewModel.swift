import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics

@MainActor
@Observable
final class WPComPushNotificationsBenefitsViewModel {

    enum Variant: Equatable {
        case connect
        case pluginUpdate(currentVersion: String)
    }

    private(set) var variant: Variant = .connect
    private(set) var isCheckingPlugin: Bool = false

    private let analytics: Analytics
    private let onDismiss: () -> Void
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol

    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(siteID: Int64,
         jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil,
         analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void) {
        self.jetpackConnectionService = jetpackConnectionService
        self.analytics = analytics
        self.onDismiss = onDismiss
        let minimumVersion: String = {
        #if DEBUG
            if let override: String = UserDefaults.standard[.debugMinWooVersionForSelfDrivenPushNotifications],
               !override.isEmpty {
                return override
            }
        #endif
            return WooPluginRequirements.minimumVersion
        }()
        self.pluginVersionChecker = pluginVersionChecker ?? PluginVersionChecker(
            siteID: siteID,
            pluginPath: WooPluginRequirements.pluginPath,
            minimumVersion: minimumVersion
        )
    }

    func updateCoordinator(_ coordinator: WooPushNotificationSetupCoordinator) {
        self.pushNotificationSetupCoordinator = coordinator
    }

    func onAppear() {
        // TODO: Track modal shown event
    }

    /// Fetches Jetpack connection data to determine whether the site is connected,
    /// then checks the WooCommerce plugin version if Jetpack is connected.
    func determineSetupVariant() async {
        isCheckingPlugin = true
        do {
            let connectionData = try await jetpackConnectionService.fetchConnectionData()
            /// only site-connection is required for Woo PN
            /// ref: C03L1NF1EA3-slack-p1771522327596419
            if connectionData.isRegistered == true {
                await checkWooPluginVersion()
            } else {
                variant = .connect
            }
        } catch {
            DDLogError("⛔️ Failed to fetch Jetpack connection data: \(error)")
            variant = .connect
        }
        isCheckingPlugin = false
    }

    func continueTapped() {
        // TODO: Track continue tapped event
        switch variant {
        case .connect:
            pushNotificationSetupCoordinator?.start()
        case .pluginUpdate(let currentVersion):
            pushNotificationSetupCoordinator?.showPluginUpdateSetup(pluginVersion: currentVersion)
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

// MARK: - Plugin version check

private extension WPComPushNotificationsBenefitsViewModel {
    func checkWooPluginVersion() async {
        do {
            let result = try await pluginVersionChecker.checkCompatibility()
            if case .incompatible(let currentVersion, _) = result {
                variant = .pluginUpdate(currentVersion: currentVersion)
            } else {
                // TODO: add error handling for unexpected case
                variant = .connect
            }
        } catch {
            DDLogError("⛔️ Plugin version check failed: \(error)")
            // TODO: add error handling for unexpected case
            variant = .connect
        }
    }
}
