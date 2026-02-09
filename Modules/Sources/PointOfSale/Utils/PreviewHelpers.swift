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
import enum Yosemite.SearchDebounceStrategy
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import enum Yosemite.PointOfSaleBarcodeScanError
import Combine
import struct Yosemite.PaymentIntent
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import struct Yosemite.POSRefund
import struct Yosemite.POSRefundsResult
import typealias Yosemite.OrderItemAttribute
import class Yosemite.POSOrderListService
import class Yosemite.POSOrderListFetchStrategyFactory
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import struct Yosemite.POSBooking
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.BookingPaymentStatus
import enum Yosemite.POSCatalogSyncState
import class Yosemite.POSCatalogSyncStateModel
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
import protocol Yosemite.POSRefundsServiceProtocol
import struct Yosemite.POSRefundableItem
import struct Yosemite.POSRefundAmounts
import struct Yosemite.POSItemIdentifier

// MARK: - PreviewProvider helpers
//
struct POSProductPreview: POSOrderableItem, Equatable {
    let id: POSItemIdentifier
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

    func providePointOfSaleItem() -> POSOrderableItem {
        POSProductPreview(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                          name: "Product 1",
                          formattedPrice: "$1.00")
    }
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
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading(),
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))
    var currentDebounceStrategy: SearchDebounceStrategy { .immediate }
    var searchDebounceStrategy: SearchDebounceStrategy { .smart() }
    func enableCoupons() async { }
    func loadItems(base: ItemListBaseItem) async { }
    func refreshItems(base: ItemListBaseItem) async { }
    func loadNextItems(base: ItemListBaseItem) async { }
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async { }
    func clearSearchItems(baseItem: ItemListBaseItem) { }
}

final class PointOfSalePreviewItemsController: PointOfSaleSearchingItemsControllerProtocol {
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading(),
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))

    var currentDebounceStrategy: SearchDebounceStrategy { .immediate }
    var searchDebounceStrategy: SearchDebounceStrategy { .smart() }

    func loadItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loaded(mockItems, hasMoreItems: true),
                                                                                                  itemStates: [:]))
        case .parent:
            // Set `itemsViewState` instead.
            break
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
}

final class PointOfSalePreviewItemActionHandler: POSItemActionHandler {
    func handleTap(_ item: Yosemite.POSItem, position: Int) { }
}

final class PointOfSalePreviewHistoryService: POSSearchHistoryProviding {
    func saveSuccessfulSearch(term: String, for itemType: POSItemType) {}

    func searchHistory(for itemType: POSItemType) -> [String] {
        return []
    }
}

private var mockItems: [POSItem] {
    return [
        mockSimpleProductItem(id: 1, price: "1.00"),
        mockSimpleProductItem(id: 2, price: "2.00"),
        mockSimpleProductItem(id: 3, price: "3.00"),
        .variableParentProduct(
            .init(
                id: POSItemIdentifier(underlyingType: .product, itemID: 5),
                name: "Variable product 1",
                productImageSource: nil,
                productID: 5
            )
        ),
        mockSimpleProductItem(id: 4, price: "4.00")
    ]
}

private func mockSimpleProductItem(id: Int, price: String) -> POSItem {
    .simpleProduct(POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: Int64(id)),
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
        .variation(.init(id: POSItemIdentifier(underlyingType: .variation, itemID: 256),
                         name: "Variation 1",
                         formattedPrice: "$1.00",
                         price: "1.00",
                         productID: 134,
                         variationID: 256,
                         parentProductName: "Variable product")),
        .variation(.init(id: POSItemIdentifier(underlyingType: .variation, itemID: 257),
                         name: "Variation 2",
                         formattedPrice: "$2.00",
                         price: "2.00",
                         productID: 134,
                         variationID: 257,
                         parentProductName: "Variable product")),
    ]
}

