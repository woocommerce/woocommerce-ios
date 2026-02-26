import Foundation
import Yosemite

enum SetupStep: Int, CaseIterable {
    case checkPlugin = 0
    case connect = 1
    case enablePush = 2
}

@MainActor
protocol WPComConnectionSetupHandlerDelegate: AnyObject {
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status)
    func setupDidComplete()
}

@MainActor
protocol WPComConnectionSetupHandlerProtocol: AnyObject {
    var delegate: WPComConnectionSetupHandlerDelegate? { get set }
    func start()
    func retry()
    func cancel()
}

/// Stub implementation for the handler protocol.
/// The full implementation will be added in a follow-up PR.
@MainActor
final class WPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private var currentStep: SetupStep?

    private let siteURL: String
    private let siteAlreadyConnected: Bool
    private let stores: StoresManager
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol
    private let pushNotesManager: PushNotesManager

    init(siteID: Int64,
         siteURL: String,
         siteAlreadyConnected: Bool,
         stores: StoresManager = ServiceLocator.stores,
         jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteURL = siteURL
        self.siteAlreadyConnected = siteAlreadyConnected
        self.stores = stores
        self.jetpackConnectionService = jetpackConnectionService
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
        self.pushNotesManager = pushNotesManager
    }

    func start() {
        startPluginVersionCheck()
    }

    func retry() {
        switch currentStep {
        case .connect:
            startJetpackConnection()
        case .checkPlugin:
            startPluginVersionCheck()
        case .enablePush:
            startPushRegistration()
        case .none:
            start()
        }
    }

    func cancel() {
        // TODO: Implement in follow-up PR
    }
}

private extension WPComConnectionSetupHandler {
    func startJetpackConnection() {
        currentStep = .connect
        Task { @MainActor in
            do {
                delegate?.stepDidUpdate(.connect, status: .running)
                try await jetpackConnectionService.establishSiteConnection(siteURL: siteURL)
                delegate?.stepDidUpdate(.connect, status: .success)
                startPushRegistration()
            } catch {
                didFailConnection(with: error)
            }
        }

    }

    func didFailConnection(with error: Error) {
        DDLogError("⛔️ WPCom connection fails: \(error)")
        delegate?.stepDidUpdate(.connect, status: .failure(error: .generic(reason: Localization.ConnectionStep.genericError)))
    }

    func startPluginVersionCheck() {
        currentStep = .checkPlugin
        Task {
            do {
                delegate?.stepDidUpdate(.checkPlugin, status: .running)
                let result = try await pluginVersionChecker.checkCompatibility()
                switch result {
                case .compatible:
                    delegate?.stepDidUpdate(.checkPlugin, status: .success)
                    if !siteAlreadyConnected {
                        startJetpackConnection()
                    } else {
                        delegate?.stepDidUpdate(.connect, status: .success)
                        startPushRegistration()
                    }
                case .incompatible(let currentVersion, _):
                    delegate?.stepDidUpdate(.checkPlugin, status: .failure(error: .outdatedPlugin(version: currentVersion)))
                }
            } catch {
                DDLogError("⛔️ Plugin version check failed: \(error)")
                delegate?.stepDidUpdate(.checkPlugin, status: .failure(error: .generic(reason: Localization.PluginCheckStep.genericError)))
            }
        }
    }
}

private extension WPComConnectionSetupHandler {
    func startPushRegistration() {
        currentStep = .enablePush
        delegate?.stepDidUpdate(.enablePush, status: .running)
        Task { @MainActor in
            do {
                let _ = try await pushNotesManager.registerDeviceAndWaitForTokenAcceptance()
                delegate?.stepDidUpdate(.enablePush, status: .success)
                delegate?.setupDidComplete()
            } catch {
                DDLogError("⛔️ Push notification registration failed: \(error)")
                delegate?.stepDidUpdate(.enablePush, status: .failure(error: .generic(reason: Localization.PushStep.genericError)))
            }
        }
    }
}

private extension WPComConnectionSetupHandler {
    enum Constants {
        static let accountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
        static let siteConnectionURLFormat = "%@/wp-admin/admin.php?page=jetpack"
    }

    enum Localization {
        enum PluginCheckStep {
            static let genericError = NSLocalizedString(
                "wpcomConnectionSetupHandler.PluginCheckStep.genericError",
                value: "There was an error checking the version of WooCommerce plugin on your store. " +
                "Please try again or contact support if this error continues.",
                comment: "Generic error message when the plugin check step fails during push notification setup"
            )
        }
        enum PushStep {
            static let genericError = NSLocalizedString(
                "wpcomConnectionSetupHandler.PushStep.genericError",
                value: "There was an error enabling push notifications. Please try again or contact support if this error continues.",
                comment: "Error message when push notification registration fails during setup"
            )
        }
        enum ConnectionStep {
            static let genericError = NSLocalizedString(
                "wpcomConnectionSetupHandler.ConnectionStep.genericError",
                value: "There was an error completing your request. Please try again or contact support if this error continues.",
                comment: "Generic error message when the connection step fails during push notification setup"
            )
            static let canceled = NSLocalizedString(
                "wpcomConnectionSetupHandler.ConnectionStep.canceled",
                value: "Connection canceled.",
                comment: "Error message when the connection step is canceled during push notification setup"
            )
        }

    }
}
