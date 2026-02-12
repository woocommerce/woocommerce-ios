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
    func setupDidRequireWebView(url: URL, siteURL: String)
}

@MainActor
protocol WPComConnectionSetupHandlerProtocol: AnyObject {
    var delegate: WPComConnectionSetupHandlerDelegate? { get set }
    func start()
    func retry()
    func cancel()
    func didAuthorizeWebViewConnection()
    func didEncounterWebViewError(code: Int?)
    func didCancelWebView()
}

/// Stub implementation for the handler protocol.
/// The full implementation will be added in a follow-up PR.
@MainActor
final class WPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private var currentStep: SetupStep?

    private let siteURL: String
    private let credentials: Credentials?
    private let stores: StoresManager
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol

    init(siteID: Int64,
         siteURL: String,
         credentials: Credentials?,
         stores: StoresManager = ServiceLocator.stores,
         jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil) {
        self.siteURL = siteURL
        self.credentials = credentials
        self.stores = stores
        self.jetpackConnectionService = jetpackConnectionService
        self.pluginVersionChecker = pluginVersionChecker ?? PluginVersionChecker(
            siteID: siteID,
            pluginPath: Constants.wooPluginPath,
            minimumVersion: Constants.minimumWooVersion
        )
    }

    func start() {
        /// Step 1 (optional): check Jetpack connection
        if credentials != nil {
            currentStep = .connect
            startJetpackConnection()
        }

        /// Step 2: TODO: Check plugin version

        /// Step 3: Enable push notification
        /// TODO: Inject PushNotificationManager to trigger Woo PN registration
    }

    func retry() {
        switch currentStep {
        case .connect:
            startJetpackConnection()
        case .checkPlugin, .enablePush, .none:
            // TODO
            break
        }
    }

    func cancel() {
        // TODO: Implement in follow-up PR
    }

    func didAuthorizeWebViewConnection() {
        Task { @MainActor in
            do {
                let _ = try await jetpackConnectionService.verifyConnection()
                delegate?.stepDidUpdate(.connect, status: .success)
                // TODO: continue to next steps
            } catch {
                delegate?.stepDidUpdate(.connect, status: .failure(reason: error.localizedDescription))
            }
        }
    }

    func didEncounterWebViewError(code: Int?) {
        let reason = code.map { "Web view error (code: \($0))" } ?? "Web view error"
        delegate?.stepDidUpdate(.connect, status: .failure(reason: reason))
    }

    func didCancelWebView() {
        delegate?.stepDidUpdate(.connect, status: .failure(reason: "Connection cancelled"))
    }
}

private extension WPComConnectionSetupHandler {
    func startJetpackConnection() {
        guard let credentials else { return }
        Task { @MainActor in
            do {
                delegate?.stepDidUpdate(.connect, status: .running)
                let completed = try await checkJetpackConnection(with: credentials)
                if completed {
                    delegate?.stepDidUpdate(.connect, status: .success)
                }
                // When `completed` is false, the web view flow has been triggered
                // and the flow will resume via didAuthorizeWebViewConnection().
            } catch {
                delegate?.stepDidUpdate(.connect, status: .failure(reason: error.localizedDescription)) // TODO: update msg
            }
        }

    }

    /// Returns `true` when the connection step completed (already connected or just connected).
    /// Returns `false` when a web view is required — the flow pauses until the web view finishes.
    @MainActor
    func checkJetpackConnection(with credentials: Credentials) async throws -> Bool {
        let result = try await jetpackConnectionService.evaluateAndConnect(siteURL: siteURL, credentials: credentials)
        switch result {
        case .alreadyConnected, .connected:
            return true
        case .webViewRequired:
            startConnectionWithWebView()
            return false
        }
    }

    @MainActor
    func startConnectionWithWebView() {
        let authenticatedWithWPCom = !stores.isAuthenticatedWithoutWPCom
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let url = try await jetpackConnectionService.fetchJetpackConnectionURL(authenticatedWithWPCom: authenticatedWithWPCom)
                let connectionURL: URL
                if url.absoluteString.hasPrefix(Constants.accountConnectionURL) {
                    connectionURL = url
                } else {
                    let fallback = String(format: Constants.siteConnectionURLFormat, self.siteURL)
                    connectionURL = URL(string: fallback) ?? url
                }
                delegate?.setupDidRequireWebView(url: connectionURL, siteURL: self.siteURL)
            } catch {
                DDLogError("⛔️ Error fetching Jetpack connection URL: \(error)")
                delegate?.stepDidUpdate(.connect, status: .failure(reason: error.localizedDescription))
            }
        }
    }
}

private extension WPComConnectionSetupHandler {
    enum Constants {
        static let wooPluginPath = "woocommerce/woocommerce.php"
        static let minimumWooVersion = "10.5.3" // This is for testing
        static let accountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
        static let siteConnectionURLFormat = "%@/wp-admin/admin.php?page=jetpack"
    }
}
