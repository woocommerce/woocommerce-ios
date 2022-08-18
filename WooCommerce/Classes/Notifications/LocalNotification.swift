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
    enum Scenario: String, CaseIterable {
        case loginSiteAddressError = "site_address_error"
        case invalidEmailFromSiteAddressLogin = "site_address_email_error"
        case invalidEmailFromWPComLogin = "wpcom_email_error"
        case invalidPasswordFromSiteAddressLogin = "site_address_wpcom_password_error"
        case invalidPasswordFromWPComLogin = "wpcom_password_error"
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case loginError
    }

    /// The action type in a local notification.
    enum Action: String {
        case contactSupport
        case loginWithWPCom

        /// The title of the action in a local notification.
        var title: String {
            switch self {
            case .contactSupport:
                return NSLocalizedString("Contact support", comment: "Local notification action to contact support.")
            case .loginWithWPCom:
                return NSLocalizedString("Login with WordPress.com", comment: "Local notification action to log in with WordPress.com.")
            }
        }
    }
}

extension LocalNotification {
    init(scenario: Scenario) {
        switch scenario {
        case .loginSiteAddressError:
            self.init(title: Localization.errorLoggingInTitle,
                      body: Localization.errorLoggingInBody,
                      scenario: scenario,
                      actions: .init(category: .loginError, actions: [.contactSupport, .loginWithWPCom]))
        case .invalidEmailFromWPComLogin, .invalidEmailFromSiteAddressLogin:
            self.init(title: Localization.errorLoggingInTitle,
                      body: Localization.errorLoggingInBody,
                      scenario: scenario,
                      actions: .init(category: .loginError, actions: [.contactSupport]))
        case .invalidPasswordFromWPComLogin, .invalidPasswordFromSiteAddressLogin:
            self.init(title: Localization.errorLoggingInTitle,
                      body: Localization.errorLoggingInBody,
                      scenario: scenario,
                      actions: .init(category: .loginError, actions: [.contactSupport]))
        }
    }
}

private extension LocalNotification {
    enum Localization {
        static let errorLoggingInTitle = NSLocalizedString("Problems with logging in?",
                                                           comment: "Local notification title when the user encounters an error logging in " +
                                                           "with site address.")
        static let errorLoggingInBody = NSLocalizedString("Get some help!",
                                                          comment: "Local notification body when the user encounters an error logging in " +
                                                          "with site address.")
    }
}
