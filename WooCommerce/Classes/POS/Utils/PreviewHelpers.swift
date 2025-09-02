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
import class Yosemite.PointOfSaleOrderListService
import class Yosemite.PointOfSaleOrderListFetchStrategyFactory

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
        barcodeScanService: PointOfSaleBarcodeScanServiceProtocol = PointOfSalePreviewBarcodeScanService()
    ) -> PointOfSaleAggregateModel {
        return PointOfSaleAggregateModel(
            entryPointController: POSEntryPointController(eligibilityChecker: LegacyPOSTabEligibilityChecker(siteID: 0)),
            itemsController: itemsController,
            purchasableItemsSearchController: purchasableItemsSearchController,
            couponsController: couponsController,
            couponsSearchController: couponsSearchController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController,
            settingsController: settingsController,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            searchHistoryService: searchHistoryService,
            popularPurchasableItemsController: popularItemsController,
            barcodeScanService: barcodeScanService
        )
    }

    static func makePreviewOrdersModel() -> PointOfSaleOrderListModel {
        return PointOfSaleOrderListModel(ordersController: PointOfSalePreviewOrderListController())
    }

    static func makePreviewOrder() -> POSOrder {
        return POSOrder(
            id: 1,
            number: "1001",
            dateCreated: Date(),
            datePaid: Date(),
            status: .completed,
            total: "45.75",
            customerEmail: "customer@example.com",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash on Delivery",
            lineItems: [
                POSOrderItem(itemID: 1,
                             name: "Premium Coffee Beans",
                             productID: 101,
                             variationID: 0,
                             quantity: 2.0,
                             price: NSDecimalNumber(string: "12.50"), subtotal: "25.00", total: "25.00", attributes: []),
                POSOrderItem(
                    itemID: 2,
                    name: "Organic Tea - Earl Grey",
                    productID: 102,
                    variationID: 203,
                    quantity: 1.0,
                    price: NSDecimalNumber(string: "15.99"),
                    subtotal: "15.99",
                    total: "15.99",
                    attributes: [
                        OrderItemAttribute(metaID: 1, name: "Size", value: "Large"),
                        OrderItemAttribute(metaID: 2, name: "Type", value: "Loose Leaf")
                    ]
                )
            ],
            refunds: [],
            currency: "USD",
            currencySymbol: "$",
            discountTotal: "0.00",
            totalTax: "3.76"
        )
    }
}

