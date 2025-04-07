import Foundation
import Observation
import protocol Yosemite.StoresManager
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import struct Yosemite.Order
import struct Yosemite.PaymentGateway
import struct Yosemite.POSCart
import struct Yosemite.POSCartItem
import struct Yosemite.POSCoupon
import struct Yosemite.CouponsError
import enum Yosemite.OrderAction
import enum Yosemite.OrderUpdateField
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import enum WooFoundation.CurrencyCode
import protocol WooFoundation.Analytics

enum SyncOrderState {
    case newOrder
    case orderNotChanged
}

enum SyncOrderStateError: Error {
    case syncFailure
}

protocol PointOfSaleOrderControllerProtocol {
    var orderState: PointOfSaleInternalOrderState { get }

    @discardableResult
    func syncOrder(for cart: Cart, retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error>
    func sendReceipt(recipientEmail: String) async throws
    func clearOrder()
    func collectCashPayment() async throws
}

@available(iOS 17.0, *)
@Observable final class PointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    init(orderService: POSOrderServiceProtocol,
         receiptService: POSReceiptServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration()) {
        self.orderService = orderService
        self.receiptService = receiptService
        self.stores = stores
        self.storeCurrency = currencySettings.currencyCode
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
        self.celebration = celebration
    }

    private let orderService: POSOrderServiceProtocol
    private let receiptService: POSReceiptServiceProtocol

    private let currencyFormatter: CurrencyFormatter
    private let celebration: PaymentCaptureCelebrationProtocol
    private let storeCurrency: CurrencyCode
    private let analytics: Analytics
    private let stores: StoresManager

    private(set) var orderState: PointOfSaleInternalOrderState = .idle
    private var order: Order? = nil

    @MainActor @discardableResult
    func syncOrder(for cart: Cart,
                   retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error> {
        let posCart = POSCart(cart: cart)

        guard !orderState.isSyncing, !posCart.matches(order: order) else {
            return .success(.orderNotChanged)
        }

        orderState = .syncing

        do {
            let syncedOrder = try await orderService.syncOrder(cart: posCart,
                                                               currency: storeCurrency)
            self.order = syncedOrder
            orderState = .loaded(totals(for: syncedOrder), syncedOrder)
            analytics.track(.orderCreationSuccess)
            return .success(.newOrder)
        } catch {
            self.order = nil
            analytics.track(event: WooAnalyticsEvent.Orders.orderCreationFailed(
                usesGiftCard: false,
                errorContext: String(describing: error),
                errorDescription: error.localizedDescription))
            setOrderStateToError(error, retryHandler: retryHandler)
            return .failure(SyncOrderStateError.syncFailure)
        }
    }

    private func setOrderStateToError(_ error: Error,
                                      retryHandler: @escaping () async -> Void) {
        if let couponsError = CouponsError(underlyingError: error) {
            orderState = .error(.invalidCoupon(couponsError.message), {
                Task {
                    await retryHandler()
                }
            })
        } else {
            orderState = .error(.other(error.localizedDescription), {
                Task {
                    await retryHandler()
                }
            })
        }
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

    private func celebrate() {
        celebration.celebrate()
    }

    @MainActor
    func collectCashPayment() async throws {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            throw PointOfSaleOrderControllerError.noSiteID
        }
        guard let order = order else {
            throw PointOfSaleOrderControllerError.noOrder
        }

        let fieldsToUpdate: [OrderUpdateField] = [
            .status,
            .paymentMethodID,
            .paymentMethodTitle]
        let updatedOrder = order.copy(status: .completed,
                                      paymentMethodID: PaymentGateway.Constants.cashOnDeliveryGatewayID,
                                      paymentMethodTitle: Localization.cashPaymentMethodTitle)

        let _ = try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.updateOrder(siteID: siteID,
                                                 order: updatedOrder,
                                                 giftCard: nil,
                                                 fields: fieldsToUpdate,
                                                 onCompletion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.celebrate()
                case .failure:
                    analytics.track(.pointOfSaleCashPaymentFailed)
                }
                continuation.resume(with: result)
            })
            stores.dispatch(action)
        }
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleOrderController {
    func totals(for order: Order) -> PointOfSaleOrderTotals {
        let totalsCalculator = OrderTotalsCalculator(for: order,
                                                     using: currencyFormatter)
        return PointOfSaleOrderTotals(
            cartTotal: formattedPrice(totalsCalculator.itemsTotal.stringValue,
                                      currency: order.currency) ?? "",
            orderTotal: formattedPrice(order.total, currency: order.currency) ?? "",
            taxTotal: formattedPrice(order.totalTax, currency: order.currency) ?? "",
            orderTotalDecimal: totalsCalculator.orderTotal.decimalValue,
            discountTotal: formattedDiscount(totalsCalculator.discountTotal,
                                             currency: order.currency),
            couponsTotals: couponsTotals(order))
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }

    func couponsTotals(_ order: Order) -> [PointOfSaleCouponTotal] {
        return order.coupons.compactMap { coupon in
            PointOfSaleCouponTotal(
                code: coupon.code,
                total: formattedPrice(coupon.discount, currency: order.currency) ?? ""
            )
        }
    }

    func formattedDiscount(_ discount: NSDecimalNumber, currency: String) -> String? {
        guard !discount.isZero(),
              let formattedDiscount = formattedPrice(discount.stringValue, currency: currency) else {
            return nil
        }

        return formattedDiscount
    }
}

// This is named to note that it is for use within the AggregateModel and OrderController.
// Conversely, PointOfSaleOrderState is available to the Views, as it doesn't include the Order.
enum PointOfSaleInternalOrderState {
    case idle
    case syncing
    case loaded(PointOfSaleOrderTotals, Order)
    case error(PointOfSaleOrderState.OrderStateError, PointOfSaleOrderState.OrderStateRetryHandler)

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
        case .error(let error, let handler):
            return .error(error, handler)
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
        case (.error(let lhsError, _), .error(let rhsError, _)):
            return lhsError == rhsError
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

@available(iOS 17.0, *)
extension PointOfSaleOrderController {
    enum Localization {
        static let cashPaymentMethodTitle = NSLocalizedString(
            "pointOfSaleOrderController.collectCashPayment.paymentMethodTitle",
            value: "Pay in Person",
            comment: "Title for the payment method used when collecting cash payment in Point of Sale.")
    }
    enum PointOfSaleOrderControllerError: Error {
        case noSiteID
        case noOrder
    }
}

// MARK: - Mapping

private extension POSCart {
    init(cart: Cart) {
        let items = cart.items.map { POSCartItem(item: $0.item, quantity: Decimal($0.quantity)) }
        let coupons = cart.coupons.map { POSCoupon(id: $0.id, code: $0.code, summary: $0.summary) }
        self.init(items: items, coupons: coupons)
    }
}
