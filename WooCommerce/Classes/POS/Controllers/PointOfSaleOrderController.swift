import Foundation
import Combine
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import struct Yosemite.Order
import struct Yosemite.POSCartItem
import enum Yosemite.OrderAction
import enum Yosemite.OrderUpdateField
import class WooFoundation.CurrencyFormatter

protocol PointOfSaleOrderControllerProtocol {
    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> { get }

    @available(*, deprecated, message: "This property will be removed when possible. Use `orderState.loaded` instead.")
    var order: Order? { get }

    func syncOrder(for cartProducts: [CartItem], retryHandler: @escaping () async -> Void) async
    func sendReceipt(recipientEmail: String) async throws
    func clearOrder()
    func collectCashPayment() async throws
}

final class PointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    init(orderService: POSOrderServiceProtocol,
         receiptService: POSReceiptServiceProtocol,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.orderService = orderService
        self.receiptService = receiptService
        self.currencyFormatter = currencyFormatter
    }

    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> {
        $orderState.eraseToAnyPublisher()
    }

    private let orderService: POSOrderServiceProtocol
    private let receiptService: POSReceiptServiceProtocol

    private let currencyFormatter: CurrencyFormatter

    @Published private var orderState: PointOfSaleInternalOrderState = .idle
    private(set) var order: Order? = nil

    @MainActor
    func syncOrder(for cartItems: [CartItem],
                   retryHandler: @escaping () async -> Void) async {
        let posCartItems = cartItems.map {
            POSCartItem(item: $0.item, quantity: Decimal($0.quantity))
        }

        guard !orderState.isSyncing,
              !posCartItems.matches(order: order) else {
            return
        }

        orderState = .syncing

        do {
            let syncedOrder = try await orderService.syncOrder(cart: posCartItems, order: order)
            self.order = syncedOrder
            orderState = .loaded(totals(for: syncedOrder), syncedOrder)
            DDLogInfo("🟢 [POS] Synced order: \(syncedOrder)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
            setOrderStateToError(error, retryHandler: retryHandler)
        }
    }

    private func setOrderStateToError(_ error: Error,
                                      retryHandler: @escaping () async -> Void) {
        // Consider removing error or handle specific errors with our own formatting and localization
        orderState = .error(.init(message: error.localizedDescription,
                                  handler: {
            Task {
                await retryHandler()
            }
        }))
    }

    func sendReceipt(recipientEmail: String) async throws {
        guard let order = order else {
            return
        }
        try await orderService.updatePOSOrder(order: order, recipientEmail: recipientEmail)
        try await receiptService.sendReceipt(order: order, recipientEmail: recipientEmail)
    }

    func clearOrder() {
        order = nil
        orderState = .idle
    }

    @MainActor
    func collectCashPayment() async throws {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            throw NSError(domain: "", code: 0)
        }
        guard let order = order else {
            throw NSError(domain: "", code: 0)
        }

        let fieldsToUpdate: [OrderUpdateField] = [
            .status,
            .paymentMethodID,
            .paymentMethodTitle]
        let updatedOrder = order.copy(status: .completed,
                                      paymentMethodID: "cash",
                                      paymentMethodTitle: "Cash (Point of Sale)")

        let _ = try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.updateOrder(siteID: siteID,
                                                 order: updatedOrder,
                                                 giftCard: nil,
                                                 fields: fieldsToUpdate,
                                                 onCompletion: { result in
                continuation.resume(with: result)
            })
            ServiceLocator.stores.dispatch(action)
        }
    }
}


private extension PointOfSaleOrderController {
    func totals(for order: Order) -> PointOfSaleOrderTotals {
        let totalsCalculator = OrderTotalsCalculator(for: order,
                                                     using: currencyFormatter)
        return PointOfSaleOrderTotals(
            cartTotal: formattedPrice(totalsCalculator.itemsTotal.stringValue,
                                      currency: order.currency) ?? "",
            orderTotal: formattedPrice(order.total, currency: order.currency) ?? "",
            taxTotal: formattedPrice(order.totalTax, currency: order.currency) ?? "")
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }
}

// This is named to note that it is for use within the AggregateModel and OrderController.
// Conversely, PointOfSaleOrderState is available to the Views, as it doesn't include the Order.
enum PointOfSaleInternalOrderState {
    case idle
    case syncing
    case loaded(PointOfSaleOrderTotals, Order)
    case error(PointOfSaleOrderSyncErrorMessageViewModel)

    var isSyncing: Bool {
        switch self {
        case .syncing:
            return true
        default:
            return false
        }
    }

    var externalState: PointOfSaleOrderState {
        switch self {
        case .idle:
            return .idle
        case .error(let error):
            return .error(error)
        case .loaded(let totals, _):
            return .loaded(totals)
        case .syncing:
            return .syncing
        }
    }
}

extension PointOfSaleInternalOrderState: Equatable {
    static func ==(lhs: PointOfSaleInternalOrderState, rhs: PointOfSaleInternalOrderState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.title == rhsError.title &&
            lhsError.message == rhsError.message
        case (.syncing, .syncing):
            return true
        case (.loaded(let lhsTotals, let lhsOrder), .loaded(let rhsTotals, let rhsOrder)):
            return lhsTotals == rhsTotals &&
            lhsOrder == rhsOrder
        default:
            return false
        }
    }
}
