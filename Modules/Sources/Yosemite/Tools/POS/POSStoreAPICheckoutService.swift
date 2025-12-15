import Foundation
import Networking
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

/// Payment methods supported by POS Store API checkout.
///
public enum POSStoreAPIPaymentMethod: String {
    case cash = "pos_cash"
    case card = "pos_card"
}

/// Gift card information for a cart item during checkout.
///
public struct POSGiftCardItemInfo {
    public let recipientEmail: String
    public let senderName: String

    public init(recipientEmail: String, senderName: String) {
        self.recipientEmail = recipientEmail
        self.senderName = senderName
    }
}

/// Result of a Store API checkout operation.
///
public struct POSStoreAPICheckoutResult {
    /// The checkout response from the Store API.
    public let checkoutResponse: StoreAPICheckoutResponse

    /// The cart totals at the time of checkout.
    public let cartTotals: StoreAPICartTotals

    public init(checkoutResponse: StoreAPICheckoutResponse, cartTotals: StoreAPICartTotals) {
        self.checkoutResponse = checkoutResponse
        self.cartTotals = cartTotals
    }
}

/// Protocol for POS Store API checkout operations.
///
public protocol POSStoreAPICheckoutServiceProtocol {
    /// Syncs local cart to Store API and initiates checkout.
    ///
    /// This method:
    /// 1. Clears any existing Store API cart
    /// 2. Adds all local cart items to the Store API cart
    /// 3. Applies all coupons
    /// 4. Gets cart totals
    /// 5. Calls checkout with the specified payment method
    ///
    /// - Parameters:
    ///   - cart: The local POS cart to sync and checkout.
    ///   - paymentMethod: Payment method to use (cash or card).
    ///   - billingEmail: Optional billing email for the order.
    ///   - giftCardInfo: Gift card info per cart item, keyed by cart item UUID.
    /// - Returns: Checkout result with order details and cart totals.
    ///
    func checkout(
        cart: POSCart,
        paymentMethod: POSStoreAPIPaymentMethod,
        billingEmail: String?,
        giftCardInfo: [UUID: POSGiftCardItemInfo]
    ) async throws -> POSStoreAPICheckoutResult

    /// Captures a card payment by calling checkout with the payment intent ID.
    ///
    /// This is the second step of the two-step card payment flow:
    /// 1. Initial checkout creates a pending order
    /// 2. Terminal SDK collects payment and returns payment_intent_id
    /// 3. This method calls checkout again with the payment_intent_id to complete
    ///
    /// - Parameter paymentIntentID: The Stripe payment intent ID from the Terminal SDK.
    /// - Returns: The checkout response (order should now be completed).
    ///
    func captureCardPayment(paymentIntentID: String) async throws -> StoreAPICheckoutResponse

    /// Clears the Store API cart.
    ///
    func clearCart() async throws
}

/// Service for POS Store API checkout operations.
///
public final class POSStoreAPICheckoutService: POSStoreAPICheckoutServiceProtocol {
    private let remote: POSStoreAPIRemote

    /// Creates a checkout service with a pre-configured network.
    ///
    /// Use this initializer when you have an existing network that's already
    /// configured for application password authentication.
    ///
    /// - Parameters:
    ///   - siteURL: URL of the WooCommerce site.
    ///   - network: Pre-configured network for making requests.
    ///
    public convenience init(siteURL: String, network: Network) {
        let remote = POSStoreAPIRemote(network: network, siteURL: siteURL)
        self.init(remote: remote)
    }

