import Foundation
import Networking
import class WooFoundation.CurrencyFormatter
import enum WooFoundation.CurrencyCode

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with different types of items and quantities.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order
    func updatePOSOrder(order: Order, recipientEmail: String) async throws
    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws
}

public final class POSOrderService: POSOrderServiceProtocol {
    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  ordersRemote: OrdersRemote(network: network))
    }

    public init(siteID: Int64,
                ordersRemote: POSOrdersRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
    }

    // MARK: - Protocol conformance

    public func syncOrder(cart: POSCart,
                          currency: CurrencyCode) async throws -> Order {
        let order = OrderFactory
            .newOrder(currency: currency)
            .copy(siteID: siteID, status: .autoDraft)
            .addItems(cart.items)
            .addCoupons(cart.coupons)

        return try await ordersRemote.createPOSOrder(siteID: siteID, order: order, fields: [.items, .status, .currency, .couponLines])
    }

    public func updatePOSOrder(order: Order, recipientEmail: String) async throws {
        guard order.billingAddress?.email == nil || order.billingAddress?.email == "" else {
            throw POSOrderServiceError.emailAlreadySet
        }
        let updatedBillingAddress = order.billingAddress?.copy(email: recipientEmail)
        let updatedOrder = order.copy(billingAddress: updatedBillingAddress)

        do {
            let _ = try await ordersRemote.updatePOSOrder(
                siteID: siteID,
                order: updatedOrder,
                cashPaymentChangeDueAmount: nil,
                fields: [.billingAddress]
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

private extension POSOrderService {
    enum POSOrderServiceError: Error {
        case emailAlreadySet
        case updateOrderFailed
    }
}

private extension POSOrderService {
    enum Localization {
        static let cashPaymentMethodTitle = NSLocalizedString(
            "pointOfSaleOrderController.collectCashPayment.paymentMethodTitle",
            value: "Pay in Person",
            comment: "Title for the payment method used when collecting cash payment in Point of Sale."
        )
    }
}
