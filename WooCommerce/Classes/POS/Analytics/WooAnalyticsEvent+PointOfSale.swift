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
            static let search = "search"
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
            WooAnalyticsEvent(statName: .pointOfSaleAddItemToCart, properties: [
                Key.itemType: type.analyticsValue,
                Key.source: itemListType.addItemSourceAnalyticsValue
            ])
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
                              properties: [
                                Key.itemListType: itemListType.analyticsValue
                              ])
        }

        static func preSearchRecentTermTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePreSearchRecentTermTapped,
                              properties: [
                                Key.itemListType: itemListType.analyticsValue
                              ])
        }

        static func pointOfSaleItemsNextPageLoaded(itemType: POSItemType, searching: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleItemsNextPageLoaded,
                              properties: [
                                Key.itemListType: itemType.analyticsValue,
                                Key.search: searching
            ])
        }

        static func pointOfSaleSearchRemoteResultsFetched(itemType: POSItemType,
                                                          resultsCount: Int,
                                                          millisecondsSinceRequestSent: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSearchRemoteResultsFetched,
                              properties: [
                                Key.itemListType: itemType.analyticsValue,
                                Key.resultsCount: "\(resultsCount)",
                                Key.millisecondsSinceRequestSent: "\(millisecondsSinceRequestSent)"
                              ])
        }
    }
}

private extension WooAnalyticsEvent.PointOfSale.CartItemType {
    var analyticsValue: String {
        switch self {
        case .simpleProduct:
            return "simple"
        case .variation:
            return "variation"
        }
    }
}

private extension ItemListType {
    var analyticsValue: String {
        switch self {
        case .products:
            return "products"
        case .coupons:
            return "coupons"
        }
    }

    var addItemSourceAnalyticsValue: String {
        switch self {
        case .products(search: true):
            return "search_result"
        case .products(search: false),
                .coupons:
            return "list"
        }
    }
}

private extension POSItemType {
    var analyticsValue: String {
        switch self {
        case .product:
            return "product"
        case .variation:
            return "variation"
        case .coupon:
            return "coupon"
        }
    }
}
