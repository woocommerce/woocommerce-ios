import Foundation
import Yosemite

/// Protocol for checking Blaze eligibility for easier unit testing.
protocol BlazeEligibilityCheckerProtocol {
    @MainActor
    func isSiteEligible() async -> Bool

    @MainActor
    func isProductEligible(product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool
}

/// Checks for Blaze eligibility for a site and its products.
final class BlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Checks if the site is eligible for Blaze.
    /// - Returns: Whether the site is eligible for Blaze.
    func isSiteEligible() async -> Bool {
        await checkSiteEligibility()
    }

    /// Checks if the product is eligible for Blaze.
    /// - Parameter product: The product to check for Blaze eligibility.
    /// - Parameter isPasswordProtected: Whether the product is password protected.
    /// - Returns: Whether the product is eligible for Blaze.
    func isProductEligible(product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        guard product.status == .published && isPasswordProtected == false else {
            return false
        }
        return await checkSiteEligibility()
    }
}

private extension BlazeEligibilityChecker {
    @MainActor
    func checkSiteEligibility() async -> Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }
        guard site.isAdmin && site.canBlaze else {
            return false
        }
        guard stores.isAuthenticatedWithoutWPCom == false else {
            return false
        }
        guard await isRemoteFeatureFlagEnabled(.blaze) else {
            return false
        }
        return true
    }
}

private extension BlazeEligibilityChecker {
    @MainActor
    func isRemoteFeatureFlagEnabled(_ remoteFeatureFlag: RemoteFeatureFlag) async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(remoteFeatureFlag, defaultValue: false) { isEnabled in
                continuation.resume(returning: isEnabled)
            })
        }
    }
}
