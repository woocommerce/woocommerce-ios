import Foundation
import Combine
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.Order
import struct Yosemite.POSCartItem
import class WooFoundation.CurrencyFormatter

protocol PointOfSaleOrderControllerProtocol {
    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> { get }

    @available(*, deprecated, message: "This property will be removed when possible. Use `orderState.loaded` instead.")
    var order: Order? { get }

    func syncOrder(for cartProducts: [CartItem], retryHandler: @escaping () async -> Void) async
    func clearOrder()
}

final class PointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    init(orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        self.orderService = orderService
        self.currencyFormatter = currencyFormatter
    }

    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> {
        $orderState.eraseToAnyPublisher()
    }

    private let orderService: POSOrderServiceProtocol

    private let currencyFormatter: CurrencyFormatter

    @Published private var orderState: PointOfSaleInternalOrderState = .idle
    private(set) var order: Order? = nil

    @MainActor
    func syncOrder(for cartProducts: [CartItem],
                   retryHandler: @escaping () async -> Void) async {
        guard !orderState.isSyncing,
              CartItem.areOrderAndCartDifferent(order: order, cartItems: cartProducts) else {
            return
        }

        orderState = .syncing
        let cartItems = cartProducts.map {
            POSCartItem(product: $0.item, quantity: Decimal($0.quantity))
        }

        do {
            let syncedOrder = try await orderService.syncOrder(cart: cartItems, order: order)
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

    func clearOrder() {
        order = nil
        orderState = .idle
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
