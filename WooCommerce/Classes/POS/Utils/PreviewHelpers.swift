#if DEBUG

import Foundation
import WooFoundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import protocol Yosemite.POSOrderableItem
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.OrderSyncProductInput
import enum Yosemite.ProductType
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct
import struct Yosemite.ProductBundleItem
import struct Yosemite.OrderItem
import protocol Yosemite.PointOfSalePurchasableItemFetchStrategy
import struct Yosemite.POSProduct
import struct Yosemite.POSProductVariation
import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import enum Yosemite.PointOfSaleBarcodeScanError
import Combine
import struct Yosemite.PaymentIntent
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import typealias Yosemite.OrderItemAttribute
import class Yosemite.POSOrderListService
import class Yosemite.POSOrderListFetchStrategyFactory
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import protocol Yosemite.POSCatalogSettingsServiceProtocol
import struct Yosemite.POSCatalogInfo
import struct Yosemite.Site
import struct Yosemite.Order
import struct Yosemite.POSCart
import struct Yosemite.POSReceiptInformation
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import protocol Yosemite.PointOfSaleCouponFetchStrategy
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import protocol Yosemite.PointOfSaleItemFetchStrategyFactoryProtocol
import protocol Yosemite.POSItemFetchAnalyticsTracking
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderListFetchStrategy
import protocol Yosemite.PointOfSaleCouponFetchStrategyFactoryProtocol

// MARK: - PreviewProvider helpers
//
struct POSProductPreview: POSOrderableItem, Equatable {
    let id: UUID
    let name: String
    let formattedPrice: String
    var productImageSource: String?

    struct POSProductPreviewType: OrderSyncProductTypeProtocol {
        var price: String = ""
        var productID: Int64 = 0
        var productType: Yosemite.ProductType = .simple
        var bundledItems: [Yosemite.ProductBundleItem] = []
    }

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(product: .product(POSProductPreviewType()), quantity: 1)
    }

    func matches(orderItem: OrderItem) -> Bool {
        return false
    }
}

final class PointOfSalePreviewItemService: PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: true, totalItems: nil)
    }

    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        .init(items: mockVariationItems, hasMorePages: true, totalItems: nil)
    }

    func providePointOfSaleItems() -> [POSItem] {
        return mockItems
    }

    func providePointOfSaleItem() -> POSOrderableItem {
        POSProductPreview(id: UUID(),
                          name: "Product 1",
                          formattedPrice: "$1.00")
    }

    var fetchStrategy: PointOfSalePurchasableItemFetchStrategy = PointOfSalePreviewPurchasableItemFetchStrategy()
}

struct PointOfSalePreviewPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return .init(items: [], hasMorePages: true, totalItems: nil)
    }

    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        return .init(items: [], hasMorePages: true, totalItems: nil)
    }
}

final class PointOfSalePreviewCouponsController: PointOfSaleCouponsControllerProtocol {
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))
    func enableCoupons() async { }
    func loadItems(base: ItemListBaseItem) async { }
    func refreshItems(base: ItemListBaseItem) async { }
    func loadNextItems(base: ItemListBaseItem) async { }
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async { }
    func clearSearchItems(baseItem: ItemListBaseItem) { }
}

final class PointOfSalePreviewItemsController: PointOfSaleSearchingItemsControllerProtocol {
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { $itemsViewState }

    func loadItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loaded(mockItems, hasMoreItems: true),
                                                                                                  itemStates: [:]))
        case .parent(let parent):
            await loadInitialChildItems(for: parent)
        }
    }

    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {}

    func clearSearchItems(baseItem: ItemListBaseItem) { }

    func refreshItems(base: ItemListBaseItem) async {
        await loadItems(base: base)
    }

    func loadNextItems(base: ItemListBaseItem) async {
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loading(mockItems),
                                                                                              itemStates: [:]))
    }

    private func loadInitialChildItems(for parent: POSItem) async {
        // Set `itemsViewState` instead.
    }
}

