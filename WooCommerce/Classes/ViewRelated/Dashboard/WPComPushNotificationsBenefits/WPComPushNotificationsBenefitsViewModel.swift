import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics

@MainActor
@Observable
final class WPComPushNotificationsBenefitsViewModel {

    enum Variant {
        case connect
        case pluginUpdate
    }

    private(set) var variant: Variant = .connect
    private(set) var pluginVersion: String = ""
    private(set) var isCheckingPlugin: Bool = false

    private let analytics: Analytics
    private let onDismiss: () -> Void
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol?

    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void) {
        self.jetpackConnectionService = jetpackConnectionService
        self.analytics = analytics
        self.onDismiss = onDismiss
        self.pluginVersionChecker = pluginVersionChecker ?? {
            guard let site = stores.sessionManager.defaultSite else {
                return nil
            }
            return PluginVersionChecker(
                siteID: site.siteID,
                pluginPath: WooPluginRequirements.pluginPath,
                minimumVersion: WooPluginRequirements.minimumVersion
            )
        }()
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
            if connectionData.currentUser.isConnected {
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

// MARK: - Plugin version check

private extension WPComPushNotificationsBenefitsViewModel {
    func checkWooPluginVersion() async {
        guard let pluginVersionChecker else {
            variant = .connect
            return
        }

        do {
            let result = try await pluginVersionChecker.checkCompatibility()
            if case .incompatible(let currentVersion, _) = result {
                variant = .pluginUpdate
                pluginVersion = currentVersion
            } else {
                variant = .connect
            }
        } catch {
            DDLogError("⛔️ Plugin version check failed: \(error)")
            variant = .connect
        }
    }
}
