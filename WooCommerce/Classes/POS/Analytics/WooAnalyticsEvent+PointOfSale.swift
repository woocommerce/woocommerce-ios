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
            static let elapsedTime = "milliseconds_time_elapsed_in_splash_screen"
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

        static func pointOfSaleInitialLoadingTime(_ elapsedTime: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLoaded,
                              properties: [Key.elapsedTime: elapsedTime])
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
