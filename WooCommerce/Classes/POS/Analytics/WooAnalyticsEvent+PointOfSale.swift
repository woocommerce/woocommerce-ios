import enum Yosemite.CardPresentPaymentOnboardingState

extension WooAnalyticsEvent {
    enum PointOfSale {
        /// Event property Key.
        private enum Key {
            static let paymentsOnboardingState = "onboarding_state"
        }

        static func paymentsOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingShown, properties: [:])
        }

        static func paymentsOnboardingDismissed(onboardingState: CardPresentPaymentOnboardingState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSalePaymentsOnboardingDismissed,
                              properties: [Key.paymentsOnboardingState: onboardingState.reasonForAnalytics])
        }
    }
}
