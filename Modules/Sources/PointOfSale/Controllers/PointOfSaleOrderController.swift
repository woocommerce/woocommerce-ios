import Foundation
import Observation
import protocol Experiments.FeatureFlagService
import class WooFoundation.VersionHelpers
import protocol Yosemite.POSOrderServiceProtocol
import class Yosemite.POSOrderService
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PluginsServiceProtocol
import protocol Yosemite.PaymentCaptureCelebrationProtocol
import class Yosemite.PaymentCaptureCelebration
import struct Yosemite.Order
import struct Yosemite.POSCart
import struct Yosemite.POSCartItem
import struct Yosemite.POSCoupon
import struct Yosemite.CouponsError
import enum Yosemite.OrderAction
import enum Yosemite.OrderUpdateField
import enum Yosemite.Plugin
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import class Yosemite.PluginsService
import enum WooFoundation.CurrencyCode
import protocol WooFoundation.Analytics
import enum Alamofire.AFError
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError
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

protocol PointOfSaleOrderControllerProtocol {
    var orderState: PointOfSaleInternalOrderState { get }

    @discardableResult
    func syncOrder(for cart: Cart, retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error>
    func sendReceipt(recipientEmail: String) async throws
    func clearOrder()
    func collectCashPayment(changeDueAmount: String?) async throws
}

@Observable final class PointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    init(orderService: POSOrderServiceProtocol,
         receiptSender: POSReceiptSending,
         currencySettingsProvider: POSCurrencySettingsProviding,
         analytics: POSAnalyticsProviding,
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration()) {
        self.orderService = orderService
        self.receiptSender = receiptSender
        self.currencySettingsProvider = currencySettingsProvider
        self.analytics = analytics
        self.celebration = celebration
    }

    private let orderService: POSOrderServiceProtocol
    private let receiptSender: POSReceiptSending
    private let currencySettingsProvider: POSCurrencySettingsProviding
    private let celebration: PaymentCaptureCelebrationProtocol
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

    private func celebrate() {
        celebration.celebrate()
    }

    @MainActor
    func collectCashPayment(changeDueAmount: String?) async throws {
        guard let order = order else {
            throw PointOfSaleOrderControllerError.noOrder
        }

        do {
            try await orderService.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: changeDueAmount)
            celebrate()
        } catch {
            analytics.track(.pointOfSaleCashPaymentFailed)
            throw error
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
                PointOfSaleOrderState.OrderStateError.MissingProductInfo(name: $0.name, quantity: $0.expectedQuantity)
            }
            return .missingProducts(missingProductInfo)
        }
        // Check for server-side validation errors about invalid products/variations
        else if let missingProductInfo = extractMissingProductsFromServerError(error) {
            return .missingProducts(missingProductInfo)
        }
        else if let couponsError = CouponsError(underlyingError: error) {
            return .invalidCoupon(couponsError.message)
        } else if let afErrorDescription = (error as? AFError)?.underlyingError?.localizedDescription {
            return .other(afErrorDescription)
        } else {
            return .other(error.localizedDescription)
        }
    }

    /// Extracts missing product information from server validation errors
    /// Handles cases where the server rejects order creation due to invalid product/variation IDs
    func extractMissingProductsFromServerError(_ error: Error) -> [PointOfSaleOrderState.OrderStateError.MissingProductInfo]? {
        // Check if this is an AFError wrapping a DotcomError or NetworkError
        let underlyingError: Error? = {
            if let afError = error as? AFError {
                return afError.underlyingError
            }
            return error
        }()

        // Check for DotcomError with product/variation validation error codes
        if case .unknown(let code, let message) = underlyingError as? DotcomError {
            if isProductValidationError(code: code) {
                // Try to extract product names from cart since server doesn't return which specific product failed
                return extractMissingProductsFromCart()
            }
        }

        // Check for NetworkError with product/variation validation error codes
        if let networkError = underlyingError as? NetworkError,
           let errorCode = networkError.errorCode,
           isProductValidationError(code: errorCode) {
            return extractMissingProductsFromCart()
        }

        return nil
    }

    /// Checks if an error code indicates a product validation error
    /// Currently only handles the confirmed error code from WooCommerce server responses
    private func isProductValidationError(code: String) -> Bool {
        // Only check for the one confirmed error code we've observed
        // Additional codes can be added as they are discovered through testing
        return code == "order_item_product_invalid_variation_id"
    }

    /// Extracts missing products by trying to identify items in cart that might have caused the validation error
    /// Since server doesn't tell us which specific products failed, we return generic error info
    private func extractMissingProductsFromCart() -> [PointOfSaleOrderState.OrderStateError.MissingProductInfo]? {
        // We can't determine which specific products are invalid from the server error
        // So we return a generic missing product message
        // The user will need to remove products and retry to identify the problematic ones
        return [
            PointOfSaleOrderState.OrderStateError.MissingProductInfo(
                name: Localization.unknownProductName,
                quantity: 1
            )
        ]
    }
}

private extension PointOfSaleOrderController {
    enum Localization {
        static let unknownProductName = NSLocalizedString(
            "pointOfSale.orderController.unknownProduct",
            value: "One or more products",
            comment: "Generic product name used when we can't identify which specific product is unavailable"
        )
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
        } else if extractMissingProductsFromServerError(error) != nil {
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
        let coupons = cart.coupons.map { POSCoupon(id: $0.id, code: $0.code, summary: $0.summary) }
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
