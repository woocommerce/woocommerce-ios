import Foundation
import Observation
import class WooFoundation.VersionHelpers
import protocol Yosemite.POSOrderServiceProtocol
import class Yosemite.POSOrderService
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PluginsServiceProtocol
import struct Yosemite.Order
import struct Yosemite.POSCart
import struct Yosemite.POSCartItem
import struct Yosemite.POSCoupon
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation
import protocol Yosemite.POSOrderableItem
import struct Yosemite.CouponsError
import enum Yosemite.OrderAction
import enum Yosemite.OrderUpdateField
import enum Yosemite.Plugin
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import class Yosemite.PluginsService
import enum WooFoundation.CurrencyCode
import protocol WooFoundation.Analytics
import class Yosemite.OrderTotalsCalculator
import struct WooFoundation.WooAnalyticsEvent
import protocol WooFoundationCore.WooAnalyticsEventPropertyType

enum SyncOrderState {
    case newOrder
    case orderNotChanged
}

enum SyncOrderStateError: Error {
    case syncFailure
}

/// Represents a cart item whose price was updated by the server during order sync.
struct CartItemPriceUpdate {
    /// The UUID of the cart's `PurchasableItem` whose price changed.
    let cartItemID: UUID
    /// The updated orderable item with the corrected price.
    let updatedItem: POSOrderableItem
}

protocol PointOfSaleOrderControllerProtocol {
    var orderState: PointOfSaleInternalOrderState { get }

    @discardableResult
    func syncOrder(for cart: Cart, retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error>
    func sendReceipt(recipientEmail: String) async throws
    func clearOrder()
    func collectCashPayment(changeDueAmount: String?) async throws

    /// Compares cart item prices with the synced order's line items.
    /// Returns updates for items whose server-side price differs from the local price.
    func priceUpdates(for cart: Cart) -> [CartItemPriceUpdate]
}

@Observable final class PointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    init(orderService: POSOrderServiceProtocol,
         receiptSender: POSReceiptSending,
         currencySettingsProvider: POSCurrencySettingsProviding,
         analytics: POSAnalyticsProviding) {
        self.orderService = orderService
        self.receiptSender = receiptSender
        self.currencySettingsProvider = currencySettingsProvider
        self.analytics = analytics
    }

    private let orderService: POSOrderServiceProtocol
    private let receiptSender: POSReceiptSending
    private let currencySettingsProvider: POSCurrencySettingsProviding
    private let analytics: POSAnalyticsProviding

    private(set) var orderState: PointOfSaleInternalOrderState = .idle
    private var order: Order? = nil

    private var currencyFormatter: CurrencyFormatter {
        CurrencyFormatter(currencySettings: currencySettingsProvider.currencySettings)
    }

