import Foundation
import Observation
import protocol Experiments.FeatureFlagService
import protocol Yosemite.StoresManager
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PluginsServiceProtocol
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
         receiptService: POSReceiptServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager),
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration()) {
        self.orderService = orderService
        self.receiptService = receiptService
        self.stores = stores
        self.storeCurrency = currencySettings.currencyCode
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.pluginsService = pluginsService
        self.celebration = celebration
    }

    private let orderService: POSOrderServiceProtocol
    private let receiptService: POSReceiptServiceProtocol

    private let currencyFormatter: CurrencyFormatter
    private let celebration: PaymentCaptureCelebrationProtocol
    private let storeCurrency: CurrencyCode
    private let analytics: Analytics
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let pluginsService: PluginsServiceProtocol

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
        var isEligibleForPOSReceipt: Bool = false
        do {
            guard let order else {
                throw PointOfSaleOrderControllerError.noOrder
            }

            try await orderService.updatePOSOrder(order: order, recipientEmail: recipientEmail)

            isEligibleForPOSReceipt = isPluginSupported(
                .wooCommerce,
                minimumVersion: POSReceiptEligibilityConstants.wcPluginMinimumVersion,
                siteID: order.siteID
            )

            try await receiptService.sendReceipt(order: order, recipientEmail: recipientEmail, isEligibleForPOSReceipt: isEligibleForPOSReceipt)

            analytics.track(.receiptEmailSuccess, withProperties: ["eligible_for_pos_receipt": isEligibleForPOSReceipt])
        } catch {
            let properties = [
                "eligible_for_pos_receipt": isEligibleForPOSReceipt
            ].compactMapValues( { $0 })
            analytics.track(.receiptEmailFailed, properties: properties, error: error)
            throw error
        }
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

private extension PointOfSaleOrderController {
    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String, siteID: Int64) -> Bool {
        // Plugin must be installed and active
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true),
              systemPlugin.active else {
            return false
        }

        // If plugin version is higher than minimum required version, mark as eligible
        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion,
                                                            includesDevAndBetaVersions: true)
        return isSupported
    }
}


// MARK: - Error Handling

private extension PointOfSaleOrderController {
    func orderStateError(from error: Error) -> PointOfSaleOrderState.OrderStateError {
        if let couponsError = CouponsError(underlyingError: error) {
            return .invalidCoupon(couponsError.message)
        } else if let afErrorDescription = (error as? AFError)?.underlyingError?.localizedDescription {
            return .other(afErrorDescription)
        } else {
            return .other(error.localizedDescription)
        }
    }
}

private extension PointOfSaleOrderController {
    enum POSReceiptEligibilityConstants {
        static let wcPluginMinimumVersion = "10.0.0"
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
        case noSiteID
        case noOrder
    }
}


private extension PointOfSaleOrderController {
    func trackOrderCreationFailed(error: Error) {
        var errorType: WooAnalyticsEvent.Orders.OrderCreationErrorType?

        if let _ = CouponsError(underlyingError: error) {
            errorType = .invalidCoupon
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
