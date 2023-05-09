import Foundation

/// Content for a local notification to be converted to `UNNotificationContent`.
struct LocalNotification {
    let title: String
    let body: String
    let scenario: Scenario
    let actions: CategoryActions?

    /// A category of actions in a notification.
    struct CategoryActions {
        let category: Category
        let actions: [Action]
    }

    /// The scenario for the local notification.
    /// Its raw value is used for the identifier of a local notification and also the event property for analytics.
    enum Scenario {
        case storeCreationComplete
        case oneDayAfterStoreCreationNameWithoutFreeTrial
        case oneDayBeforeFreeTrialExpires(expiryDate: Date)
        case oneDayAfterFreeTrialExpires
        // The following notifications are deprecated and are canceled in the first release.
        case loginSiteAddressError
        case invalidEmailFromSiteAddressLogin
        case invalidEmailFromWPComLogin
        case invalidPasswordFromSiteAddressWPComLogin
        case invalidPasswordFromWPComLogin

        var identifier: String {
            switch self {
            case .storeCreationComplete:
                return "store_creation_complete"
            case .oneDayAfterStoreCreationNameWithoutFreeTrial:
                return "one_day_after_store_creation_name_without_free_trial"
            case .oneDayBeforeFreeTrialExpires:
                return "one_day_before_free_trial_expires"
            case .oneDayAfterFreeTrialExpires:
                return "one_day_after_free_trial_expires"
            case .loginSiteAddressError:
                return "site_address_error"
            case .invalidEmailFromSiteAddressLogin:
                return "site_address_email_error"
            case .invalidEmailFromWPComLogin:
                return "wpcom_email_error"
            case .invalidPasswordFromSiteAddressWPComLogin:
                return "site_address_wpcom_password_error"
            case .invalidPasswordFromWPComLogin:
                return "wpcom_password_error"
            }
        }
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case storeCreation
    }

    /// The action type in a local notification.
    enum Action: String {
        // TODO: 9665 - determine if there are any custom actions
        case none

        /// The title of the action in a local notification.
        var title: String {
            switch self {
            case .none:
                return ""
            }
        }
    }
}

extension LocalNotification {
    init(scenario: Scenario) {
        // TODO: 9665 - Copy TBD for each notification
        self.init(title: scenario.rawValue,
                  body: "",
                  scenario: scenario,
                  actions: .init(category: .storeCreation, actions: []))
    }
}
