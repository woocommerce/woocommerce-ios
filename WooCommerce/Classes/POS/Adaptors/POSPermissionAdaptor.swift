import Foundation
import PointOfSale
import Yosemite
import enum Experiments.FeatureFlag

/// Factory for the POS permission provider used by the M1 server-side design.
///
/// When the `pointOfSaleStaff` feature flag is on, returns the real provider that
/// fetches `GET /wc-pos/v1/staff` and validates PINs locally against the cached
/// PBKDF2 hashes. When off, returns an empty provider that allows every capability
/// so callers don't need to branch on flag state.
struct POSPermissionAdaptor {
    static func createProvider(
        siteID: Int64,
        userID: Int64,
        displayName: String,
        stores: StoresManager = ServiceLocator.stores
    ) -> POSPermissionProviding {
        let featureFlagService = ServiceLocator.featureFlagService

        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleStaff) else {
            return EmptyPOSPermissionAdaptor()
        }

        return POSPermissionProvider(
            appAccountUserID: userID,
            appAccountDisplayName: displayName,
            fetchStaffRemote: {
                try await withCheckedThrowingContinuation { continuation in
                    let action = POSStaffAction.fetchStaff(siteID: siteID) { result in
                        switch result {
                        case .success(let members):
                            continuation.resume(returning: members)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    Task { @MainActor in
                        stores.dispatch(action)
                    }
                }
            }
        )
    }
}

/// Empty provider used when the POS staff feature flag is off. Reports the device
/// admin as having every capability so call-site gates effectively no-op.
private final class EmptyPOSPermissionAdaptor: POSPermissionProviding {
    var currentOperator: PointOfSale.POSOperator? { nil }
    var isLocked: Bool { false }
    var hasAnyPINs: Bool { false }
    var autoLockTimeoutSeconds: Int { 0 }
    func hasCapability(_ capability: String) -> Bool { true }
    func checkPermission(_ capability: String) -> PointOfSale.POSPermissionResult { .allowed }
    func requestManagerApproval(managerPIN: String, for capability: String) async throws -> PointOfSale.POSOperator {
        PointOfSale.POSOperator(userID: 0, displayName: "", role: "", capabilities: [], isAppAccountHolder: false)
    }
    func signIn(_ posOperator: PointOfSale.POSOperator) {}
    func lock() {}
    func resetInactivityTimer() {}
}
