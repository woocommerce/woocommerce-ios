import Foundation
import NetworkingCore

/// Remote for WooCommerce Store API operations used in Point of Sale.
///
/// This remote uses the Store API (`/wc/store/v1/`) with the `X-WC-POS: 1` header
/// for cart and checkout operations.
///
public final class POSStoreAPIRemote: Remote {
    /// Site URL for making requests.
    private let siteURL: String

    /// Initializer.
    ///
    /// - Parameters:
    ///   - network: Network layer for making requests.
    ///   - siteURL: URL of the site to make requests to.
    ///
    public init(network: Network, siteURL: String) {
        self.siteURL = siteURL
        super.init(network: network)
    }

    // MARK: - Cart Operations

    /// Retrieves the current cart.
    ///
    /// - Returns: The current cart state.
    ///
    public func getCart() async throws -> StoreAPICart {
        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .get,
            path: Path.cart
        )
        let mapper = StoreAPICartMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Clears all items from the cart.
    ///
    public func clearCart() async throws {
        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .delete,
            path: Path.cartItems
        )
        try await enqueue(request)
    }

    /// Adds an item to the cart.
    ///
    /// - Parameters:
    ///   - productID: The product ID to add.
    ///   - quantity: The quantity to add.
    ///   - variationID: Optional variation ID (for variable products).
    /// - Returns: The updated cart.
    ///
    public func addItem(productID: Int64, quantity: Int, variationID: Int64? = nil) async throws -> StoreAPICart {
        var parameters: [String: Any] = [
            ParameterKey.id: productID,
            ParameterKey.quantity: quantity
        ]

        if let variationID, variationID > 0 {
            parameters[ParameterKey.variation] = variationID
        }

        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .post,
            path: Path.cartAddItem,
            parameters: parameters
        )
        let mapper = StoreAPICartMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Applies a coupon to the cart.
    ///
    /// - Parameter code: The coupon code to apply.
    /// - Returns: The updated cart.
    ///
    public func applyCoupon(code: String) async throws -> StoreAPICart {
        let parameters: [String: Any] = [
            ParameterKey.code: code
        ]

        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .post,
            path: Path.cartApplyCoupon,
            parameters: parameters
        )
        let mapper = StoreAPICartMapper()
        return try await enqueue(request, mapper: mapper)
    }

    /// Removes a coupon from the cart.
    ///
    /// - Parameter code: The coupon code to remove.
    /// - Returns: The updated cart.
    ///
    public func removeCoupon(code: String) async throws -> StoreAPICart {
        let parameters: [String: Any] = [
            ParameterKey.code: code
        ]

        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .post,
            path: Path.cartRemoveCoupon,
            parameters: parameters
        )
        let mapper = StoreAPICartMapper()
        return try await enqueue(request, mapper: mapper)
    }

    // MARK: - Checkout Operations

    /// Performs checkout to create or complete an order.
    ///
    /// - Parameters:
    ///   - paymentMethod: Payment method ID (e.g., "pos_cash", "pos_card").
    ///   - billingAddress: Billing address fields (can be empty for POS).
    ///   - paymentData: Payment data array (e.g., containing payment_intent_id for card capture).
    /// - Returns: The checkout response with order details.
    ///
    public func checkout(
        paymentMethod: String,
        billingAddress: [String: Any] = [:],
        paymentData: [[String: String]] = []
    ) async throws -> StoreAPICheckoutResponse {
        var parameters: [String: Any] = [
            ParameterKey.paymentMethod: paymentMethod,
            ParameterKey.billingAddress: billingAddress
        ]

        if !paymentData.isEmpty {
            parameters[ParameterKey.paymentData] = paymentData
        }

        let request = POSStoreAPIRequest(
            siteURL: siteURL,
            method: .post,
            path: Path.checkout,
            parameters: parameters
        )
        let mapper = StoreAPICheckoutResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants

private extension POSStoreAPIRemote {
    enum Path {
        static let cart = "cart"
        static let cartItems = "cart/items"
        static let cartAddItem = "cart/add-item"
        static let cartApplyCoupon = "cart/apply-coupon"
        static let cartRemoveCoupon = "cart/remove-coupon"
        static let checkout = "checkout"
    }

    enum ParameterKey {
        static let id = "id"
        static let quantity = "quantity"
        static let variation = "variation"
        static let code = "code"
        static let paymentMethod = "payment_method"
        static let billingAddress = "billing_address"
        static let paymentData = "payment_data"
    }
}