struct POSPreviewHelpers {
    static func makePreviewAggregateModel(
        itemsController: PointOfSaleItemsControllerProtocol = PointOfSalePreviewItemsController(),
        purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = PointOfSalePreviewItemsController(),
        couponsController: PointOfSaleCouponsControllerProtocol = PointOfSalePreviewCouponsController(),
        couponsSearchController: PointOfSaleCouponsControllerProtocol = PointOfSalePreviewCouponsController(),
        cardPresentPaymentService: CardPresentPaymentFacade = CardPresentPaymentPreviewService(),
        orderController: PointOfSaleOrderControllerProtocol = PointOfSalePreviewOrderController(),
        settingsController: POSSettingsControllerProtocol = POSSettingsPreviewController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = POSCollectOrderPaymentPreviewAnalytics(),
        searchHistoryService: POSSearchHistoryProviding = PointOfSalePreviewHistoryService(),
        popularItemsController: PointOfSaleItemsControllerProtocol = PointOfSalePreviewItemsController(),
        barcodeScanService: PointOfSaleBarcodeScanServiceProtocol = PointOfSalePreviewBarcodeScanService(),
        analytics: POSAnalyticsProviding = EmptyPOSAnalytics(),
        siteID: Int64 = 1,
        catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = nil,
        isLocalCatalogEligible: Bool = false
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
            barcodeScanService: barcodeScanService,
            siteID: siteID,
            catalogSyncCoordinator: catalogSyncCoordinator,
            isLocalCatalogEligible: isLocalCatalogEligible
        )
    }

    static func makePreviewOrdersModel(state: POSOrderListState) -> POSOrderListModel {
        return POSOrderListModel(
            ordersController: POSConfigurablePreviewOrderListController(state: state),
            receiptSender: POSReceiptSenderPreview())
    }

    static func makePreviewOrders() -> [POSOrder] {
        return [
            makePreviewOrder(),
            makePreviewFailedOrder(),
            makePreviewOrderWithRefund(),
            makePreviewOrderWithoutEmail(),
            makePreviewOrderWithNetPayment()
        ]
    }

    static func loadedState() -> POSOrderListState {
        return .loaded(makePreviewOrders(), hasMoreItems: false)
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
                             price: 12.50,
                             total: 25.00,
                             totalTax: 2.50,
                             formattedPrice: "$12.50",
                             formattedTotal: "$25.00",
                             imageSrc: nil,
                             attributes: []),
                POSOrderItem(
                    itemID: 2,
                    name: "Organic Tea - Earl Grey",
                    quantity: 1.0,
                    price: 15.99,
                    total: 15.99,
                    totalTax: 1.26,
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
            id: 3,
            number: "1003",
            dateCreated: Date().addingTimeInterval(-7200),
            status: .refunded,
            formattedTotal: "$89.50",
            formattedSubtotal: "$89.96",
            customerEmail: "very.long.customer.email@withverylongdomainname.com",
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "WooCommerce In-Person Payments",
            lineItems: [
                POSOrderItem(
                    itemID: 4,
                    name: "Artisan Chocolate Box",
                    quantity: 3.0,
                    price: 19.99,
                    total: 59.97,
                    totalTax: 5.99,
                    formattedPrice: "$19.99",
                    formattedTotal: "$59.97",
                    imageSrc: nil,
                    attributes: []
                ),
                POSOrderItem(
                    itemID: 5,
                    name: "Gourmet Cookie Set - Mixed",
                    quantity: 1.0,
                    price: 29.99,
                    total: 29.99,
                    totalTax: 2.96,
                    formattedPrice: "$29.99",
                    formattedTotal: "$29.99",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 4, name: "Flavor", value: "Mixed"),
                        OrderItemAttribute(metaID: 5, name: "Packaging", value: "Gift Box")
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

    static func makePreviewFailedOrder() -> POSOrder {
        return POSOrder(
            id: 2,
            number: "1002",
            dateCreated: Date().addingTimeInterval(-3600),
            status: .failed,
            formattedTotal: "$129.99",
            formattedSubtotal: "$120.00",
            customerEmail: nil,
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "WooCommerce In-Person Payments",
            lineItems: [
                POSOrderItem(
                    itemID: 3,
                    name: "Wireless Headphones",
                    quantity: 1.0,
                    price: 120.00,
                    total: 120.00,
                    totalTax: 9.99,
                    formattedPrice: "$120.00",
                    formattedTotal: "$120.00",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 3, name: "Color", value: "Black")
                    ]
                )
            ],
            refunds: [],
            formattedDiscountTotal: "$0.00",
            formattedTotalTax: "$9.99",
            formattedPaymentTotal: "$0.00",
            formattedNetAmount: nil
        )
    }

    static func makePreviewOrderWithoutEmail() -> POSOrder {
        return POSOrder(
            id: 4,
            number: "1004",
            dateCreated: Date().addingTimeInterval(-10800),
            status: .completed,
            formattedTotal: "$24.99",
            formattedSubtotal: "$22.99",
            customerEmail: nil,
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash on Delivery",
            lineItems: [
                POSOrderItem(
                    itemID: 6,
                    name: "Coffee Mug",
                    quantity: 1.0,
                    price: 22.99,
                    total: 22.99,
                    totalTax: 2.00,
                    formattedPrice: "$22.99",
                    formattedTotal: "$22.99",
                    imageSrc: nil,
                    attributes: []
                )
            ],
            refunds: [],
            formattedDiscountTotal: "$0.00",
            formattedTotalTax: "$2.00",
            formattedPaymentTotal: "$24.99",
            formattedNetAmount: nil
        )
    }

    static func makePreviewOrderWithNetPayment() -> POSOrder {
        return POSOrder(
            id: 5,
            number: "1005",
            dateCreated: Date().addingTimeInterval(-14400),
            status: .processing,
            formattedTotal: "$156.47",
            formattedSubtotal: "$145.00",
            customerEmail: "john.doe@example.com",
            paymentMethodID: "woocommerce_payments",
            paymentMethodTitle: "WooCommerce In-Person Payments",
            lineItems: [
                POSOrderItem(
                    itemID: 7,
                    name: "Leather Wallet",
                    quantity: 2.0,
                    price: 45.00,
                    total: 90.00,
                    totalTax: 7.20,
                    formattedPrice: "$45.00",
                    formattedTotal: "$90.00",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 6, name: "Material", value: "Genuine Leather")
                    ]
                ),
                POSOrderItem(
                    itemID: 8,
                    name: "Sunglasses",
                    quantity: 1.0,
                    price: 55.00,
                    total: 55.00,
                    totalTax: 4.27,
                    formattedPrice: "$55.00",
                    formattedTotal: "$55.00",
                    imageSrc: nil,
                    attributes: [
                        OrderItemAttribute(metaID: 7, name: "Frame", value: "Metal"),
                        OrderItemAttribute(metaID: 8, name: "Lens", value: "Polarized")
                    ]
                )
            ],
            refunds: [],
            formattedDiscountTotal: "-$10.00",
            formattedTotalTax: "$11.47",
            formattedPaymentTotal: "$156.47",
            formattedNetAmount: "$153.50"
        )
    }
}

