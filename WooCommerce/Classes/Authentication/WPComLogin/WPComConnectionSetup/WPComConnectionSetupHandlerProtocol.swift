import Foundation
import Yosemite

enum SetupStep: Int, CaseIterable {
    case connect = 0
    case checkPlugin = 1
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

    private let siteURL: String
    private let credentials: Credentials?
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol

    init(siteID: Int64,
         siteURL: String,
         credentials: Credentials?,
         jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil) {
        self.siteURL = siteURL
        self.credentials = credentials
        self.jetpackConnectionService = jetpackConnectionService
        self.pluginVersionChecker = pluginVersionChecker ?? PluginVersionChecker(
            siteID: siteID,
            pluginPath: Constants.wooPluginPath,
            minimumVersion: Constants.minimumWooVersion
        )
    }

    func start() {
        Task { @MainActor in
            /// Step 1 (optional): check Jetpack connection
            if let credentials {
                do {
                    delegate?.stepDidUpdate(.connect, status: .running)
                    try await checkJetpackConnection(with: credentials)
                    delegate?.stepDidUpdate(.connect, status: .success)
                } catch {
                    delegate?.stepDidUpdate(.connect, status: .failure(reason: error.localizedDescription)) // TODO: update msg
                }
            }

            /// Step 2: TODO: Check plugin version

            /// Step 3: Enable push notification
            /// TODO: Inject PushNotificationManager to trigger Woo PN registration
        }
    }

    func retry() {
        // TODO: Implement in follow-up PR
    }

    func cancel() {
        // TODO: Implement in follow-up PR
    }
}

private extension WPComConnectionSetupHandler {
    @MainActor
    func checkJetpackConnection(with credentials: Credentials) async throws {
        let result = try await jetpackConnectionService.evaluateAndConnect(siteURL: siteURL, credentials: credentials)
    }
}

private extension WPComConnectionSetupHandler {
    enum Constants {
        static let wooPluginPath = "woocommerce/woocommerce.php"
        static let minimumWooVersion = "10.5.3" // This is for testing
    }
}
