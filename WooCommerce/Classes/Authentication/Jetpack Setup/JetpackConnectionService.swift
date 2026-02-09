import Foundation
import Yosemite
import class Networking.AlamofireNetwork

enum JetpackConnectionServiceError: Error {
    case verificationFailed
}

/// Performs the native Jetpack/WPCom connection sequence:
/// register (if needed) → provision → finalize → verify.
protocol JetpackConnectionServiceProtocol {
    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws -> String

    func verifyConnection() async throws -> String
}

final class JetpackConnectionService: JetpackConnectionServiceProtocol {
    private let stores: StoresManager
    private let maxRetryCount: Int
    private let retryDelay: TimeInterval

    init(stores: StoresManager = ServiceLocator.stores,
         maxRetryCount: Int = 2,
         retryDelay: TimeInterval = 0.5) {
        self.stores = stores
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
    }

    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws -> String {
        // 1. Determine blogID — register if needed
        let blogID: Int64
        if connectionData.isRegistered == true, let existingBlogID = connectionData.blogID {
            blogID = existingBlogID
        } else {
            blogID = try await registerSite()
        }

        // 2. Provision
        let provisionResponse = try await provisionConnection()

        // 3. Finalize
        try await finalizeConnection(blogID: blogID,
                                     siteURL: siteURL,
                                     provisionResponse: provisionResponse,
                                     credentials: credentials)

        // 4. Verify with retry
        return try await verifyConnection()
    }

    func verifyConnection() async throws -> String {
        try await verifyConnection(retryCount: 0)
    }
}

// MARK: - Private steps
private extension JetpackConnectionService {
    func registerSite() async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(JetpackConnectionAction.registerSite { result in
                continuation.resume(with: result)
            })
        }
    }

    func provisionConnection() async throws -> JetpackConnectionProvisionResponse {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(JetpackConnectionAction.provisionConnection { result in
                continuation.resume(with: result)
            })
        }
    }

    func finalizeConnection(blogID: Int64,
                            siteURL: String,
                            provisionResponse: JetpackConnectionProvisionResponse,
                            credentials: Credentials) async throws {
        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(JetpackConnectionAction.finalizeConnection(
                siteID: blogID,
                siteURL: siteURL,
                provisionResponse: provisionResponse,
                network: network
            ) { result in
                continuation.resume(with: result)
            })
        }
    }

    func fetchConnectionData() async throws -> JetpackConnectionData {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(JetpackConnectionAction.fetchJetpackConnectionData { result in
                continuation.resume(with: result)
            })
        }
    }

    func verifyConnection(retryCount: Int) async throws -> String {
        let data: JetpackConnectionData
        do {
            data = try await fetchConnectionData()
        } catch {
            if retryCount < maxRetryCount {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                return try await verifyConnection(retryCount: retryCount + 1)
            }
            throw error
        }

        if let email = data.currentUser.wpcomUser?.email {
            DDLogDebug("📱 JetpackConnectionService: Successfully connected (\(email))")
            return email
        }

        DDLogWarn("⚠️ JetpackConnectionService: Cannot find connected WPCom user")
        if retryCount < maxRetryCount {
            try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            return try await verifyConnection(retryCount: retryCount + 1)
        }

        throw JetpackConnectionServiceError.verificationFailed
    }
}
