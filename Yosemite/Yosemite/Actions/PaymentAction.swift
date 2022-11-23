import Foundation

/// PaymentAction: Defines all of the Actions supported by the PaymentStore.
///
public enum PaymentAction: Action {
    case loadPlan(productID: Int64,
                  completion: (Result<WPComPlan, Error>) -> Void)

    /// Creates a cart with a WPCOM product.
    /// - Parameters:
    ///   - productID: The ID of the WPCOM product.
    ///   - siteID: The site ID for the WPCOM product to be attached to.
    ///   - completion: The result of cart creation.
    case createCart(productID: String,
                    siteID: Int64,
                    completion: (Result<Void, Error>) -> Void)
}
