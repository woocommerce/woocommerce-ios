import Foundation
import PointOfSale
import Yosemite

/// Concrete implementation of `POSApprovalServiceProtocol` that dispatches Yosemite actions
/// to request manager approval via the backend REST API.
final class RemotePOSApprovalService: POSApprovalServiceProtocol {
    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func requestApproval(pin: String, action: String, context: [String: Int64]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let posAuthAction = POSAuthAction.requestApproval(
                siteID: siteID,
                pin: pin,
                action: action,
                context: context
            ) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.approvalToken)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            Task { @MainActor in
                stores.dispatch(posAuthAction)
            }
        }
    }
}