final class PointOfSalePreviewItemActionHandler: POSItemActionHandler {
    func handleTap(_ item: Yosemite.POSItem) { }
}

final class PointOfSalePreviewHistoryService: POSSearchHistoryProviding {
    func saveSuccessfulSearch(term: String, for itemType: POSItemType) {}

    func searchHistory(for itemType: POSItemType) -> [String] {
        return []
    }

    func clearSearchHistory(for itemType: POSItemType) {}

    func clearAllSearchHistory() {}
}

private var mockItems: [POSItem] {
    return [
        mockSimpleProductItem(id: 1, price: "1.00"),
        mockSimpleProductItem(id: 2, price: "2.00"),
        mockSimpleProductItem(id: 3, price: "3.00"),
        .variableParentProduct(
            .init(
                id: .init(),
                name: "Variable product 1",
                productImageSource: nil,
                productID: 5
            )
        ),
        mockSimpleProductItem(id: 4, price: "4.00")
    ]
}

private func mockSimpleProductItem(id: Int, price: String) -> POSItem {
    .simpleProduct(POSSimpleProduct(id: UUID(),
                                    name: "Product \(id)",
                                    formattedPrice: "$\(price)",
                                    productID: Int64(id),
                                    price: price,
                                    manageStock: false,
                                    stockQuantity: nil,
                                    stockStatusKey: ""))
}

private var mockVariationItems: [POSItem] {
    [
        .variation(.init(id: UUID(),
                         name: "Variation 1",
                         formattedPrice: "$1.00",
                         price: "1.00",
                         productID: 134,
                         variationID: 256,
                         parentProductName: "Variable product")),
        .variation(.init(id: UUID(),
                         name: "Variation 2",
                         formattedPrice: "$2.00",
                         price: "2.00",
                         productID: 134,
                         variationID: 256,
                         parentProductName: "Variable product")),
    ]
}

final class POSConnectivityObserverPreview: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .unknown
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        $currentStatus.eraseToAnyPublisher()
    }
    func startObserving() {}

    func stopObserving() {}
}

struct POSPreviewHelpers {
    static func makePreviewAggregateModel(
        itemsController: PointOfSaleItemsControllerProtocol = PointOfSalePreviewItemsController(),
        purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = PointOfSalePreviewItemsController(),
        couponsController: PointOfSaleCouponsControllerProtocol = PointOfSalePreviewCouponsController(),
        couponsSearchController: PointOfSaleCouponsControllerProtocol = PointOfSalePreviewCouponsController(),
        cardPresentPaymentService: CardPresentPaymentFacade = CardPresentPaymentPreviewService(),
        orderController: PointOfSaleOrderControllerProtocol = PointOfSalePreviewOrderController(),
        settingsController: PointOfSaleSettingsControllerProtocol = PointOfSaleSettingsPreviewController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = POSCollectOrderPaymentPreviewAnalytics(),
        searchHistoryService: POSSearchHistoryProviding = PointOfSalePreviewHistoryService(),
        popularItemsController: PointOfSaleItemsControllerProtocol = PointOfSalePreviewItemsController(),
        barcodeScanService: PointOfSaleBarcodeScanServiceProtocol = PointOfSalePreviewBarcodeScanService(),
        analytics: POSAnalyticsProviding = EmptyPOSAnalytics()
    ) -> PointOfSaleAggregateModel {
        return PointOfSaleAggregateModel(
            entryPointController: POSEntryPointController(eligibilityChecker: PointOfSalePreviewTabEligibilityChecker()),
            itemsController: itemsController,
            purchasableItemsSearchController: purchasableItemsSearchController,
            couponsController: couponsController,
            couponsSearchController: couponsSearchController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController,
            settingsController: settingsController,
            analytics: analytics,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            searchHistoryService: searchHistoryService,
            popularPurchasableItemsController: popularItemsController,
            barcodeScanService: barcodeScanService
        )
    }

