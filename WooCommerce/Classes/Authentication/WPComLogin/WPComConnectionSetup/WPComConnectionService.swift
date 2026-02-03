import Foundation
import Yosemite
import class Networking.AlamofireNetwork

protocol WPComConnectionServiceProtocol {
    func connect() async throws
}

/**
 Handles the WordPress.com connection flow using JetpackConnectionAction.

 The connection process:
 1. Check if already connected (early exit if wpcomUser exists)
 2. Register site if not registered
 3. Provision connection
 4. Finalize connection with WPCom credentials
 5. Verify connection succeeded
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
        let connectionData = try await fetchConnectionData()

        if connectionData.currentUser.wpcomUser != nil {
            DDLogDebug("📱 WPCom connection: Site already connected")
            return
        }

        let blogID: Int64
        if let existingBlogID = connectionData.blogID, connectionData.isRegistered == true {
            blogID = existingBlogID
        } else {
            blogID = try await registerSite()
        }

        let provisionResponse = try await provisionConnection()
        try await finalizeConnection(blogID: blogID, provisionResponse: provisionResponse)

        let verificationData = try await fetchConnectionData()
        guard verificationData.currentUser.wpcomUser != nil else {
            throw WPComConnectionError.verificationFailed
        }

        DDLogDebug("📱 WPCom connection: Successfully connected")
    }
}

private extension WPComConnectionService {
    func fetchConnectionData() async throws -> JetpackConnectionData {
        let stores = self.stores
        return try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.fetchJetpackConnectionData { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func registerSite() async throws -> Int64 {
        let stores = self.stores
        return try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.registerSite { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func provisionConnection() async throws -> JetpackConnectionProvisionResponse {
        let stores = self.stores
        return try await withCheckedThrowingContinuation { continuation in
            let action = JetpackConnectionAction.provisionConnection { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func finalizeConnection(blogID: Int64, provisionResponse: JetpackConnectionProvisionResponse) async throws {
        let stores = self.stores
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
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

enum WPComConnectionError: Error {
    case verificationFailed
}
