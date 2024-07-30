import Foundation
import Yosemite

/// Protocol for checking Blaze eligibility for easier unit testing.
protocol BlazeEligibilityCheckerProtocol {
    func isSiteEligible(_ site: Site) -> Bool
    func isProductEligible(site: Site, product: ProductFormDataModel, isPasswordProtected: Bool) -> Bool
}

/// Checks for Blaze eligibility for a site and its products.
final class BlazeEligibilityChecker: BlazeEligibilityCheckerProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Checks if the site is eligible for Blaze.
    /// - Returns: Whether the site is eligible for Blaze.
    func isSiteEligible(_ site: Site) -> Bool {
        checkSiteEligibility(site)
    }

    /// Checks if the product is eligible for Blaze.
    /// - Parameter product: The product to check for Blaze eligibility.
    /// - Parameter isPasswordProtected: Whether the product is password protected.
    /// - Returns: Whether the product is eligible for Blaze.
    func isProductEligible(site: Site, product: ProductFormDataModel, isPasswordProtected: Bool) -> Bool {
        guard product.status == .published && isPasswordProtected == false else {
            return false
        }
        return checkSiteEligibility(site)
    }
}

private extension BlazeEligibilityChecker {
    func checkSiteEligibility(_ site: Site) -> Bool {
        guard site.isAdmin && site.canBlaze else {
            return false
        }
        guard site.isJetpackConnected && site.isJetpackThePluginInstalled else {
            return false
        }
        guard stores.isAuthenticatedWithoutWPCom == false else {
            return false
        }
        return true
    }
}