    /// Creates a checkout service with the provided credentials.
    ///
    /// - Parameters:
    ///   - siteURL: URL of the WooCommerce site.
    ///   - credentials: Authentication credentials.
    ///   - selectedSite: Publisher for the selected site.
    ///   - appPasswordSupportState: Publisher for app password support state.
    ///
    public convenience init?(
        siteURL: String,
        credentials: Credentials?,
        selectedSite: AnyPublisher<JetpackSite?, Never>,
        appPasswordSupportState: AnyPublisher<Bool, Never>
    ) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSStoreAPICheckoutService due to missing credentials")
            return nil
        }
        let network = AlamofireNetwork(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupportState
        )
        let remote = POSStoreAPIRemote(network: network, siteURL: siteURL)
        self.init(remote: remote)
    }

    /// Creates a checkout service with a pre-configured remote.
    ///
    /// - Parameter remote: The Store API remote to use for requests.
    ///
    public init(remote: POSStoreAPIRemote) {
        self.remote = remote
    }

    // MARK: - POSStoreAPICheckoutServiceProtocol

    public func checkout(
        cart: POSCart,
        paymentMethod: POSStoreAPIPaymentMethod,
        billingEmail: String?,
        giftCardInfo: [UUID: POSGiftCardItemInfo] = [:]
    ) async throws -> POSStoreAPICheckoutResult {
        // Step 1: Clear any existing cart
        try await clearCart()

        // Step 2: Add all cart items
        for cartItem in cart.items {
            let (productID, variationID) = extractProductIDs(from: cartItem.item)
            let quantity = Int(truncating: cartItem.quantity as NSDecimalNumber)

            // Get gift card info for this cart item if available
            let gcInfo = giftCardInfo[cartItem.id]

            _ = try await remote.addItem(
                productID: productID,
                quantity: quantity,
                variationID: variationID > 0 ? variationID : nil,
                giftCardRecipientEmail: gcInfo?.recipientEmail,
                giftCardSenderName: gcInfo?.senderName
            )
        }

        // Step 3: Apply all coupons
        for coupon in cart.coupons {
            _ = try await remote.applyCoupon(code: coupon.code)
        }

        // Step 4: Get cart to retrieve totals
        let cartWithTotals = try await remote.getCart()

        // Step 5: Build billing address (only include email if provided)
        var billingAddress: [String: Any] = [:]
        if let email = billingEmail, !email.isEmpty {
            billingAddress["email"] = email
        }

        // Step 6: Call checkout
        let checkoutResponse = try await remote.checkout(
            paymentMethod: paymentMethod.rawValue,
            billingAddress: billingAddress
        )

        return POSStoreAPICheckoutResult(
            checkoutResponse: checkoutResponse,
            cartTotals: cartWithTotals.totals
        )
    }

    public func captureCardPayment(paymentIntentID: String) async throws -> StoreAPICheckoutResponse {
        // Call checkout with the payment_intent_id to capture the payment
        // The cart can be empty for this call - it just needs the payment data
        let paymentData: [[String: String]] = [
            ["key": "payment_intent_id", "value": paymentIntentID]
        ]

        return try await remote.checkout(
            paymentMethod: POSStoreAPIPaymentMethod.card.rawValue,
            billingAddress: [:],
            paymentData: paymentData
        )
    }

    public func clearCart() async throws {
        try await remote.clearCart()
    }
}

// MARK: - Private Helpers

private extension POSStoreAPICheckoutService {
    /// Extracts product and variation IDs from a POS orderable item.
    ///
    func extractProductIDs(from item: POSOrderableItem) -> (productID: Int64, variationID: Int64) {
        if let simpleProduct = item as? POSSimpleProduct {
            return (simpleProduct.productID, 0)
        } else if let variation = item as? POSVariation {
            return (variation.productID, variation.productVariationID)
        }
        // Fallback - shouldn't happen for valid cart items
        DDLogWarn("⚠️ Unknown POSOrderableItem type: \(type(of: item))")
        return (0, 0)
    }
}

// MARK: - Errors

public extension POSStoreAPICheckoutService {
    enum CheckoutError: Error, LocalizedError {
        case failedToSyncCart
        case failedToCheckout
        case failedToCapturePayment

        public var errorDescription: String? {
            switch self {
            case .failedToSyncCart:
                return NSLocalizedString(
                    "posStoreAPICheckoutService.error.failedToSyncCart",
                    value: "Failed to sync cart to server",
                    comment: "Error message when Store API cart sync fails"
                )
            case .failedToCheckout:
                return NSLocalizedString(
                    "posStoreAPICheckoutService.error.failedToCheckout",
                    value: "Failed to complete checkout",
                    comment: "Error message when Store API checkout fails"
                )
            case .failedToCapturePayment:
                return NSLocalizedString(
                    "posStoreAPICheckoutService.error.failedToCapturePayment",
                    value: "Failed to capture payment",
                    comment: "Error message when Store API payment capture fails"
                )
            }
        }
    }
}
