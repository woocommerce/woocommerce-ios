import Foundation
import Yosemite

/// Checks for Blaze eligibility for a site and its products.
final class BlazeEligibilityChecker {
    private let site: Site
    private let stores: StoresManager

    init(site: Site, stores: StoresManager = ServiceLocator.stores) {
        self.site = site
        self.stores = stores
    }

    /// Checks if the site is eligible for Blaze.
    /// - Returns: Whether the site is eligible for Blaze.
    func isEligible() async -> Bool {
        await isSiteEligible()
    }

    /// Checks if the product is eligible for Blaze.
    /// - Parameter product: The product to check for Blaze eligibility.
    /// - Parameter isPasswordProtected: Whether the product is password protected.
    /// - Returns: Whether the product is eligible for Blaze.
    func isEligible(product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        guard product.status == .published && isPasswordProtected == false else {
            return false
        }
        return await isSiteEligible()
    }
}

private extension BlazeEligibilityChecker {
    @MainActor
    func isSiteEligible() async -> Bool {
        guard stores.isAuthenticatedWithoutWPCom == false else {
            return false
        }
        guard await isRemoteFeatureFlagEnabled(.blaze) else {
            return false
        }
        do {
            return try await isBlazeApproved(for: site)
        } catch {
            DDLogError("⛔️ Unable to load Blaze status for site ID \(site.siteID): \(error)")
            return false
        }
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

    @MainActor
    func isBlazeApproved(for site: Site) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SiteAction.loadBlazeStatus(siteID: site.siteID) { result in
                continuation.resume(with: result)
            })
        }
    }
}
