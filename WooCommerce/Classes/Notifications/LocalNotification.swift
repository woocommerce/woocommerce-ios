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
    enum Scenario: String {
        case loginSiteAddressError = "site_address_error"
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case loginError
    }

    /// The action type in a local notification.
    enum Action: String {
        case contactSupport

        /// The title of the action in a local notification.
        var title: String {
            switch self {
            case .contactSupport:
                return NSLocalizedString("Contact support", comment: "Local notification action to contact support.")
            }
        }
    }
}
