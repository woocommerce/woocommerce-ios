import Foundation
import enum Yosemite.CardPresentPaymentOnboardingState
import enum Yosemite.POSItemType
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation
import enum WooFoundation.CountryCode
import enum Yosemite.PaymentMethod
import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    public enum PointOfSale {
        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
            static let itemType = "item_type"
            static let productType = "product_type"
            static let productsInCart = "products_in_cart"
            static let couponsInCart = "coupons_in_cart"
            static let millisecondsSinceCustomerInteractionStarted = "milliseconds_since_customer_interaction_started"
            static let millisecondsSinceOrderSyncSuccess = "milliseconds_since_order_sync_success"
            static let millisecondsSinceReaderReadyToCollect = "milliseconds_since_reader_ready_to_collect_payment"
            static let millisecondsSinceCardTapped = "milliseconds_since_card_tapped"
            static let checkoutTapCount = "checkout_tap_count"
            static let waitingTime = "waiting_time"
            static let type = "type"
            static let sourceView = "source"
            static let sourceViewType = "source_type"
            static let resultsCount = "results_count"
            static let millisecondsSinceRequestSent = "milliseconds_since_request_sent"
            static let totalItems = "total_items"
            static let cardReaderModel = "card_reader_model"
            static let countryCode = "country"
            static let paymentMethodType = "payment_method_type"
            static let gatewayID = "plugin_slug"
            static let scanDurationMs = "scan_duration_ms"
            static let barcodeLength = "barcode_length"
            static let failReason = "fail_reason"
            static let scanner = "scanner"
            static let step = "step"
            static let scanValue = "scan_value"
            static let orderID = "order_id"
            static let orderStatus = "order_status"
            static let listPosition = "list_position"
            static let daysSinceCreated = "days_since_created"
            static let pageNumber = "page_number"
            static let reason = "reason"
            static let syncStrategy = "sync_strategy"
            static let searchMethod = "search_method"
            static let resultPosition = "result_position"
            static let bookingID = "booking_id"
            static let bookingStatus = "booking_status"
            static let paymentStatus = "payment_status"
        }

        /// Source of the event where the event is triggered
        /// Views: Product, Variation, and Coupon Lists. Cart view and Checkout error.
        ///
        enum SourceView: String {
            case product
            case variation
            case coupon
            case cart
            case error

            init(itemType: POSItemType) {
                switch itemType {
                case .product:
                    self = .product
                case .variation:
                    self = .variation
                case .coupon:
                    self = .coupon
                }
            }

            init(itemListType: ItemListType) {
                switch itemListType {
                case .products:
                    self = .product
                case .coupons:
                    self = .coupon
                }
            }
        }

        /// The state of the view where the event is triggered.
        /// E.g. product list, procuct search, or product pre-search view where popular searches are shown.
        ///
        enum SourceViewType: String {
            case list
            case search
            case preSearch = "pre_search"
            case scanner

            init(isSearching: Bool, searchTerm: String = "") {
                switch (isSearching, searchTerm.isEmpty) {
                case (false, _):
                    self = .list
                case (true, true):
                    self = .preSearch
                case (true, false):
                    self = .search
                }
            }
        }

        /// Types of high-level items supported in the POS
        ///
        enum ItemType: String {
            case product
            case coupon
            case loading
            case error

            init(cartItem: Cart.PurchasableItem) {
                switch cartItem.state {
                case .loaded:
                    self = .product
                case .loading:
                    self = .loading
                case .error:
                    self = .error
                }
            }
        }

        /// Types of products supported in the POS
        ///
        enum CartItemProductType: String {
            case simple
            case variation

            init?(cartItem: Cart.PurchasableItem) {
                guard case let .loaded(item) = cartItem.state else {
                    return nil
                }

                if item is POSSimpleProduct {
                    self = .simple
                } else if item is POSVariation {
                    self = .variation
                } else {
                    return nil
                }
            }
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }

        static func addItemToCart(
            sourceView: WooAnalyticsEvent.PointOfSale.SourceView? = nil,
            sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType,
            itemType: WooAnalyticsEvent.PointOfSale.ItemType,
            productType: WooAnalyticsEvent.PointOfSale.CartItemProductType? = nil,
            resultPosition: Int? = nil,
            error: Error? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: String] = [
                Key.sourceViewType: sourceViewType.rawValue,
                Key.itemType: itemType.rawValue
            ]

            if let sourceView {
                properties[Key.sourceView] = sourceView.rawValue
            }

            if let productType {
                properties[Key.productType] = productType.rawValue
            }

            if let resultPosition {
                properties[Key.resultPosition] = "\(resultPosition)"
            }

            return WooAnalyticsEvent(
                statName: .pointOfSaleAddItemToCart,
                properties: properties,
                error: error
            )
        }

        static func itemRemovedFromCart(
            sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
            itemType: WooAnalyticsEvent.PointOfSale.ItemType,
            productType: WooAnalyticsEvent.PointOfSale.CartItemProductType? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: String] = [
                Key.sourceView: sourceView.rawValue,
                Key.itemType: itemType.rawValue
            ]

            if let productType = productType {
                properties[Key.productType] = productType.rawValue
            }

            return WooAnalyticsEvent(
                statName: .pointOfSaleItemRemovedFromCart,
                properties: properties
            )
        }

        static func checkoutTapped(purchasableItemsInCart: Int, couponsInCart: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleCheckoutTapped,
                properties: [
                    Key.productsInCart: purchasableItemsInCart,
                    Key.couponsInCart: couponsInCart
                ]
            )
        }

        /// Tracks the time elapsed preparing reader for payment, after successful order creation
        /// - Parameter waitingTime: Elapsed time from Order creation to card ready for payment
        ///
        public static func cardReaderReadyForCardPayment(waitingTime: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleReaderReadyForCardPayment, properties: [Key.waitingTime: "\(waitingTime)"])
        }

        public static func cardPresentCollectPaymentSuccess(forGatewayID: String?,
                                                     countryCode: CountryCode,
                                                     paymentMethod: PaymentMethod,
                                                     cardReaderModel: String?,
                                                     millisecondsSinceCustomerIteractionStarted: Double,
                                                     millisecondsSinceOrderSyncSuccess: Double,
                                                     millisecondsSinceReaderReadyToCollect: Double,
                                                     millisecondsSinceCardTapped: Double,
                                                     checkoutTapCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
                Key.cardReaderModel: readerModel(for: cardReaderModel),
                Key.countryCode: countryCode.rawValue,
                Key.gatewayID: safeGatewayID(for: forGatewayID),
                Key.paymentMethodType: analyticsValue(for: paymentMethod),
                Key.millisecondsSinceCustomerInteractionStarted: "\(millisecondsSinceCustomerIteractionStarted)",
                Key.millisecondsSinceOrderSyncSuccess: "\(millisecondsSinceOrderSyncSuccess)",
                Key.millisecondsSinceReaderReadyToCollect: "\(millisecondsSinceReaderReadyToCollect)",
                Key.millisecondsSinceCardTapped: "\(millisecondsSinceCardTapped)",
                Key.checkoutTapCount: "\(checkoutTapCount)"
            ])
        }

        static func analyticsValue(for paymentMethod: PaymentMethod) -> String {
            switch paymentMethod {
            case .card, .cardPresent:
                return "card"
            case .interacPresent:
                return "card_interac"
            case .unknown:
                return "unknown"
            }
        }

        public static func cashCollectPaymentSuccess(millisecondsSinceCustomerIteractionStarted: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleCashCollectPaymentSuccess, properties: [
                Key.millisecondsSinceCustomerInteractionStarted: "\(millisecondsSinceCustomerIteractionStarted)",
            ])
        }

        static func searchButtonTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleSearchButtonTapped,
                properties: [Key.sourceView: SourceView(itemListType: itemListType).rawValue]
            )
        }

        static func itemsHeaderTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleItemsHeaderTapped,
                properties: [Key.type: SourceView(itemListType: itemListType).rawValue]
            )
        }

        static func preSearchRecentTermTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSalePreSearchRecentTermTapped,
                properties: [Key.sourceView: SourceView(itemListType: itemListType).rawValue]
            )
        }

        static func itemsPullToRefresh(
            sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
            sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleItemsPullToRefresh,
                properties: [Key.sourceView: sourceView.rawValue, Key.sourceViewType: sourceViewType.rawValue]
            )
        }

        static func itemsNextPageLoaded(
            sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
            sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleItemsNextPageLoaded,
                properties: [Key.sourceView: sourceView.rawValue, Key.sourceViewType: sourceViewType.rawValue]
            )
        }

        static func pointOfSaleSearchRemoteResultsFetched(itemType: POSItemType,
                                                          resultsCount: Int,
                                                          millisecondsSinceRequestSent: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSearchRemoteResultsFetched,
                              properties: [
                                Key.sourceView: SourceView(itemType: itemType).rawValue,
                                Key.resultsCount: "\(resultsCount)",
                                Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)"
                              ])
        }

        static func pointOfSaleSearchResultsFetched(source: String,
                                                    resultsCount: Int,
                                                    millisecondsSinceRequestSent: Int,
                                                    searchMethod: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSearchResultsFetched,
                              properties: [
                                Key.sourceView: source,
                                Key.resultsCount: "\(resultsCount)",
                                Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)",
                                Key.searchMethod: searchMethod
                              ])
        }

        static func pointOfSaleItemsFetched(itemType: POSItemType,
                                            totalItems: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleItemsFetched,
                              properties: [
                                Key.sourceView: SourceView(itemType: itemType).rawValue,
                                Key.totalItems: "\(totalItems)"
                              ])
        }

        static func barcodeScanningSuccess(scanDurationMs: Int, barcodeLength: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScanningSuccess,
                              properties: [
                                Key.scanDurationMs: "\(scanDurationMs)",
                                Key.barcodeLength: "\(barcodeLength)"
                              ])
        }

        static func barcodeScanningFailed(scanDurationMs: Int, barcodeLength: Int, failReason: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScanningFailed,
                              properties: [
                                Key.scanDurationMs: "\(scanDurationMs)",
                                Key.barcodeLength: "\(barcodeLength)",
                                Key.failReason: failReason
                              ])
        }

        static func barcodeScannerSetupScannerSelected(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupScannerSelected,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        static func barcodeScannerSetupNextTapped(scanner: PointOfSaleBarcodeScannerType, step: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupNextTapped,
                              properties: [
                                Key.scanner: scanner.analyticsName,
                                Key.step: step
                              ])
        }

        static func barcodeScannerSetupBackTapped(scanner: PointOfSaleBarcodeScannerType, step: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupBackTapped,
                              properties: [
                                Key.scanner: scanner.analyticsName,
                                Key.step: step
                              ])
        }

        static func barcodeScannerSetupOpenSystemSettingsTapped(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupOpenSystemSettingsTapped,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        static func barcodeScannerSetupTestScanSuccess(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupTestScanSuccess,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        static func barcodeScannerSetupTestScanFailed(scanner: PointOfSaleBarcodeScannerType, scanValue: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupTestScanFailed,
                              properties: [
                                Key.scanner: scanner.analyticsName,
                                Key.scanValue: scanValue
                              ])
        }

        static func barcodeScannerSetupTestScanTimedOut(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupTestScanTimedOut,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        static func barcodeScannerSetupDismissed(scanner: PointOfSaleBarcodeScannerType? = nil, step: String? = nil) -> WooAnalyticsEvent {
            var properties: [String: String] = [:]
            if let scanner {
                properties[Key.scanner] = scanner.analyticsName
            }
            if let step {
                properties[Key.step] = step
            }
            return WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupDismissed,
                                     properties: properties)
        }

        static func barcodeScannerSetupRetryTapped(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupRetryTapped,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        static func barcodeScannerSetupScannerConnected(scanner: PointOfSaleBarcodeScannerType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBarcodeScannerSetupScannerConnected,
                              properties: [Key.scanner: scanner.analyticsName])
        }

        // MARK: - Orders Analytics Events

        static func ordersMenuItemTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersMenuItemTapped, properties: [:])
        }

        static func ordersListPullToRefresh() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListPullToRefresh, properties: [:])
        }

        static func ordersListFetched(millisecondsSinceRequestSent: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListFetched,
                              properties: [Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)"])
        }

        static func ordersListNextPageLoaded(pageNumber: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListNextPageLoaded,
                              properties: [Key.pageNumber: "\(pageNumber)"])
        }

        static func ordersListRowTapped(orderID: Int64,
                                        orderStatus: String,
                                        listPosition: Int,
                                        orderCreatedDate: Date,
                                        siteTimezone: TimeZone) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListRowTapped,
                              properties: [
                                Key.orderID: "\(orderID)",
                                Key.orderStatus: orderStatus,
                                Key.listPosition: "\(listPosition)",
                                Key.daysSinceCreated: "\(daysSinceCreated(from: orderCreatedDate, using: siteTimezone))"
                              ])
        }

        static func ordersListSearchButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListSearchButtonTapped, properties: [:])
        }

        static func ordersListSearchResultsFetched(millisecondsSinceRequestSent: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrdersListSearchResultsFetched,
                              properties: [Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)"])
        }

        static func orderDetailsLoaded(orderID: Int64,
                                       orderStatus: String,
                                       orderCreatedDate: Date,
                                       siteTimezone: TimeZone) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrderDetailsLoaded,
                              properties: [
                                Key.orderID: "\(orderID)",
                                Key.orderStatus: orderStatus,
                                Key.daysSinceCreated: "\(daysSinceCreated(from: orderCreatedDate, using: siteTimezone))"
                              ])
        }

        static func orderDetailsEmailReceiptTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOrderDetailsEmailReceiptTapped, properties: [:])
        }

        static func ordersListLoaded() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .ordersListLoaded, properties: [:])
        }

        // MARK: - Checkout Outdated Item Detection Events

        static func checkoutOutdatedItemDetectedScreenShown(
            reason: String,
            syncStrategy: String
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleCheckoutOutdatedItemDetectedScreenShown,
                properties: [
                    Key.reason: reason,
                    Key.syncStrategy: syncStrategy
                ]
            )
        }

        static func checkoutOutdatedItemDetectedEditOrderTapped(
            reason: String,
            syncStrategy: String
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleCheckoutOutdatedItemDetectedEditOrderTapped,
                properties: [
                    Key.reason: reason,
                    Key.syncStrategy: syncStrategy
                ]
            )
        }

        static func checkoutOutdatedItemDetectedRemoveTapped(
            reason: String,
            syncStrategy: String
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleCheckoutOutdatedItemDetectedRemoveTapped,
                properties: [
                    Key.reason: reason,
                    Key.syncStrategy: syncStrategy
                ]
            )
        }
        // MARK: - Bookings

        static func bookingsMenuItemTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingsMenuItemTapped, properties: [:])
        }

        static func bookingsListSearchButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingsListSearchButtonTapped, properties: [:])
        }

        static func bookingsListBookingTapped(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingsListBookingTapped,
                              properties: [Key.bookingID: "\(bookingID)"])
        }


        static func bookingCancelled(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingCancelled,
                              properties: [Key.bookingID: "\(bookingID)"])
        }

        static func bookingAddNoteTapped(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingAddNoteTapped,
                              properties: [Key.bookingID: "\(bookingID)"])
        }

        static func bookingIssueRefundTapped(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingIssueRefundTapped,
                              properties: [Key.bookingID: "\(bookingID)"])
        }

        static func bookingViewOrderTapped(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingViewOrderTapped,
                              properties: [Key.bookingID: "\(bookingID)"])
        }

        static func bookingAttendanceChanged(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingAttendanceChanged,
                              properties: [Key.bookingID: "\(bookingID)"])
        }

        static func bookingNoteAdded(bookingID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleBookingNoteAdded,
                              properties: [Key.bookingID: "\(bookingID)"])
        }
    }
}

private extension WooAnalyticsEvent.PointOfSale {
    static func readerModel(for connectedReaderModel: String?) -> String {
        connectedReaderModel ?? "none_connected"
    }

    static func safeGatewayID(for gatewayID: String?) -> String {
        gatewayID ?? "unknown"
    }

    static func daysSinceCreated(from date: Date, using siteTimezone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        return calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}
