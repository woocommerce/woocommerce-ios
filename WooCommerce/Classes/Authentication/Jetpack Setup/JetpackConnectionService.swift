import Foundation
import Yosemite
import class Networking.AlamofireNetwork

/// Performs the native Jetpack/WPCom connection sequence:
/// register (if needed) → provision → finalize.
protocol JetpackConnectionServiceProtocol {
    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws
}

final class JetpackConnectionService: JetpackConnectionServiceProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws {
        let blogID: Int64
        if connectionData.isRegistered == true, let existingBlogID = connectionData.blogID {
            blogID = existingBlogID
        } else {
            blogID = try await dispatch(JetpackConnectionAction.registerSite)
        }

        let provisionResponse: JetpackConnectionProvisionResponse = try await dispatch(JetpackConnectionAction.provisionConnection)

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
}

private extension JetpackConnectionService {
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