    static func makePreviewOrdersModel(state: POSOrderListState) -> POSOrderListModel {
        return POSOrderListModel(
            ordersController: POSConfigurablePreviewOrderListController(state: state),
            receiptSender: POSReceiptSenderPreview())
    }

    static func makePreviewOrder() -> POSOrder {
        return POSOrder(
            id: 1,
            number: "1001",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$45.75",
            formattedSubtotal: "$41.99",
            customerEmail: "customer@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash on Delivery",
            lineItems: [
                POSOrderItem(itemID: 1,
                             name: "Premium Coffee Beans",
                             quantity: 2.0,
                             formattedPrice: "$12.50",
                             formattedTotal: "$25.00",
                             imageSrc: nil,
                             attributes: []),
                POSOrderItem(
                    itemID: 2,
                    name: "Organic Tea - Earl Grey",
                    quantity: 1.0,
                    formattedPrice: "$15.99",
                    formattedTotal: "$15.99",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 1, name: "Size", value: "Large"),
                        OrderItemAttribute(metaID: 2, name: "Type", value: "Loose Leaf")
                    ]
                )
            ],
            refunds: [],
            formattedDiscountTotal: "$0.00",
            formattedTotalTax: "$3.76",
            formattedPaymentTotal: "$45.75",
            formattedNetAmount: nil
        )
    }

    static func makePreviewOrderWithRefund() -> POSOrder {
        return POSOrder(
            id: 2,
            number: "1002",
            dateCreated: Date().addingTimeInterval(-3600),
            status: .completed,
            formattedTotal: "$89.50",
            formattedSubtotal: "$89.96",
            customerEmail: "customer.with.refund@example.com",
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "WooCommerce In-Person Payments",
            lineItems: [
                POSOrderItem(
                    itemID: 3,
                    name: "Artisan Chocolate Box",
                    quantity: 3.0,
                    formattedPrice: "$19.99",
                    formattedTotal: "$59.97",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 4,
                    name: "Gourmet Cookie Set - Mixed",
                    quantity: 1.0,
                    formattedPrice: "$29.99",
                    formattedTotal: "$29.99",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 3, name: "Flavor", value: "Mixed"),
                        OrderItemAttribute(metaID: 4, name: "Packaging", value: "Gift Box")
                    ]
                )
            ],
            refunds: [
                POSOrderRefund(
                    refundID: 1,
                    formattedTotal: "-$19.99",
                    reason: "Customer requested partial refund"
                )
            ],
            formattedDiscountTotal: "-$15.00",
            formattedTotalTax: "$8.95",
            formattedPaymentTotal: "$89.50",
            formattedNetAmount: "$69.51"
        )
    }
}

// MARK: - Preview Orders Controller
final class POSConfigurablePreviewOrderListController: POSSearchingOrderListControllerProtocol {
    let ordersViewState: POSOrderListState

