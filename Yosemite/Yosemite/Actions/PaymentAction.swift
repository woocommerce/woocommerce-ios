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

    /// Creates a cart with a WPCOM plan.
    /// - Parameters:
    ///   - productID: The ID of the WPCOM plan product.
    ///   - siteID: The site ID for the WPCOM plan to be attached to.
    ///   - completion: The result of cart creation.
    case createCart(productID: String,
                    siteID: Int64,
                    completion: (Result<Void, Error>) -> Void)
}
