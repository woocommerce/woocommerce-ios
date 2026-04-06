import CocoaLumberjackSwift
import Foundation
import Yosemite
import class Networking.AlamofireNetwork
import enum Networking.NetworkError

enum JetpackConnectionOutcome {
    /// The site was already connected with this email.
    case alreadyConnected(email: String)
    /// The connection was newly established, verified with this email.
    case connected(email: String)
    /// The site uses an outdated Jetpack version; consumer should use web view.
    case webViewRequired
}

enum JetpackConnectionServiceError: Error, CustomNSError {
    case verificationFailed

    static let errorDomain = "JetpackConnectionService"
    var errorCode: Int {
        switch self {
        case .verificationFailed: return 99
        }
    }
}

/// Encapsulates the full Jetpack/WPCom connection decision tree:
/// fetch data → decide native/webview → connect → verify.
/// Ref: pe5sF9-401-p2
protocol JetpackConnectionServiceProtocol {
    /// Establish site-only connection - minimum requirement for self-driven push notifications.
    func establishSiteConnection(siteURL: String) async throws

    /// Full decision tree: evaluate connection data, perform native connection if possible,
    /// or return `.webViewRequired` if the site uses outdated Jetpack.
    func evaluateAndConnect(siteURL: String,
                            credentials: Credentials) async throws -> JetpackConnectionOutcome

    /// Verify a connected WPCom user exists.
    /// Retries internally. Returns the connected email or throws.
    func verifyConnection() async throws -> String

    /// Fetches the URL used for setting up Jetpack connection via web view.
    func fetchJetpackConnectionURL(authenticatedWithWPCom: Bool) async throws -> URL

    /// Fetches the current Jetpack connection data for the site.
    func fetchConnectionData() async throws -> JetpackConnectionData
}

final class JetpackConnectionService: JetpackConnectionServiceProtocol {
    private let siteID: Int64
    private let stores: StoresManager
    private let maxRetryCount: Int
    private let delayBeforeRetry: TimeInterval

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         maxRetryCount: Int = 2,
         delayBeforeRetry: TimeInterval = 0.5) {
        self.siteID = siteID
        self.stores = stores
        self.maxRetryCount = maxRetryCount
        self.delayBeforeRetry = delayBeforeRetry
    }

    func establishSiteConnection(siteURL: String) async throws {
        _ = try await dispatch(JetpackConnectionAction.registerSite)
    }

    func evaluateAndConnect(siteURL: String,
                            credentials: Credentials) async throws -> JetpackConnectionOutcome {
        let data: JetpackConnectionData
        do {
            data = try await fetchConnectionData()
        } catch {
            DDLogError("⛔️ Error fetching Jetpack connection data: \(error)")
            throw error
        }

        // Branch A: Already connected
        if let email = data.currentUser.wpcomUser?.email {
            return .alreadyConnected(email: email)
        }

        // Branch B: isRegistered available (Jetpack >= 14.4) → native path
        if data.isRegistered != nil {
            try await nativeConnect(with: data, siteURL: siteURL, credentials: credentials)
            let email = try await verifyConnection()
            return .connected(email: email)
        }

        // Branch C: isRegistered == nil (Jetpack < 14.4)
        let pluginResult = await checkJetpackPluginInstalled()
        switch pluginResult {
        case .installed:
            return .webViewRequired
        case .notFound:
            // Jetpack CP plugin: infer isRegistered from connectionOwner
            let inferred = data.copy(isRegistered: data.connectionOwner != nil)
            try await nativeConnect(with: inferred, siteURL: siteURL, credentials: credentials)
            let email = try await verifyConnection()
            return .connected(email: email)
        case .error(let error):
            throw error
        }
    }

    func fetchJetpackConnectionURL(authenticatedWithWPCom: Bool) async throws -> URL {
        try await dispatch { completion in
            JetpackConnectionAction.fetchJetpackConnectionURL(
                authenticatedWithWPCom: authenticatedWithWPCom,
                completion: completion
            )
        }
    }

    func verifyConnection() async throws -> String {
        for attempt in 0...maxRetryCount {
            do {
                let data = try await fetchConnectionData()
                if let email = data.currentUser.wpcomUser?.email {
                    return email
                }
            } catch {
                DDLogError("⛔️ Error verifying Jetpack connection (attempt \(attempt + 1)): \(error)")
                if attempt == maxRetryCount { throw error }
            }
            if attempt < maxRetryCount {
                try await Task.sleep(nanoseconds: UInt64(delayBeforeRetry * 1_000_000_000))
            }
        }
        DDLogWarn("⚠️ Cannot find connected WPCom user after \(maxRetryCount + 1) attempts")
        throw JetpackConnectionServiceError.verificationFailed
    }

    func fetchConnectionData() async throws -> JetpackConnectionData {
        try await dispatch { completion in
            JetpackConnectionAction.fetchJetpackConnectionData(siteID: self.siteID, completion: completion)
        }
    }
}

private extension JetpackConnectionService {
    enum PluginCheckResult {
        case installed
        case notFound
        case error(Error)
    }

    func nativeConnect(with connectionData: JetpackConnectionData,
                       siteURL: String,
                       credentials: Credentials) async throws {
        let blogID: Int64
        if connectionData.isRegistered == true, let existingBlogID = connectionData.blogID {
            blogID = existingBlogID
        } else {
            blogID = try await dispatch(JetpackConnectionAction.registerSite)
        }

        let provisionResponse: JetpackConnectionProvisionResponse =
            try await dispatch(JetpackConnectionAction.provisionConnection)

        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil)
        try await dispatch { completion in
            JetpackConnectionAction.finalizeConnection(
                siteID: blogID,
                siteURL: siteURL,
                provisionResponse: provisionResponse,
                network: network,
                completion: completion
            )
        }
    }

    func checkJetpackPluginInstalled() async -> PluginCheckResult {
        do {
            let _: SitePlugin = try await dispatch { completion in
                JetpackConnectionAction.retrieveJetpackPluginDetails(siteID: self.siteID, completion: completion)
            }
            return .installed
        } catch {
            let code = (error as? NetworkError)?.responseCode ?? (error as NSError).code
            if code == 404 {
                return .notFound
            }
            return .error(error)
        }
    }

    func dispatch<T>(_ actionBuilder: @escaping (@escaping (Result<T, Error>) -> Void) -> Action) async throws -> T {
        let stores = self.stores
        return try await withCheckedThrowingContinuation { continuation in
            let action = actionBuilder { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
