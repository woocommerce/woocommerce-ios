import enum Yosemite.CardPresentPaymentOnboardingState
import enum Yosemite.POSItemType
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

extension WooAnalyticsEvent {
    enum PointOfSale {
        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
            static let itemType = "item_type"
            static let productType = "product_type"
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

        static func addItemToCart(
            source: WooAnalyticsEvent.PointOfSale.Source,
            sourceType: WooAnalyticsEvent.PointOfSale.SourceType,
            itemType: WooAnalyticsEvent.PointOfSale.ItemType,
            productType: WooAnalyticsEvent.PointOfSale.ProductType? = nil,
        ) -> WooAnalyticsEvent {
            var properties: [String: String] = [
                Key.source: source.rawValue,
                Key.sourceType: sourceType.rawValue,
                Key.itemType: itemType.rawValue
            ]

            if let productType = productType {
                properties[Key.productType] = productType.rawValue
            }

            return WooAnalyticsEvent(
                statName: .pointOfSaleAddItemToCart,
                properties: properties
            )
        }

        static func itemRemovedFromCart(
            source: WooAnalyticsEvent.PointOfSale.Source,
            itemType: WooAnalyticsEvent.PointOfSale.ItemType,
            productType: WooAnalyticsEvent.PointOfSale.ProductType? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: String] = [
                Key.source: source.rawValue,
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
            WooAnalyticsEvent(
                statName: .pointOfSaleSearchButtonTapped,
                properties: [Key.source: Source(itemListType: itemListType).rawValue]
            )
        }

        static func preSearchRecentTermTapped(itemListType: ItemListType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePreSearchRecentTermTapped,
                              properties: [:])
        }

        static func itemsPullToRefresh(
            source: WooAnalyticsEvent.PointOfSale.Source,
            sourceType: WooAnalyticsEvent.PointOfSale.SourceType
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleItemsPullToRefresh,
                properties: [Key.source: source.rawValue, Key.sourceType: sourceType.rawValue]
            )
        }

        static func itemsNextPageLoaded(
            source: WooAnalyticsEvent.PointOfSale.Source,
            sourceType: WooAnalyticsEvent.PointOfSale.SourceType
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .pointOfSaleItemsNextPageLoaded,
                properties: [Key.source: source.rawValue, Key.sourceType: sourceType.rawValue]
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

extension WooAnalyticsEvent.PointOfSale {
    enum Source: String {
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

    enum SourceType: String {
        case list
        case search
        case preSearch = "pre_search"

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

    enum ItemType: String {
        case product
        case coupon
    }

    enum ProductType: String {
        case simple
        case variation

        init?(cartItem: Cart.PurchasableItem) {
            if cartItem.item is POSSimpleProduct {
                self = .simple
            } else if cartItem.item is POSVariation {
                self = .variation
            } else {
                return nil
            }
        }
    }
}
