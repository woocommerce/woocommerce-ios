import enum Yosemite.CreateAccountError
import struct Yosemite.StoreProfilerAnswers

extension WooAnalyticsEvent {
    enum StoreCreation {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let url = "url"
            static let errorType = "error_type"
            static let flow = "flow"
            static let step = "step"
            static let category = "industry_slug"
            static let sellingStatus = "user_commerce_journey"
            static let sellingPlatforms = "ecommerce_platforms"
            static let countryCode = "country_code"
            static let isFreeTrial = "is_free_trial"
            static let waitingTime = "waiting_time"
            static let newSiteID = "new_site_id"
            static let initialDomain = "initial_domain"
        }

        static func siteCreationFlowStarted(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationFlowStarted,
                              properties: [Key.source: source.rawValue])
        }

        /// Tracked when a site is created from the store creation flow.
        static func siteCreated(source: Source, siteURL: String, flow: Flow, isFreeTrial: Bool, waitingTime: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreated,
                              properties: [Key.source: source.rawValue,
                                           Key.url: siteURL,
                                           Key.flow: flow.rawValue,
                                           Key.isFreeTrial: isFreeTrial,
                                           Key.waitingTime: waitingTime])
        }

        /// Tracked when site creation request success
        static func siteCreationRequestSuccess(siteID: Int64, domainName: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationFreeTrialCreatedSuccess,
                              properties: [Key.newSiteID: siteID,
                                           Key.initialDomain: domainName])
        }

        /// Tracked when site creation fails.
        static func siteCreationFailed(source: Source, error: Error, flow: Flow, isFreeTrial: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationFailed,
                              properties: [Key.source: source.rawValue, Key.flow: flow.rawValue, Key.isFreeTrial: isFreeTrial],
                              error: error)
        }

        /// Tracked when the user dismisses the store creation flow before the flow is complete.
        static func siteCreationDismissed(source: Source, flow: Flow, isFreeTrial: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationDismissed,
                              properties: [Key.source: source.rawValue, Key.flow: flow.rawValue, Key.isFreeTrial: isFreeTrial])
        }

        /// Tracked when the user reaches each step of the store creation flow.
        static func siteCreationStep(step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationStep,
                              properties: [Key.step: step.rawValue])
        }

        /// Tracked clicking on “Store Preview” button after a site is created successfully.
        static func siteCreationSitePreviewed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationSitePreviewed, properties: [:])
        }

        /// Tracked when tapping on the “Manage my store” button on the store creation success screen.
        static func siteCreationManageStoreTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationManageStoreTapped, properties: [:])
        }

        /// Tracked when the user skips a profiler question in the store creation flow.
        static func siteCreationProfilerQuestionSkipped(step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationProfilerQuestionSkipped,
                              properties: [Key.step: step.rawValue])
        }

        /// Tracked when completing the last profiler question during the store creation flow
        static func siteCreationProfilerData(_ profilerData: StoreProfilerAnswers) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType] = [
                Key.category: profilerData.category,
                Key.sellingStatus: profilerData.sellingStatus?.analyticsValue,
                Key.sellingPlatforms: profilerData.sellingPlatforms,
                Key.countryCode: profilerData.countryCode
            ].compactMapValues({ $0 })
            return WooAnalyticsEvent(statName: .siteCreationProfilerData, properties: properties)
        }

        /// Tracked when the "Try For Free" button in the "Summary View" is  tapped.
        ///
        static func siteCreationTryForFreeTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationTryForFreeTapped, properties: [:])
        }

        /// Tracked when the site creation process takes too much time waiting for the store to be ready.
        ///
        static func siteCreationTimedOut() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationTimedOut, properties: [:])
        }

        /// Tracked when the Retry button on the timeout screen is tapped.
        ///
        static func siteCreationTimeoutRetried() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationTimeoutRetried, properties: [:])
        }

        /// Tracked when the store is jetpack ready, but other store properties are not in sync yet.
        ///
        static func siteCreationPropertiesOutOfSync() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .siteCreationPropertiesOutOfSync, properties: [:])
        }

        /// Tracked when the user taps on the CTA in login prologue (logged out) to create a store.
        static func loginPrologueCreateSiteTapped(isFreeTrial: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginPrologueCreateSiteTapped,
                              properties: [Key.isFreeTrial: isFreeTrial])
        }

        /// Tracked when the user taps on the "Starting a new store?" button in login prologue (logged out).
        static func loginPrologueStartingANewStoreTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginPrologueStartingANewStoreTapped,
                              properties: [:])
        }

        /// Tracked when the user taps on the CTA in the account creation form to log in instead.
        static func signupFormLoginTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .signupFormLoginTapped,
                              properties: [:])
        }

        /// Tracked when the user taps to submit the WPCOM signup form.
        static func signupSubmitted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .signupSubmitted,
                              properties: [:])
        }

        /// Tracked when WPCOM signup succeeds.
        static func signupSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .signupSuccess,
                              properties: [:])
        }

        /// Tracked when WPCOM signup fails.
        static func signupFailed(error: CreateAccountError) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .signupFailed,
                              properties: [Key.errorType: error.analyticsValue])
        }

        /// Tracked when we show an alert that store is ready after checking status in background
        static func storeReadyAlertDisplayed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeReadyAlertDisplayed,
                              properties: [:])
        }

        /// Tracked when user taps button to switch to the new store
        static func storeReadyAlertSwitchStoreTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .storeReadyAlertSwitchStoreTapped,
                              properties: [:])
        }
    }
}

extension WooAnalyticsEvent.StoreCreation {
    enum StorePickerSource: String {
        /// From switching stores.
        case switchStores = "switching_stores"
        /// From the login flow.
        case login
        /// The store creation flow is originally initiated from login prologue and dismissed,
        /// which lands on the store picker.
        case loginPrologue = "prologue"
        /// Other sources like from any error screens during the login flow.
        case other
    }

    enum Source: String {
        case loginPrologue = "prologue"
        case storePicker = "store_picker"
        case loginEmailError = "login_email_error"
    }

    /// The implementation of store creation flow - native (M2) or web (M1).
    enum Flow: String {
        case native = "native"
        case web = "web"
    }

    /// Steps of the native store creation flow.
    enum Step: String {
        case profilerCategoryQuestion = "store_profiler_industries"
        case profilerSellingStatusQuestion = "store_profiler_commerce_journey"
        case profilerSellingPlatformsQuestion = "store_profiler_ecommerce_platforms"
        case profilerCountryQuestion = "store_profiler_country"
        case domainPicker = "domain_picker"
        case storeSummary = "store_summary"
        case planPurchase = "plan_purchase"
        case webCheckout = "web_checkout"
        case storeInstallation = "store_installation"
    }
}

private extension CreateAccountError {
    var analyticsValue: String {
        switch self {
        case .emailExists:
            return "EMAIL_EXIST"
        case .invalidEmail:
            return "EMAIL_INVALID"
        case .invalidPassword:
            return "PASSWORD_INVALID"
        default:
            return "\(self)"
        }
    }
}

private extension StoreProfilerAnswers.SellingStatus {
    var analyticsValue: String {
        remoteValue
    }
}
