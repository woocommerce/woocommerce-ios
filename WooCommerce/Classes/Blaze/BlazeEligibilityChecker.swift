import Foundation
import Yosemite

/// Protocol for checking Blaze eligibility for easier unit testing.
protocol BlazeEligibilityCheckerProtocol {
    @MainActor
    func isSiteEligible(_ site: Site) async -> Bool

    @MainActor
    func isProductEligible(site: Site, product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool
}

/// Checks for Blaze eligibility for a site and its products.
final class BlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {
    private let stores: StoresManager
    private let siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol

    /// In-flight eligibility checks keyed by siteID, shared across all instances.
    /// Thread-safe because all access is on @MainActor.
    private static var inFlightChecks: [Int64: Task<Bool, Never>] = [:]

    init(
        stores: StoresManager = ServiceLocator.stores,
        siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker()
    ) {
        self.stores = stores
        self.siteCIABEligibilityChecker = siteCIABEligibilityChecker
    }

    /// Checks if the site is eligible for Blaze.
    /// - Returns: Whether the site is eligible for Blaze.
    @MainActor
    func isSiteEligible(_ site: Site) async -> Bool {
        await deduplicatedCheckSiteEligibility(site)
    }

    /// Checks if the product is eligible for Blaze.
    /// - Parameter product: The product to check for Blaze eligibility.
    /// - Parameter isPasswordProtected: Whether the product is password protected.
    /// - Returns: Whether the product is eligible for Blaze.
    @MainActor
    func isProductEligible(site: Site, product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        guard product.status == .published && isPasswordProtected == false else {
            return false
        }
        return await deduplicatedCheckSiteEligibility(site)
    }
}

private extension BlazeEligibilityChecker {
    @MainActor
    func deduplicatedCheckSiteEligibility(_ site: Site) async -> Bool {
        let siteID = site.siteID
        if let existingTask = Self.inFlightChecks[siteID] {
            return await existingTask.value
        }

        let task = Task { @MainActor [weak self] () -> Bool in
            guard let self else { return false }
            return await self.checkSiteEligibility(site)
        }
        Self.inFlightChecks[siteID] = task
        let result = await task.value
        Self.inFlightChecks.removeValue(forKey: siteID)
        return result
    }

    @MainActor
    func checkSiteEligibility(_ site: Site) async -> Bool {
        guard
            site.isAdmin,
            site.canBlaze,
            siteCIABEligibilityChecker.isFeatureSupported(.blaze, for: site)
        else {
            return false
        }

        guard site.isJetpackConnected else {
            return false
        }

        guard stores.isAuthenticatedWithoutWPCom == false else {
            return false
        }

        /// Blaze DSP requires a Jetpack full sync to work. So, Jetpack CP sites are excluded from Blaze unless the store has Blaze plugin.
        /// More discussion links at - https://github.com/woocommerce/woocommerce-ios/issues/13057
        ///
        if site.isJetpackThePluginInstalled {
            return true
        }

        if let blazePlugin = await fetchBlazePluginFromRemote(siteID: site.siteID) {
            return blazePlugin.active
        }

        return false
    }

    @MainActor
    func fetchBlazePluginFromRemote(siteID: Int64) async -> SystemPlugin? {
        await withCheckedContinuation { continuation in
            stores.dispatch(SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { result in
                switch result {
                case .success(let info):
                    let plugin = info.systemPlugins.first(where: { Plugin(systemPlugin: $0) == .blaze && $0.active })
                    continuation.resume(returning: plugin)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
        }
    }
}
