import Foundation

/// PaymentAction: Defines all of the Actions supported by the PaymentStore.
///
public enum PaymentAction: Action {
    /// Loads a specific WPCOM plan.
    /// - Parameters:
    ///   - productID: The ID of the WPCOM product to return.
    ///   - completion: Invoked when the WPCOM plan that matches the given ID is loaded.
    case loadPlan(productID: Int64,
                  completion: (Result<WPComPlan, Error>) -> Void)

    /// Loads a site's current WPCOM plan.
    /// - Parameters:
    ///   - siteID: The ID of a site.
    ///   - completion: Invoked when the site's current plan is loaded.
    case loadSiteCurrentPlan(siteID: Int64,
                             completion: (Result<WPComSitePlan, Error>) -> Void)

    /// Creates a cart with a WPCOM plan.
    /// - Parameters:
    ///   - productID: The ID of the WPCOM plan product. It is of string type to integrate with `InAppPurchasesForWPComPlansProtocol`.
    ///                If the value is not a string of integer value, an error `CreateCartError.invalidProductID` is returned.
    ///   - siteID: The site ID for the WPCOM plan to be attached to.
    ///   - completion: The result of cart creation.
    case createCart(productID: String,
                    siteID: Int64,
                    completion: (Result<Void, Error>) -> Void)
}
