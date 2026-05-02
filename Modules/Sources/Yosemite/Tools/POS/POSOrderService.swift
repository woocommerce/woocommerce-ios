import Foundation
import Networking
import class WooFoundation.CurrencyFormatter
import enum WooFoundation.CurrencyCode
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import enum Alamofire.AFError

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with different types of items and quantities.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order
    func loadOrder(orderID: Int64) async throws -> Order
    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws
    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws
    /// Marks an order as completed when payment was collected out-of-band (external reader,
    /// gift card, account credit, etc.) and the merchant confirms it via the "Mark order as
    /// paid" flow. The order's `paymentMethodID` is set to `"other"` so reporting can
    /// distinguish it from cash and card-present payments.
    func markOrderAsCompletedManually(order: Order) async throws
}

public final class POSOrderService: POSOrderServiceProtocol {
    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol

    public convenience init?(siteID: Int64,
                             credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(siteID: siteID,
                  ordersRemote: OrdersRemote(network: network))
    }

    public init(siteID: Int64,
                ordersRemote: POSOrdersRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
    }

    // MARK: - Protocol conformance

    public func loadOrder(orderID: Int64) async throws -> Order {
        do {
            return try await ordersRemote.loadPOSOrder(siteID: siteID, orderID: orderID)
        } catch {
            throw POSOrderServiceError.updateOrderFailed
        }
    }

    public func syncOrder(cart: POSCart,
                          currency: CurrencyCode) async throws -> Order {
        let order = OrderFactory
            .newOrder(currency: currency)
            .copy(siteID: siteID, status: .autoDraft)
            .addItems(cart.items)
            .addCoupons(cart.coupons)

        let createdOrder: Order
        do {
            createdOrder = try await ordersRemote.createPOSOrder(
                siteID: siteID,
                order: order,
                fields: [.items, .status, .currency, .couponLines]
            )
        } catch {
            // Check if this is a server validation error about missing products
            if let missingItems = extractMissingProductsFromServerError(error, cart: cart) {
                throw POSOrderServiceError.missingProductsInOrder(missingItems)
            }
            throw error
        }

        // Validate that the created order contains all cart items
        let comparison = cart.compareWithOrder(createdOrder)
        if comparison.hasDiscrepancies {
            DDLogWarn("""
                ⚠️ Order created but cart-order mismatch detected. \
                Missing items: \(comparison.missingItems.count), \
                Quantity mismatches: \(comparison.quantityMismatches.count)
                """)

            if !comparison.missingItems.isEmpty {
                throw POSOrderServiceError.missingProductsInOrder(comparison.missingItems)
            }
        }

        return createdOrder
    }

    public func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        do {
            try await ordersRemote.updatePOSOrderEmail(siteID: siteID, orderID: orderID, emailAddress: recipientEmail)
        } catch {
            throw POSOrderServiceError.updateOrderFailed
        }
    }

    public func markOrderAsCompletedManually(order: Order) async throws {
        let fieldsToUpdate: [OrderUpdateField] = [
            .status,
            .paymentMethodID,
            .paymentMethodTitle
        ]
        let updatedOrder = order.copy(status: .completed,
                                      paymentMethodID: Constants.manualPaymentMethodID,
                                      paymentMethodTitle: Localization.manualPaymentMethodTitle)
        do {
            _ = try await ordersRemote.updatePOSOrder(
                siteID: siteID,
                order: updatedOrder,
                cashPaymentChangeDueAmount: nil,
                fields: fieldsToUpdate
            )
        } catch {
            throw POSOrderServiceError.updateOrderFailed
        }
    }

    public func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        let fieldsToUpdate: [OrderUpdateField] = [
            .status,
            .paymentMethodID,
            .paymentMethodTitle
        ]
        let updatedOrder = order.copy(status: .completed,
                                      paymentMethodID: PaymentGateway.Constants.cashOnDeliveryGatewayID,
                                      paymentMethodTitle: Localization.cashPaymentMethodTitle)
        do {
            let _ = try await ordersRemote.updatePOSOrder(
                siteID: siteID,
                order: updatedOrder,
                cashPaymentChangeDueAmount: changeDueAmount,
                fields: fieldsToUpdate
            )
        } catch {
            throw POSOrderServiceError.updateOrderFailed
        }
    }
}

private extension Order {
    func addItems(_ cartItems: [POSCartItem]) -> Order {
        let itemsToAdd = Array(cartItems.createGroupedOrderSyncProductInputs().values)
        return ProductInputTransformer
            .updateMultipleItems(with: itemsToAdd, on: self, shouldUpdateOrDeleteZeroQuantities: .update)
            .sanitizingLocalItems()
    }

    func addCoupons(_ coupons: [POSCoupon]) -> Order {
        let newCoupons = coupons
            .map { OrderFactory.newOrderCouponLine(code: $0.code) }

        return self.copy(coupons: newCoupons)
    }
}

