extension WooAnalyticsEvent {
    enum LoginOnboarding {
        /// Event property keys.
        private enum Keys {
            static let isFinalFeaturePage = "is_final_page"
        }

        /// Tracked when the store stats are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        static func loginOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingShown, properties: [:])
        }

        /// Tracked when the date range on the store stats view changes.
        /// - Parameter isFinalPage: <#isFinalPage description#>
        static func loginOnboardingNextButtonTapped(isFinalPage: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingNextButtonTapped, properties: [Keys.isFinalFeaturePage: isFinalPage])
        }

        /// Tracked when the top performers are loaded with fresh data either via first load, event driven refresh, or manual refresh.
        static func loginOnboardingSkipButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingSkipButtonTapped, properties: [:])
        }
    }
}
