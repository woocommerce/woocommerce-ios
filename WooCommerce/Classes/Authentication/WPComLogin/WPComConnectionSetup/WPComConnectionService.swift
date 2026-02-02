import Foundation
import Yosemite
import class Networking.AlamofireNetwork

/// Protocol for WPCom connection operations
protocol WPComConnectionServiceProtocol {
    /// Connects the site to WordPress.com
    /// Returns successfully if already connected or connection succeeds
    /// Throws on API failures
    func connect() async throws
}

/// Handles the WordPress.com connection flow using existing JetpackConnectionAction.
/// This service encapsulates the multi-step connection process:
/// 1. Check if already connected
/// 2. Register site (if needed)
/// 3. Provision connection
/// 4. Finalize connection with WPCom credentials
/// 5. Verify connection succeeded
final class WPComConnectionService: WPComConnectionServiceProtocol {
    private let siteURL: String
    private let wpcomCredentials: Credentials
    private let stores: StoresManager

    init(siteURL: String, wpcomCredentials: Credentials, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.wpcomCredentials = wpcomCredentials
        self.stores = stores
    }

    func connect() async throws {
        // Step 1: Check if already connected
        let connectionData = try await fetchConnectionData()

        // If already connected (has wpcomUser), we're done
        if connectionData.currentUser.wpcomUser != nil {
            DDLogDebug("📱 WPCom connection: Site already connected")
            return
        }

        // Step 2: Register site if not registered
        let blogID: Int64
        if let existingBlogID = connectionData.blogID, connectionData.isRegistered == true {
            blogID = existingBlogID
        } else {
            blogID = try await registerSite()
        }

        // Step 3: Provision connection
        let provisionResponse = try await provisionConnection()

        // Step 4: Finalize connection with WPCom credentials
        try await finalizeConnection(blogID: blogID, provisionResponse: provisionResponse)

        // Step 5: Verify connection succeeded
        let verificationData = try await fetchConnectionData()
        guard verificationData.currentUser.wpcomUser != nil else {
            throw WPComConnectionError.verificationFailed
        }

        DDLogDebug("📱 WPCom connection: Successfully connected")
    }
}

// MARK: - Private Helpers
private extension WPComConnectionService {

    func fetchConnectionData() async throws -> JetpackConnectionData {
        try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.fetchJetpackConnectionData { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    func registerSite() async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.registerSite { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    func provisionConnection() async throws -> JetpackConnectionProvisionResponse {
        try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.provisionConnection { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    func finalizeConnection(blogID: Int64, provisionResponse: JetpackConnectionProvisionResponse) async throws {
        let network = AlamofireNetwork(credentials: wpcomCredentials, selectedSite: nil, appPasswordSupportState: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let action = JetpackConnectionAction.finalizeConnection(
                siteID: blogID,
                siteURL: siteURL,
                provisionResponse: provisionResponse,
                network: network
            ) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}

// MARK: - Error Types
enum WPComConnectionError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return NSLocalizedString(
                "wpComConnectionError.verificationFailed",
                value: "Failed to verify WordPress.com connection",
                comment: "Error message when WPCom connection verification fails"
            )
        }
    }
}
