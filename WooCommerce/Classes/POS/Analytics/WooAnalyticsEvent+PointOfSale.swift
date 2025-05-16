import enum Yosemite.CardPresentPaymentOnboardingState
import enum Yosemite.POSItemType

extension WooAnalyticsEvent {
    enum PointOfSale {
        enum CartItemType {
            case simpleProduct
            case variation
        }

        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
            static let itemListType = "item_list_type"
            static let itemType = "product_type"
            static let itemsInCart = "items_in_cart"
            static let couponsInCart = "coupons_in_cart"
            static let millisecondsSinceCustomerInteractionStarted = "milliseconds_since_customer_interaction_started"
            static let millisecondsSinceOrderSyncSuccess = "milliseconds_since_order_sync_success"
            static let millisecondsSinceReaderReadyToCollect = "milliseconds_since_reader_ready_to_collect_payment"
            static let millisecondsSinceCardTapped = "milliseconds_since_card_tapped"
            static let checkoutTapCount = "checkout_tap_count"
            static let waitingTime = "waiting_time"
            static let source = "source"
            static let sourceType = "source_type"
            static let resultsCount = "results_count"
            static let millisecondsSinceRequestSent = "milliseconds_since_request_sent"
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }

        static func addItemToCart(type: CartItemType, itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleAddItemToCart, properties: [:])
        }

        static func checkoutTapped(purchasableItemsInCart: Int, couponsInCart: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleCheckoutTapped,
                              properties: [Key.itemsInCart: purchasableItemsInCart,
                                           Key.couponsInCart: couponsInCart])
        }

        /// Tracks the time elapsed preparing reader for payment, after successful order creation
        /// - Parameter waitingTime: Elapsed time from Order creation to card ready for payment
        ///
        static func cardReaderReadyForCardPayment(waitingTime: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleReaderReadyForCardPayment, properties: [Key.waitingTime: "\(waitingTime)"])
        }

        static func cardPresentCollectPaymentSuccess(millisecondsSinceCustomerIteractionStarted: Double,
                                                     millisecondsSinceOrderSyncSuccess: Double,
                                                     millisecondsSinceReaderReadyToCollect: Double,
                                                     millisecondsSinceCardTapped: Double,
                                                     checkoutTapCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
                Key.millisecondsSinceCustomerInteractionStarted: "\(millisecondsSinceCustomerIteractionStarted)",
                Key.millisecondsSinceOrderSyncSuccess: "\(millisecondsSinceOrderSyncSuccess)",
                Key.millisecondsSinceReaderReadyToCollect: "\(millisecondsSinceReaderReadyToCollect)",
                Key.millisecondsSinceCardTapped: "\(millisecondsSinceCardTapped)",
                Key.checkoutTapCount: "\(checkoutTapCount)"
            ])
        }

        static func cashCollectPaymentSuccess(millisecondsSinceCustomerIteractionStarted: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleCashCollectPaymentSuccess, properties: [
                Key.millisecondsSinceCustomerInteractionStarted: "\(millisecondsSinceCustomerIteractionStarted)",
            ])
        }

        static func searchButtonTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSearchButtonTapped,
                              properties: [:])
        }

        static func preSearchRecentTermTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePreSearchRecentTermTapped,
                              properties: [:])
        }

        static func itemsPullToRefresh(itemType: POSItemType, searching: Bool) -> WooAnalyticsEvent {
            let source = Source(itemType: itemType).rawValue
            let sourceType = SourceType(isSearching: searching).rawValue
            return WooAnalyticsEvent(
                statName: .pointOfSaleItemsPullToRefresh,
                properties: [Key.source: source, Key.sourceType: sourceType]
            )
        }

        static func itemsNextPageLoaded(itemType: POSItemType, searching: Bool) -> WooAnalyticsEvent {
            let source = Source(itemType: itemType).rawValue
            let sourceType = SourceType(isSearching: searching).rawValue
            return WooAnalyticsEvent(
                statName: .pointOfSaleItemsNextPageLoaded,
                properties: [Key.source: source, Key.sourceType: sourceType]
            )
        }

        static func pointOfSaleSearchRemoteResultsFetched(itemType: POSItemType,
                                                          resultsCount: Int,
                                                          millisecondsSinceRequestSent: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSearchRemoteResultsFetched,
                              properties: [
                                Key.resultsCount: "\(resultsCount)",
                                Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)"
                              ])
        }
    }
}

private extension WooAnalyticsEvent.PointOfSale {
    enum Source: String {
        case product
        case variation
        case coupon

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
    }

    enum SourceType: String {
        case list
        case search

        init(isSearching: Bool) {
            self = isSearching ? .search : .list
        }
    }
}
