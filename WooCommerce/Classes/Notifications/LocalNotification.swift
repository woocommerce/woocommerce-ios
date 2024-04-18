import Foundation
import protocol Yosemite.StoresManager

/// Content for a local notification to be converted to `UNNotificationContent`.
/// This is now currently unused, but preserved for future needs.
struct LocalNotification {
    let title: String
    let body: String
    let scenario: Scenario
    let actions: CategoryActions?
    let userInfo: [AnyHashable: Any]

    /// A category of actions in a notification.
    struct CategoryActions {
        let category: Category
        let actions: [Action]
    }

    /// The scenario for the local notification.
    /// Its raw value is used for the identifier of a local notification and also the event property for analytics.
    enum Scenario {
        case unknown(siteID: Int64)

        var identifier: String {
            switch self {
            case let .unknown(siteID):
                return "unknown_" + "\(siteID)"
            }
        }

        /// Helper method to remove postfix from notification identifiers if needed.
        static func identifierForAnalytics(_ identifier: String) -> String {
            return identifier
        }
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case unknown
    }

    /// The action type in a local notification.
    enum Action: String {
        // TODO: add any custom action if needed
        case none

        /// The title of the action in a local notification.
        var title: String {
            return ""
        }
    }

    /// Holds `userInfo` dictionary keys
    enum UserInfoKey {
        static let storeName = "storeName"
        static let isIAPAvailable = WooAnalyticsEvent.LocalNotification.Key.isIAPAvailable
    }
}

extension LocalNotification {
    init(scenario: Scenario,
          stores: StoresManager = ServiceLocator.stores,
          timeZone: TimeZone = .current,
          locale: Locale = .current,
          userInfo: [AnyHashable: Any] = [:]) {
        /// Name to display in notifications
        let name: String = {
            let sessionManager = stores.sessionManager
            guard let name = sessionManager.defaultAccount?.displayName, name.isNotEmpty else {
                return sessionManager.defaultCredentials?.username ?? ""
            }
            return name
        }()

        let title: String
        let body: String
        let actions: CategoryActions? = nil

        switch scenario {
        case .unknown:
            title = ""
            body = ""
        }

        self.init(title: title,
                  body: body,
                  scenario: scenario,
                  actions: actions,
                  userInfo: userInfo)
    }
}
