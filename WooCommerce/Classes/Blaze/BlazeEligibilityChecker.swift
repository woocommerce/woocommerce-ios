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

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Checks if the site is eligible for Blaze.
    /// - Returns: Whether the site is eligible for Blaze.
    func isSiteEligible(_ site: Site) async -> Bool {
        await checkSiteEligibility(site)
    }

    /// Checks if the product is eligible for Blaze.
    /// - Parameter product: The product to check for Blaze eligibility.
    /// - Parameter isPasswordProtected: Whether the product is password protected.
    /// - Returns: Whether the product is eligible for Blaze.
    func isProductEligible(site: Site, product: ProductFormDataModel, isPasswordProtected: Bool) async -> Bool {
        guard product.status == .published && isPasswordProtected == false else {
            return false
        }
        return await checkSiteEligibility(site)
    }
}

private extension BlazeEligibilityChecker {
    @MainActor
    func checkSiteEligibility(_ site: Site) async -> Bool {
        guard site.isAdmin && site.canBlaze else {
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
                    let plugin = info.systemPlugins.first(where: { $0.plugin == Constants.pluginSlug })
                    continuation.resume(returning: plugin)
                case .failure:
                    continuation.resume(returning: nil)
                }
            })
        }
    }
}

private extension BlazeEligibilityChecker {
    enum Constants {
        static let pluginSlug = "blaze-ads/blaze-ads.php"
    }
}
