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
import class Yosemite.PointOfSaleOrderService
import class Yosemite.PointOfSaleOrderFetchStrategyFactory

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
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            searchHistoryService: searchHistoryService,
            popularPurchasableItemsController: popularItemsController,
            barcodeScanService: barcodeScanService
        )
    }

    static func makePreviewOrdersModel() -> PointOfSaleOrdersModel {
        return PointOfSaleOrdersModel(ordersController: PointOfSalePreviewOrdersController())
    }
}

// MARK: - Preview Orders Controller
final class PointOfSalePreviewOrdersController: PointOfSaleOrdersControllerProtocol {
    var ordersViewState: OrderListState {
        .loaded(
                [
                    POSOrder(
                        id: 1,
                        number: "1001",
                        dateCreated: Date(),
                        status: .completed,
                        total: "25.00",
                        customerEmail: "customer1@example.com",
                        paymentMethodTitle: "Credit Card",
                        lineItems: [],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$"
                    ),
                    POSOrder(
                        id: 2,
                        number: "1002",
                        dateCreated: Date().addingTimeInterval(-3600),
                        status: .processing,
                        total: "45.50",
                        customerEmail: "customer2@example.com",
                        paymentMethodTitle: "Cash",
                        lineItems: [],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$"
                    ),
                    POSOrder(
                        id: 3,
                        number: "1003",
                        dateCreated: Date().addingTimeInterval(-7200),
                        status: .completed,
                        total: "12.75",
                        customerEmail: nil,
                        paymentMethodTitle: "Credit Card",
                        lineItems: [],
                        refunds: [],
                        currency: "USD",
                        currencySymbol: "$"
                    )
                ],
                hasMoreItems: false
            )
    }

    func loadOrders() async {}
    func loadNextOrders() async {}
    func refreshOrders() async { }
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
