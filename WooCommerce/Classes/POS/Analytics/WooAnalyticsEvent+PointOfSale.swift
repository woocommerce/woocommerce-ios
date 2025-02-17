import enum Yosemite.CardPresentPaymentOnboardingState

extension WooAnalyticsEvent {
    enum PointOfSale {
        enum CartItemType {
            case simpleProduct
            case variation
        }

        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
            static let itemType = "product_type"
            static let itemsInCart = "items_in_cart"
            static let millisecondsSinceCustomerInteractionStarted = "milliseconds_since_customer_interaction_started"
            static let millisecondsSinceOrderCreationSuccess = "milliseconds_since_order_creation_success"
            static let millisecondsSinceReaderReadyToCollect = "milliseconds_since_reader_ready_to_collect_payment"
            static let millisecondsSinceCardTapped = "milliseconds_since_card_tapped"
            static let checkoutTapCount = "checkout_tap_count"
            static let waitingTime = "waiting_time"
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }

        static func addItemToCart(type: CartItemType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleAddItemToCart, properties: [Key.itemType: type.analyticsValue])
        }

        static func checkoutTapped(_ itemsInCart: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleCheckoutTapped,
                              properties: [Key.itemsInCart: itemsInCart])
        }
        
        /// Tracks the time elapsed preparing reader for payment, after successful order creation
        /// - Parameter waitingTime: Elapsed time from Order creation to card ready for payment
        ///
        static func cardReaderReadyForCardPayment(waitingTime: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleReaderReadyForCardPayment, properties: [Key.waitingTime: "\(waitingTime)"])
        }

        static func cardPresentCollectPaymentSuccess(millisecondsSinceCustomerIteractionStarted: Double,
                                                     millisecondsSinceOrderCreationSuccess: Double,
                                                     millisecondsSinceReaderReadyToCollect: Double,
                                                     millisecondsSinceCardTapped: Double,
                                                     checkoutTapCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
                Key.millisecondsSinceCustomerInteractionStarted: "\(millisecondsSinceCustomerIteractionStarted)",
                Key.millisecondsSinceOrderCreationSuccess: "\(millisecondsSinceOrderCreationSuccess)",
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
