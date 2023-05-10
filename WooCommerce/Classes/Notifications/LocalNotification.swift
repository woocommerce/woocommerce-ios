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
        case openPlansPage
        case none

        /// The title of the action in a local notification.
        var title: String {
            switch self {
            case .openPlansPage:
                return Localization.openPlansPage
            case .none:
                return ""
            }
        }
    }
}

extension LocalNotification {
    init?(scenario: Scenario) {
        /// Name to display in notifications
        let name: String = {
            let sessionManager = ServiceLocator.stores.sessionManager
            guard let name = sessionManager.defaultAccount?.displayName, name.isNotEmpty else {
                return sessionManager.defaultCredentials?.username ?? ""
            }
            return name
        }()

        switch scenario {
        case .oneDayBeforeFreeTrialExpires(let expiryDate):
            let title = String.localizedStringWithFormat(Localization.oneDayBeforeFreeTrialExpiresTitle, name)
            let dateFormatStyle = Date.FormatStyle()
                .weekday(.wide)
                .month(.wide)
                .day(.defaultDigits)
            let displayDate = expiryDate.formatted(dateFormatStyle)
            let message = String.localizedStringWithFormat(Localization.oneDayBeforeFreeTrialExpiresMessage, displayDate)
            self.init(title: title,
                      body: message,
                      scenario: scenario,
                      actions: .init(category: .storeCreation, actions: [.openPlansPage]))
        default:
            return nil
        }
    }
}

private extension LocalNotification {
    enum Localization {
        static let oneDayBeforeFreeTrialExpiresTitle = NSLocalizedString(
            "Time’s almost up, %1$@",
            comment: "Title of the local notification to remind the user of expiring free trial plan." +
            "The placeholder is the name of the user."
        )
        static let oneDayBeforeFreeTrialExpiresMessage = NSLocalizedString(
            "Your free trial of Woo Express ends tomorrow (%1$@). Now’s the time to own your future – pick a plan and get ready to grow.",
            comment: "Message on the local notification to remind the user of the expiring free trial plan." +
            "The placeholder is the expiry date of the trial plan."
        )
        static let openPlansPage = NSLocalizedString(
            "Upgrade",
            comment: "Action on the local notification to remind the user of the expiring free trial plan."
        )
    }
}
