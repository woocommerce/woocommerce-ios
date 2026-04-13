import Foundation
import PointOfSale
import Yosemite
import enum Experiments.FeatureFlag

/// Factory that creates the correct POS permission provider based on feature flags.
struct POSPermissionAdaptor {
    static func createProvider(
        siteID: Int64,
        userID: Int64,
        displayName: String,
        stores: StoresManager = ServiceLocator.stores
    ) -> POSPermissionProviding {
        let featureFlagService = ServiceLocator.featureFlagService

        if featureFlagService.isFeatureFlagEnabled(.pointOfSaleRemoteRoles) {
            let siteURL = stores.sessionManager.defaultSite?.url ?? ""
            let provider = RemotePOSPermissionProvider(
                approvalService: RemotePOSApprovalService(siteID: siteID, stores: stores),
                authenticatePINRemote: { pin, registerID in
                    try await withCheckedThrowingContinuation { continuation in
                        let action = POSAuthAction.authenticatePIN(
                            siteID: siteID,
                            pin: pin,
                            registerID: registerID
                        ) { result in
                            switch result {
                            case .success(let networkResult):
                                let response = POSPINAuthResponse(
                                    userID: networkResult.userID,
                                    userLogin: networkResult.userLogin,
                                    displayName: networkResult.displayName,
                                    role: networkResult.role,
                                    capabilities: networkResult.capabilities,
                                    applicationPassword: networkResult.applicationPassword,
                                    applicationPasswordUUID: networkResult.applicationPasswordUUID,
                                    sessionExpires: networkResult.sessionExpires,
                                    idleTimeoutSeconds: networkResult.idleTimeoutSeconds
                                )
                                continuation.resume(returning: response)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                        Task { @MainActor in
                            stores.dispatch(action)
                        }
                    }
                },
                appAccountUserID: userID
            )
            provider.onAuthenticated = { [weak stores] response in
                stores?.overridePOSCredentials(
                    username: response.userLogin,
                    applicationPassword: response.applicationPassword,
                    siteAddress: siteURL
                )
            }
            provider.onLock = { [weak stores] in
                stores?.revertPOSCredentialOverride()
            }
            return provider
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

private final class EmptyPOSPermissionAdaptor: POSPermissionProviding {
    var currentOperator: PointOfSale.POSOperator? { nil }
    var isLocked: Bool { false }
    var hasAnyPINs: Bool { false }
    var autoLockTimeoutSeconds: Int { 0 }
    func checkPermission(_ capability: String) -> PointOfSale.POSPermissionResult { .allowed }
    func hasCapability(_ capability: String) -> Bool { true }
    func requestManagerApproval(managerPIN: String, for capability: String, orderID: Int64?) async throws -> String? { nil }
    func signIn(_ posOperator: PointOfSale.POSOperator) {}
    func lock() {}
    func resetInactivityTimer() {}
}