    init(state: POSOrderListState? = nil) {
        let orders = [
            POSOrder(
                id: 1,
                number: "1001",
                dateCreated: Date(),
                status: .completed,
                formattedTotal: "$45.75",
                formattedSubtotal: "$40.99",
                customerEmail: "customer@example.com",
                paymentMethodID: "cod",
                paymentMethodTitle: "Cash on Delivery",
                lineItems: [
                    POSOrderItem(itemID: 1,
                                 name: "Premium Coffee Beans",
                                 quantity: 2.0,
                                 formattedPrice: "$12.50",
                                 formattedTotal: "$25.00",
                                 imageSrc: nil,
                                 attributes: []),
                    POSOrderItem(
                        itemID: 2,
                        name: "Organic Tea - Earl Grey",
                        quantity: 1.0,
                        formattedPrice: "$15.99",
                        formattedTotal: "$15.99",
                        imageSrc: nil,
                        attributes: [
                            OrderItemAttribute(metaID: 1, name: "Size", value: "Large"),
                            OrderItemAttribute(metaID: 2, name: "Type", value: "Loose Leaf")
                        ]
                    )
                ],
                refunds: [],
                formattedDiscountTotal: "-$5.24",
                formattedTotalTax: "$4.75",
                formattedPaymentTotal: "$45.75",
                formattedNetAmount: nil
            ),
            POSOrder(
                id: 2,
                number: "1002",
                dateCreated: Date().addingTimeInterval(-3600),
                status: .processing,
                formattedTotal: "$89.50",
                formattedSubtotal: "$89.96",
                customerEmail: "very.long.customer.email@withverylongdomainname.com",
                paymentMethodID: "woocommerce_payments",
                paymentMethodTitle: "WooCommerce Payments",
                lineItems: [
                    POSOrderItem(
                        itemID: 3,
                        name: "Artisan Chocolate Box",
                        quantity: 3.0,
                        formattedPrice: "$19.99",
                        formattedTotal: "$59.97",
                        imageSrc: nil,
                        attributes: []
                    ),
                    POSOrderItem(
                        itemID: 4,
                        name: "Gourmet Cookie Set - Mixed",
                        quantity: 1.0,
                        formattedPrice: "$29.99",
                        formattedTotal: "$29.99",
                        imageSrc: nil,
                        attributes: [
                            OrderItemAttribute(metaID: 3, name: "Flavor", value: "Mixed"),
                            OrderItemAttribute(metaID: 4, name: "Packaging", value: "Gift Box")
                        ]
                    )
                ],
                refunds: [
                    POSOrderRefund(
                        refundID: 1,
                        formattedTotal: "-$19.99",
                        reason: "Customer requested partial refund"
                    )
                ],
                formattedDiscountTotal: "-$15.00",
                formattedTotalTax: "$8.95",
                formattedPaymentTotal: "$89.50",
                formattedNetAmount: "$69.51"
            )
        ]
        self.ordersViewState = state ?? .loaded(orders, hasMoreItems: false)
    }

    var selectedOrder: POSOrder? {
        ordersViewState.orders.first
    }

    func loadOrders() async {}
    func loadNextOrders() async {}
    func refreshOrders() async {}
    func selectOrder(_ order: POSOrder?) {}
    func updateOrder(orderID: Int64) async throws {}
    func searchOrders(searchTerm: String) async {}
    func clearSearchOrders() {}
}

// MARK: - Barcode Scan Service
final class PointOfSalePreviewBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        return mockSimpleProductItem(id: 5, price: "35.50")
    }
}

final class PointOfSalePreviewTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    func checkEligibility() async -> POSEligibilityState { .eligible }
    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState { .eligible }
}

final class POSReceiptSenderPreview: POSReceiptSending {
    func sendReceipt(orderID: Int64, recipientEmail: String) async throws {}
}

final class POSCollectOrderPaymentPreviewAnalytics: POSCollectOrderPaymentAnalyticsTracking {
    func trackCustomerInteractionStarted() {}

    func trackOrderSyncSuccess() {}

    func trackCardReaderReady() {}

    func trackCardReaderTapped() {}

    func trackCheckoutTapped() {}

    func resetCheckoutTapCountTracker() {}

    func trackSuccessfulCashPayment() {}
}

final class POSOrderServicePreview: POSOrderServiceProtocol {
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        .empty
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {}

    func markOrderAsCompletedWithCashPayment(order: Yosemite.Order, changeDueAmount: String?) async throws {}
}

final class POSReceiptServicePreview: POSReceiptServiceProtocol {
    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws {}
}

final class PointOfSaleCouponServicePreview: PointOfSaleCouponServiceProtocol {
    func provideLocalPointOfSaleCoupons(fetchStrategy: any PointOfSaleCouponFetchStrategy) async throws -> [POSItem] {
        []
    }

