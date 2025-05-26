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
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }

        static func addItemToCart(
            sourceView: WooAnalyticsEvent.PointOfSale.SourceView,
            sourceViewType: WooAnalyticsEvent.PointOfSale.SourceViewType,
            itemType: WooAnalyticsEvent.PointOfSale.ItemType,
            productType: WooAnalyticsEvent.PointOfSale.CartItemProductType? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: String] = [
                Key.sourceView: sourceView.rawValue,
                Key.sourceViewType: sourceViewType.rawValue,
                Key.itemType: itemType.rawValue
            ]

            if let productType {
                properties[Key.productType] = productType.rawValue
            }

            return WooAnalyticsEvent(
                statName: .pointOfSaleAddItemToCart,
                properties: properties
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
    }
}

extension WooAnalyticsEvent.PointOfSale {
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
    }

    /// Types of products supported in the POS
    ///
    enum CartItemProductType: String {
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