public extension POSOrderService {
    enum POSOrderServiceError: Error {
        case updateOrderFailed
        case missingProductsInOrder([CartOrderComparison.MissingCartItem])
    }
}

private extension POSOrderService {
    /// Extracts missing product information from server validation errors
    /// Handles cases where the server rejects order creation due to invalid product/variation IDs
    func extractMissingProductsFromServerError(
        _ error: Error,
        cart: POSCart
    ) -> [CartOrderComparison.MissingCartItem]? {
        let (code, data) = errorCodeAndData(from: error)
        guard let code, isProductValidationError(code: code) else {
            return nil
        }

        guard let variationID = extractVariationID(from: data) else {
            return unknownMissingProductsInCart()
        }
        return createMissingProductInfo(forVariationID: variationID, cart: cart)
    }

    func errorCodeAndData(from error: Error) -> (code: String?, data: [String: AnyDecodable]?) {
        // Unwrap AFError if present
        let underlyingError: Error = {
            if let afError = error as? AFError, let underlying = afError.underlyingError {
                return underlying
            }
            return error
        }()

        // Extract error code and data from either error type
        if case .unknown(let code, _, let data) = underlyingError as? DotcomError {
            return (code, data)
        }
        if let networkError = underlyingError as? NetworkError {
            return (networkError.errorCode, networkError.errorData)
        }
        return (nil, nil)
    }

    /// Extracts variation_id from error data dictionary
    func extractVariationID(from data: [String: AnyDecodable]?) -> Int64? {
        guard let data,
              let variationIDValue = data["variation_id"]?.value else {
            return nil
        }

        // Handle different number types
        if let intValue = variationIDValue as? Int {
            return Int64(intValue)
        } else if let int64Value = variationIDValue as? Int64 {
            return int64Value
        }
        return nil
    }

    /// Creates MissingCartItem for a specific variation ID
    /// Searches the cart to find the variation's name and parent product ID
    func createMissingProductInfo(
        forVariationID variationID: Int64,
        cart: POSCart
    ) -> [CartOrderComparison.MissingCartItem] {
        // Search the cart for the variation to get its name
        let cartItem = cart.items.first { item in
            if let variation = item.item as? POSVariation {
                return variation.productVariationID == variationID
            }
            return false
        }

        let productName: String
        let parentProductID: Int64

        if let cartItem,
           let variation = cartItem.item as? POSVariation {
            // Found the variation in the cart - use its parent product name and variation name
            productName = "\(variation.parentProductName) - \(variation.name)"
            parentProductID = variation.productID
        } else {
            // Couldn't find it in cart, use generic name
            productName = Localization.unknownProductName
            parentProductID = 0
        }

        return [
            CartOrderComparison.MissingCartItem(
                productID: parentProductID,
                variationID: variationID,
                name: productName
            )
        ]
    }

    /// Checks if an error code indicates a product validation error
    /// Currently only handles the confirmed error code from WooCommerce server responses
    func isProductValidationError(code: String) -> Bool {
        // Only check for the one confirmed error code we've observed
        // Additional codes can be added as they are discovered through testing
        return code == "order_item_product_invalid_variation_id"
    }

    /// Extracts missing products by trying to identify items in cart that might have caused the validation error
    /// Since server doesn't tell us which specific products failed, we return generic error info
    func unknownMissingProductsInCart() -> [CartOrderComparison.MissingCartItem] {
        // We can't determine which specific products are invalid from the server error
        // So we return a generic missing product message with 0 for both IDs (meaning unknown)
        // The user will need to remove all products and retry
        return [
            CartOrderComparison.MissingCartItem(
                productID: 0,
                variationID: 0,
                name: Localization.unknownProductName
            )
        ]
    }

    enum Localization {
        static let cashPaymentMethodTitle = NSLocalizedString(
            "pointOfSaleOrderController.collectCashPayment.paymentMethodTitle",
            value: "Pay in Person",
            comment: "Title for the payment method used when collecting cash payment in Point of Sale."
        )
        static let manualPaymentMethodTitle = NSLocalizedString(
            "pointOfSaleOrderController.markOrderAsPaid.paymentMethodTitle",
            value: "Other",
            comment: "Title for the payment method used when manually marking an order as paid in Point of Sale."
        )
        static let unknownProductName = NSLocalizedString(
            "pointOfSale.orderController.unknownProduct",
            value: "One or more products",
            comment: "Fallback name for a product that couldn't be identified in error handling."
        )
    }

    enum Constants {
        /// Payment method slug used when the merchant marks an order as paid manually,
        /// e.g. for an external reader, account credit, gift card, or any out-of-band collection.
        /// Distinct from `cashOnDeliveryGatewayID` so reporting can separate the two flows.
        static let manualPaymentMethodID = "other"
    }
}
