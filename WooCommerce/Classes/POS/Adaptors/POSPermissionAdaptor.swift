import Foundation
import PointOfSale
import enum Experiments.FeatureFlag

/// Factory that creates the correct POS permission provider based on feature flags.
struct POSPermissionAdaptor {
    static func createProvider(
        siteID: Int64,
        userID: Int64,
        displayName: String
    ) -> POSPermissionProviding {
        let featureFlagService = ServiceLocator.featureFlagService

        if featureFlagService.isFeatureFlagEnabled(.pointOfSaleRemoteRoles) {
            return RemotePOSPermissionProvider(
                approvalService: PlaceholderApprovalService(),
                authenticatePINRemote: { _, _ in
                    throw NSError(domain: "POSAuth", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Remote auth not yet configured"])
                },
                appAccountUserID: userID
            )
        } else if featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalRoles) {
            return LocalPOSPermissionProvider(
                pinService: POSPINService(),
                appAccountUserID: userID,
                appAccountDisplayName: displayName
            )
        } else {
            return EmptyPOSPermissionAdaptor()
        }
    }
}

private struct PlaceholderApprovalService: POSApprovalServiceProtocol {
    func requestApproval(pin: String, action: String, context: [String: Int64]) async throws -> String {
        throw NSError(domain: "POSAuth", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Approval service not yet configured"])
    }
}

private final class EmptyPOSPermissionAdaptor: POSPermissionProviding {
    var currentOperator: PointOfSale.POSOperator? { nil }
    var isLocked: Bool { false }
    func checkPermission(_ capability: String) -> PointOfSale.POSPermissionResult { .allowed }
    func hasCapability(_ capability: String) -> Bool { true }
    func signIn(_ posOperator: PointOfSale.POSOperator) {}
    func lock() {}
}