    func providePointOfSaleCoupons(pageNumber: Int, fetchStrategy: any Yosemite.PointOfSaleCouponFetchStrategy) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: false, totalItems: 0)
    }

    func enableCoupons() async throws {}
}

final class PointOfSaleSettingsServicePreview: PointOfSaleSettingsServiceProtocol {
    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation {
        .empty
    }
}

final class PointOfSaleItemFetchStrategyFactoryPreview: PointOfSaleItemFetchStrategyFactoryProtocol {
    func defaultStrategy(analytics: any POSItemFetchAnalyticsTracking) -> any PointOfSalePurchasableItemFetchStrategy {
        PointOfSalePreviewPurchasableItemFetchStrategy()
    }

    func searchStrategy(searchTerm: String, analytics: any POSItemFetchAnalyticsTracking) -> any PointOfSalePurchasableItemFetchStrategy {
        PointOfSalePreviewPurchasableItemFetchStrategy()
    }
}

final class POSOrderListFetchStrategyFactoryPreview: POSOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> any POSOrderListFetchStrategy {
        POSOrderListFetchStrategyPreview()
    }

    func searchStrategy(searchTerm: String) -> any Yosemite.POSOrderListFetchStrategy {
        POSOrderListFetchStrategyPreview()
    }
}

final class POSOrderListFetchStrategyPreview: POSOrderListFetchStrategy {
    func trackFetched(millisecondsSinceRequestSent: Int) {}

    func trackNextPageLoaded(pageNumber: Int) {}

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        POSPreviewHelpers.makePreviewOrder()
    }

    var supportsCaching: Bool = true

    var showsLoadingWithItems: Bool = false

    var id: String = ""

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        PagedItems(items: [], hasMorePages: false, totalItems: nil)
    }
}

final class PointOfSaleCouponFetchStrategyPreview: PointOfSaleCouponFetchStrategy {
    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        []
    }
}

final class PointOfSaleCouponFetchStrategyFactoryPreview: PointOfSaleCouponFetchStrategyFactoryProtocol {
    let defaultStrategy: PointOfSaleCouponFetchStrategy = PointOfSaleCouponFetchStrategyPreview()

    func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleCouponFetchStrategy {
        PointOfSaleCouponFetchStrategyPreview()
    }
}

final class POSPreviewServices: POSDependencyProviding {
    var analytics: POSAnalyticsProviding = EmptyPOSAnalytics()
    var currency: POSCurrencySettingsProviding = EmptyPOSCurrencySettings()
    var featureFlags: POSFeatureFlagProviding = EmptyPOSFeatureFlags()
    var connectivity: POSConnectivityProviding = EmptyPOSConnectivityProvider()
    var externalNavigation: POSExternalNavigationProviding = EmptyPOSExternalNavigation()
    var externalViews: POSExternalViewProviding = EmptyPOSExternalView()
}

// MARK: - Preview Catalog Services

final class POSPreviewCatalogSettingsService: POSCatalogSettingsServiceProtocol {
    func loadCatalogInfo(for siteID: Int64) async throws -> POSCatalogInfo {
        let now = Date()
        let lastFullSync = now.addingTimeInterval(-2 * 60 * 60) // 2 hours ago
        let lastIncrementalSync = now.addingTimeInterval(-15 * 60) // 15 minutes ago
        return POSCatalogInfo(
            productCount: 247,
            variationCount: 89,
            lastFullSyncDate: lastFullSync,
            lastIncrementalSyncDate: lastIncrementalSync
        )
    }
}

final class POSPreviewCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol {
    func performFullSync(for siteID: Int64) async throws {
        // Simulates a full sync operation with a 1 second delay.
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func shouldPerformFullSync(for siteID: Int64, maxAge: TimeInterval) async -> Bool {
        true
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, forceSync: Bool) async throws {
        // Simulates an incremental sync operation with a 0.5 second delay.
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}

#endif