// MARK: - Preview Bookings

final class POSBookingListFetchStrategyFactoryPreview: POSBookingListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> POSBookingListFetchStrategy {
        POSBookingListFetchStrategyPreview()
    }

    func searchStrategy(searchTerm: String) -> POSBookingListFetchStrategy {
        POSBookingListFetchStrategyPreview()
    }
}

final class POSBookingListFetchStrategyPreview: POSBookingListFetchStrategy {
    var supportsCaching: Bool = true
    var showsLoadingWithItems: Bool = false
    var id: String = "BookingPreview"

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        PagedItems(items: [], hasMorePages: false, totalItems: nil)
    }
}

extension POSPreviewHelpers {
    static func makePreviewBookingsModel(state: POSBookingListState = .empty) -> POSBookingsModel {
        let controller = POSConfigurablePreviewBookingListController(state: state)
        return POSBookingsModel(bookingsController: controller)
    }

    static func makePreviewBookings() -> [POSBooking] {
        [
            POSBooking(
                id: 1,
                customerName: "John Smith",
                serviceName: "Haircut",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                formattedAmount: "$45.00",
                bookingStatus: .booked,
                attendanceStatus: .unattended,
                paymentStatus: .unpaid,
                orderID: 101,
                resourceName: "Station A"
            ),
            POSBooking(
                id: 2,
                customerName: "Jane Doe",
                serviceName: "Massage",
                startDate: Date().addingTimeInterval(7200),
                endDate: Date().addingTimeInterval(10800),
                formattedAmount: "$90.00",
                bookingStatus: .booked,
                attendanceStatus: .unattended,
                paymentStatus: .paid,
                orderID: 102,
                resourceName: nil
            ),
            POSBooking(
                id: 3,
                customerName: "Alex Johnson",
                serviceName: "Consultation",
                startDate: Date().addingTimeInterval(-3600),
                endDate: Date(),
                formattedAmount: "$25.00",
                bookingStatus: .cancelled,
                attendanceStatus: .unattended,
                paymentStatus: .unpaid,
                orderID: nil,
                resourceName: nil
            )
        ]
    }
}

