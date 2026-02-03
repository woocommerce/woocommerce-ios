import Foundation
import Yosemite
import class Networking.AlamofireNetwork

protocol WPComConnectionServiceProtocol {
    func connect() async throws
}

/**
 Handles the WordPress.com connection flow using JetpackConnectionAction.
 Steps: check connection → register site → provision → finalize → verify.
 */
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
        // 1. Check if already connected
        let connectionData = try await dispatch(JetpackConnectionAction.fetchJetpackConnectionData)
        if connectionData.currentUser.wpcomUser != nil {
            DDLogDebug("📱 WPCom connection: Site already connected")
            return
        }

        // 2. Register site if needed
        let blogID: Int64
        if let existingBlogID = connectionData.blogID, connectionData.isRegistered == true {
            blogID = existingBlogID
        } else {
            blogID = try await dispatch(JetpackConnectionAction.registerSite)
        }

        // 3. Provision connection
        let provisionResponse = try await dispatch(JetpackConnectionAction.provisionConnection)

        // 4. Finalize connection with WPCom credentials
        let network = AlamofireNetwork(credentials: wpcomCredentials, selectedSite: nil, appPasswordSupportState: nil)
        let siteURL = self.siteURL
        try await dispatch { completion in
            JetpackConnectionAction.finalizeConnection(
                siteID: blogID,
                siteURL: siteURL,
                provisionResponse: provisionResponse,
                network: network,
                completion: completion
            )
        }

        // 5. Verify connection succeeded
        let verificationData = try await dispatch(JetpackConnectionAction.fetchJetpackConnectionData)
        guard verificationData.currentUser.wpcomUser != nil else {
            throw WPComConnectionError.verificationFailed
        }

        DDLogDebug("📱 WPCom connection: Successfully connected")
    }

    private func dispatch<T>(_ actionBuilder: @escaping (@escaping (Result<T, Error>) -> Void) -> Action) async throws -> T {
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

enum WPComConnectionError: Error {
    case verificationFailed
}