    private var storeCurrency: CurrencyCode {
        currencySettingsProvider.currencySettings.currencyCode
    }

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
            trackOrderCreationFailed(error: error)
            setOrderStateToError(error, retryHandler: retryHandler)
            return .failure(SyncOrderStateError.syncFailure)
        }
    }

    private func setOrderStateToError(_ error: Error,
                                      retryHandler: @escaping () async -> Void) {
        orderState = .error(orderStateError(from: error), {
            Task {
                await retryHandler()
            }
        })
    }

    @MainActor
    func sendReceipt(recipientEmail: String) async throws {
        guard let order else {
            throw PointOfSaleOrderControllerError.noOrder
        }

        try await receiptSender.sendReceipt(orderID: order.orderID, recipientEmail: recipientEmail)
    }

    func clearOrder() {
        order = nil
        orderState = .idle
    }

    @MainActor
    func collectCashPayment(changeDueAmount: String?) async throws {
        guard let order = order else {
            throw PointOfSaleOrderControllerError.noOrder
        }

        do {
            try await orderService.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: changeDueAmount)
        } catch {
            analytics.track(.pointOfSaleCashPaymentFailed)
            throw error
        }
    }

    func priceUpdates(for cart: Cart) -> [CartItemPriceUpdate] {
        guard let order else { return [] }

        return cart.purchasableItems.compactMap { purchasableItem -> CartItemPriceUpdate? in
            guard case .loaded(let orderableItem) = purchasableItem.state else { return nil }

            // Find the matching order line item
            guard let orderItem = order.items.first(where: { orderableItem.matches(orderItem: $0) }) else { return nil }

            let orderPriceDecimal = orderItem.price
            let orderPriceString = orderPriceDecimal.stringValue

            // Update if the server price differs from the local price (compare as decimals to avoid string format mismatches)
            if let simpleProduct = orderableItem as? POSSimpleProduct,
               NSDecimalNumber(string: simpleProduct.price) != orderPriceDecimal {
                let formattedPrice = currencyFormatter.formatAmount(orderPriceString, with: order.currency) ?? simpleProduct.formattedPrice
                let updated = simpleProduct.copy(formattedPrice: formattedPrice, price: orderPriceString)
                return CartItemPriceUpdate(cartItemID: purchasableItem.id, updatedItem: updated)
            } else if let variation = orderableItem as? POSVariation,
                      NSDecimalNumber(string: variation.price) != orderPriceDecimal {
                let formattedPrice = currencyFormatter.formatAmount(orderPriceString, with: order.currency) ?? variation.formattedPrice
                let updated = POSVariation(id: variation.id,
                                           name: variation.name,
                                           formattedPrice: formattedPrice,
                                           price: orderPriceString,
                                           productImageSource: variation.productImageSource,
                                           productID: variation.productID,
                                           variationID: variation.productVariationID,
                                           parentProductName: variation.parentProductName)
                return CartItemPriceUpdate(cartItemID: purchasableItem.id, updatedItem: updated)
            }

            return nil
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
            taxTotal: formattedPrice(order.totalTax, currency: order.currency) ?? "",
            orderTotalDecimal: totalsCalculator.orderTotal.decimalValue,
            discountTotal: formattedDiscount(totalsCalculator.discountTotal,
                                             currency: order.currency),
            couponsTotals: couponsTotals(order))
    }

    func formattedPrice(_ price: String?, currency: String?, isNegative: Bool = false) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency, isNegative: isNegative)
    }

    func couponsTotals(_ order: Order) -> [PointOfSaleCouponTotal] {
        return order.coupons.compactMap { coupon in
            PointOfSaleCouponTotal(
                code: coupon.code,
                total: formattedPrice(coupon.discount, currency: order.currency, isNegative: true) ?? ""
            )
        }
    }

    func formattedDiscount(_ discount: NSDecimalNumber, currency: String) -> String? {
        guard !discount.isZero(),
              let formattedDiscount = formattedPrice(discount.stringValue, currency: currency, isNegative: true) else {
            return nil
        }

        return formattedDiscount
    }
}

// MARK: - Error Handling

private extension PointOfSaleOrderController {
    func orderStateError(from error: Error) -> PointOfSaleOrderState.OrderStateError {
        // Check for missing products error first
        if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
            let missingProductInfo = missingItems.map {
                PointOfSaleOrderState.OrderStateError.MissingProductInfo(
                    productID: $0.productID,
                    variationID: $0.variationID,
                    name: $0.name
                )
            }
            return .missingProducts(missingProductInfo)
        }
        else if let couponsError = CouponsError(underlyingError: error) {
            return .invalidCoupon(couponsError.message)
        } else {
            return .other(error.localizedDescription)
        }
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

extension PointOfSaleOrderController {
    enum PointOfSaleOrderControllerError: Error {
        case noOrder
    }
}


private extension PointOfSaleOrderController {
    func trackOrderCreationFailed(error: Error) {
        var errorType: WooAnalyticsEvent.Orders.OrderCreationErrorType?

        if let _ = CouponsError(underlyingError: error) {
            errorType = .invalidCoupon
        } else if case .missingProductsInOrder = error as? POSOrderService.POSOrderServiceError {
            errorType = .missingProducts
        }

        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationFailed(
            usesGiftCard: false,
            errorContext: String(describing: error),
            errorDescription: error.localizedDescription,
            errorType: errorType
        ))
    }
}

// MARK: - Mapping

private extension POSCart {
    init(cart: Cart) {
        let items = cart.purchasableItems.compactMap { (purchasableItem: Cart.PurchasableItem) -> POSCartItem? in
            guard case let .loaded(item) = purchasableItem.state else { return nil }
            return POSCartItem(item: item, quantity: Decimal(purchasableItem.quantity))
        }
        let coupons = cart.coupons.map { POSCoupon(id: $0.posItemIdentifier, code: $0.code, summary: $0.summary) }
        self.init(items: items, coupons: coupons)
    }
}

private extension WooAnalyticsEvent {
    struct Orders {
        // MARK: - Order Creation Events

        /// Matches errors on Android for consistency
        enum OrderCreationErrorType: String {
            case invalidCoupon = "INVALID_COUPON"
            case missingProducts = "MISSING_PRODUCTS"
        }

        static func orderCreationFailed(
            usesGiftCard: Bool,
            errorContext: String,
            errorDescription: String,
            errorType: OrderCreationErrorType? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                "use_gift_card": usesGiftCard,
                "error_context": errorContext,
                "error_description": errorDescription
            ]

            if let errorType {
                properties["error_type"] = errorType.rawValue
            }

            return WooAnalyticsEvent(statName: .orderCreationFailed, properties: properties)
        }
    }
}