// MARK: - Preview Orders Controller
final class PointOfSalePreviewOrderListController: PointOfSaleOrderListControllerProtocol {
    var ordersViewState: OrderListState {
        .loaded(
                [
                    POSOrder(
                        id: 1,
                        number: "1001",
                        dateCreated: Date(),
                        datePaid: Date(),
                        status: .completed,
                        total: "45.75",
                        customerEmail: "customer@example.com",
                        paymentMethodID: "cod",
                        paymentMethodTitle: "Cash on Delivery",
                        lineItems: [
                            POSOrderItem(itemID: 1,
                                         name: "Premium Coffee Beans",
                                         productID: 101,
                                         variationID: 0,
                                         quantity: 2.0,
                                         price: NSDecimalNumber(string: "12.50"), subtotal: "25.00", total: "25.00", attributes: []),
                            POSOrderItem(
                                itemID: 2,
                                name: "Organic Tea - Earl Grey",
                                productID: 102,
                                variationID: 203,
                                quantity: 1.0,
                                price: NSDecimalNumber(string: "15.99"),
                                subtotal: "15.99",
                                total: "15.99",
                                attributes: [
                                    OrderItemAttribute(metaID: 1, name: "Size", value: "Large"),
                                    OrderItemAttribute(metaID: 2, name: "Type", value: "Loose Leaf")
                                ]
                            )
                        ],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "-5.24",
                        totalTax: "4.75"
                    ),

                    // Order with refunds and long customer email
                    POSOrder(
                        id: 2,
                        number: "1002",
                        dateCreated: Date().addingTimeInterval(-3600),
                        datePaid: Date().addingTimeInterval(-3000),
                        status: .processing,
                        total: "89.50",
                        customerEmail: "very.long.customer.email@withverylongdomainname.com",
                        paymentMethodID: "woocommerce_payments",
                        paymentMethodTitle: "WooCommerce Payments",
                        lineItems: [
                            POSOrderItem(
                                itemID: 3,
                                name: "Artisan Chocolate Box",
                                productID: 103,
                                variationID: 0,
                                quantity: 3.0,
                                price: NSDecimalNumber(string: "19.99"),
                                subtotal: "59.97",
                                total: "59.97",
                                attributes: []
                            ),
                            POSOrderItem(
                                itemID: 4,
                                name: "Gourmet Cookie Set - Mixed",
                                productID: 104,
                                variationID: 401,
                                quantity: 1.0,
                                price: NSDecimalNumber(string: "29.99"),
                                subtotal: "29.99",
                                total: "29.99",
                                attributes: [
                                    OrderItemAttribute(metaID: 3, name: "Flavor", value: "Mixed"),
                                    OrderItemAttribute(metaID: 4, name: "Packaging", value: "Gift Box")
                                ]
                            )
                        ],
                        refunds: [
                            POSOrderRefund(
                                refundID: 1,
                                total: "-19.99",
                                reason: "Customer requested partial refund"
                            )
                        ],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "-15.00",
                        totalTax: "8.95"
                    ),

                    // Simple order without customer, no discount, no tax
                    POSOrder(
                        id: 3,
                        number: "1003",
                        dateCreated: Date().addingTimeInterval(-7200),
                        datePaid: Date().addingTimeInterval(-7000),
                        status: .completed,
                        total: "12.50",
                        customerEmail: nil,
                        paymentMethodID: "stripe",
                        paymentMethodTitle: "Credit Card (Stripe)",
                        lineItems: [
                            POSOrderItem(
                                itemID: 5,
                                name: "Simple Product",
                                productID: 105,
                                variationID: 0,
                                quantity: 1.0,
                                price: NSDecimalNumber(string: "12.50"),
                                subtotal: "12.50",
                                total: "12.50",
                                attributes: []
                            )
                        ],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "0.00",
                        totalTax: "0.00"
                    ),

                    // Failed order with single item and variation (no datePaid = unpaid)
                    POSOrder(
                        id: 4,
                        number: "1004",
                        dateCreated: Date().addingTimeInterval(-10800),
                        datePaid: nil,
                        status: .failed,
                        total: "35.25",
                        customerEmail: "test@test.com",
                        paymentMethodID: "bacs",
                        paymentMethodTitle: "Bank Transfer",
                        lineItems: [
                            POSOrderItem(
                                itemID: 6,
                                name: "Variable Product - Red Large",
                                productID: 106,
                                variationID: 601,
                                quantity: 1.0,
                                price: NSDecimalNumber(string: "32.00"),
                                subtotal: "32.00",
                                total: "32.00",
                                attributes: [
                                    OrderItemAttribute(metaID: 5, name: "Color", value: "Red"),
                                    OrderItemAttribute(metaID: 6, name: "Size", value: "Large")
                                ]
                            )
                        ],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "0.00",
                        totalTax: "3.25"
                    ),

                    // Order with high discount and multiple refunds
                    POSOrder(
                        id: 5,
                        number: "1005",
                        dateCreated: Date().addingTimeInterval(-14400),
                        datePaid: Date().addingTimeInterval(-14000),
                        status: .completed,
                        total: "78.90",
                        customerEmail: "big.order@company.co.uk",
                        paymentMethodID: "cod",
                        paymentMethodTitle: "Cash on Delivery",
                        lineItems: [
                            POSOrderItem(
                                itemID: 7,
                                name: "Bulk Product Pack",
                                productID: 107,
                                variationID: 0,
                                quantity: 5.0,
                                price: NSDecimalNumber(string: "19.99"),
                                subtotal: "99.95",
                                total: "99.95",
                                attributes: []
                            ),
                            POSOrderItem(
                                itemID: 8,
                                name: "Accessory Kit - Premium",
                                productID: 108,
                                variationID: 801,
                                quantity: 2.0,
                                price: NSDecimalNumber(string: "24.99"),
                                subtotal: "49.98",
                                total: "49.98",
                                attributes: [
                                    OrderItemAttribute(metaID: 7, name: "Model", value: "Premium"),
                                    OrderItemAttribute(metaID: 8, name: "Color", value: "Black")
                                ]
                            )
                        ],
                        refunds: [
                            POSOrderRefund(
                                refundID: 3,
                                total: "-25.50",
                                reason: "Damaged item replacement"
                            ),
                            POSOrderRefund(
                                refundID: 4,
                                total: "-15.75",
                                reason: "Customer satisfaction"
                            ),
                            POSOrderRefund(refundID: 5, total: "-8.25", reason: nil)
                        ],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "-25.00",
                        totalTax: "7.89"
                    ),

                    // Order with zero tax and zero discount (on hold = unpaid)
                    POSOrder(
                        id: 6,
                        number: "1006",
                        dateCreated: Date().addingTimeInterval(-18000),
                        datePaid: nil,
                        status: .onHold,
                        total: "22.00",
                        customerEmail: nil,
                        paymentMethodID: "cheque",
                        paymentMethodTitle: "Check Payment",
                        lineItems: [
                            POSOrderItem(
                                itemID: 9,
                                name: "Tax-free Item",
                                productID: 109,
                                variationID: 0,
                                quantity: 2.0,
                                price: NSDecimalNumber(string: "11.00"),
                                subtotal: "22.00",
                                total: "22.00",
                                attributes: []
                            )
                        ],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$",
                        discountTotal: "0.00",
                        totalTax: "0.00"
                    )
                ],
                hasMoreItems: false
            )
    }

    var selectedOrder: POSOrder? {
        ordersViewState.orders.first
    }

    func loadOrders() async {}
    func loadNextOrders() async {}
    func refreshOrders() async {}
    func selectOrder(_ order: POSOrder?) {}
}

// MARK: - Barcode Scan Service
final class PointOfSalePreviewBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        return mockSimpleProductItem(id: 5, price: "35.50")
    }
}

final class POSCollectOrderPaymentPreviewAnalytics: POSCollectOrderPaymentAnalyticsTracking {
    func trackCustomerInteractionStarted() {}

    func trackOrderSyncSuccess() {}

    func trackCardReaderReady() {}

    func trackCardReaderTapped() {}

    func trackCheckoutTapped() {}

    func resetCheckoutTapCountTracker() {}

    func trackSuccessfulCashPayment() {}

    var connectedReaderModel: String?

    func preflightResultReceived(_ result: CardReaderPreflightResult?) {}

    func trackProcessingCompletion(intent: PaymentIntent) {}

    func trackSuccessfulCardPayment(capturedPaymentData: CardPresentCapturedPaymentData) {}

    func trackPaymentFailure(with error: any Error) {}

    func trackPaymentCancelation(cancelationSource: WooAnalyticsEvent.InPersonPayments.CancellationSource) {}

    func trackEmailTapped() {}

    func trackReceiptPrintTapped() {}

    func trackReceiptPrintSuccess() {}

    func trackReceiptPrintCanceled() {}

    func trackReceiptPrintFailed(error: any Error) {}
}

#endif
