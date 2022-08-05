extension WooAnalyticsEvent {
    enum LoginOnboarding {
        /// Event property keys.
        private enum Keys {
            static let isFinalFeaturePage = "is_final_page"
            static let surveyOption = "option"
        }

        /// Tracked when login onboarding is shown in the app.
        static func loginOnboardingShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingShown, properties: [:])
        }

        /// Tracked when the user taps on the “Next” button on the login onboarding screen to see the next app feature or continue to the prologue screen.
        /// - Parameter isFinalPage: whether the user taps the “Next” button on the final page of the feature.
        static func loginOnboardingNextButtonTapped(isFinalPage: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingNextButtonTapped, properties: [Keys.isFinalFeaturePage: isFinalPage])
        }

        /// Tracked when the user taps on the “Skip” button on the login onboarding screen to enter the prologue screen.
        static func loginOnboardingSkipButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingSkipButtonTapped, properties: [:])
        }

        /// Tracked when the login onboarding survey is shown.
        static func loginOnboardingSurveyShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingSurveyShown, properties: [:])
        }

        /// Tracked when the user taps “Next” on the login onboarding survey with a selected option.
        /// - Parameter option: the selected survey option.
        static func loginOnboardingSurveySubmitted(option: LoginOnboardingSurveyOption) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginOnboardingSurveySubmitted, properties: [Keys.surveyOption: option.analyticsValue])
        }
    }
}

private extension LoginOnboardingSurveyOption {
    var analyticsValue: String {
        switch self {
        case .exploring:
            return "exploring"
        case .settingUpStore:
            return "setting_up_store"
        case .analytics:
            return "analytics"
        case .products:
            return "products"
        case .orders:
            return "orders"
        case .multipleStores:
            return "multiple_stores"
        }
    }
}