final class POSConfigurablePreviewBookingListController: POSSearchingBookingListControllerProtocol {
    let bookingsViewState: POSBookingListState
    var selectedBooking: POSBooking?

    init(state: POSBookingListState) {
        self.bookingsViewState = state
        self.selectedBooking = state.bookings.first
    }

    func loadBookings() async {}
    func refreshBookings() async {}
    func loadNextBookings() async {}
    func selectBooking(_ booking: POSBooking?) { }
    func searchBookings(searchTerm: String) async {}
    func clearSearchBookings() {}
}

// MARK: - Preview Orders Controller
final class POSConfigurablePreviewOrderListController: POSSearchingOrderListControllerProtocol {
    var refundSelectableItems: [POSRefundSelectableItem]
    let ordersViewState: POSOrderListState

    init(state: POSOrderListState) {
        self.ordersViewState = state
        self.refundSelectableItems = []
    }

    var selectedOrder: POSOrder? {
        ordersViewState.orders.first
    }

    var refundActionAvailability: RefundActionAvailability { .available }

    func loadOrders() async {}
    func loadNextOrders() async {}
    func refreshOrders() async {}
    func selectOrder(_ order: POSOrder?) {}
    func updateOrder(orderID: Int64) async throws {}
    func searchOrders(searchTerm: String) async {}
    func clearSearchOrders() {}
    func startRefundFlow() async -> StartRefundFlowResult { .hasItemsToRefund }
    func toggleRefundItemSelection(at index: Int) {}
    func clearRefundSelection() {}
    func toggleAllRefundItemsSelection() {}
    func preparePOSRefundReviewData() -> POSRefundReviewData? { nil }
    func processRefund(reason: String?) async throws {}
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

    func trackSuccessfulCashPayment() {}
}

final class POSOrderServicePreview: POSOrderServiceProtocol {
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        .empty
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {}

    func markOrderAsCompletedWithCashPayment(order: Yosemite.Order, changeDueAmount: String?) async throws {}
}

final class POSRefundsServicePreview: POSRefundsServiceProtocol {
    func providePointOfSaleRefunds(for order: Yosemite.POSOrder) async throws -> Yosemite.POSRefundsResult {
        POSRefundsResult(refunds: [], isFullyRefunded: false, supportsAutomaticRefund: true)
    }

    func calculateRefundAmounts(for items: [Yosemite.POSRefundableItem]) -> Yosemite.POSRefundAmounts {
        let subtotal = items.reduce(Decimal.zero) { $0 + $1.lineItemTotal }
        let tax = items.reduce(Decimal.zero) { $0 + $1.totalTax }
        return POSRefundAmounts(subtotal: subtotal, tax: tax)
    }

    func createRefund(orderID: Int64, items: [Yosemite.POSRefundableItem], reason: String?, isAutomaticRefund: Bool) async throws {}
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
    func performFullSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval, regenerateCatalog: Bool) async throws {
        // Simulates a full sync operation with a 1 second delay.
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func performIncrementalSyncIfApplicable(for siteID: Int64, maxAge: TimeInterval) async throws {
        // Simulates an incremental sync operation with a 0.5 second delay.
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func performSmartSync(for siteID: Int64, fullSyncMaxAge: TimeInterval, incrementalSyncMaxAge: TimeInterval) async throws {
        // Simulates a smart sync operation with a 1 second delay.
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    let fullSyncStateModel = POSCatalogSyncStateModel()

    func loadLastFullSyncState(for siteID: Int64) async -> POSCatalogSyncState {
        return fullSyncStateModel.state[siteID] ?? .syncCompleted(siteID: siteID)
    }

    func isSyncStale(for siteID: Int64, maxDays: Int) async -> Bool {
        return false
    }

    func hoursSinceLastSync(for siteID: Int64) async -> Int? {
        // Preview implementation - return 48 hours for testing stale warning
        return 48
    }

    func stopOngoingSyncs(for siteID: Int64) async {
        // Preview implementation - no-op
    }

    func processBackgroundDownload(fileURL: URL, siteID: Int64) async throws {
        // no-op
    }

    func deleteProductsFromCatalog(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        // no-op
    }

    func startBackgroundFTSRebuildIfNeeded(for siteID: Int64) async {
        // no-op
    }
}

#endif
