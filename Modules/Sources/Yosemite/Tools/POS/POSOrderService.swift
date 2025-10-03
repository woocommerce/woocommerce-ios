import Foundation
import Networking
import class WooFoundation.CurrencyFormatter
import enum WooFoundation.CurrencyCode
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import protocol Storage.StorageManagerType

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with different types of items and quantities.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order
    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws
    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws
    func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void)
}

public final class POSOrderService: POSOrderServiceProtocol {
    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol
    private let orderStoreMethods: OrderStoreMethodsProtocol

    public convenience init?(siteID: Int64,
                             credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             storageManager: StorageManagerType) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let remote = OrdersRemote(network: network)
        self.init(siteID: siteID,
                  ordersRemote: remote,
                  orderStoreMethods: OrderStoreMethods(storageManager: storageManager, remote: remote))
    }

    internal init(siteID: Int64,
                  ordersRemote: POSOrdersRemoteProtocol,
                  orderStoreMethods: OrderStoreMethodsProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
        self.orderStoreMethods = orderStoreMethods
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

    public func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        do {
            try await ordersRemote.updatePOSOrderEmail(siteID: siteID, orderID: orderID, emailAddress: recipientEmail)
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

    public func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        orderStoreMethods.deleteOrder(siteID: siteID, order: order, deletePermanently: deletePermanently, onCompletion: onCompletion)
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
