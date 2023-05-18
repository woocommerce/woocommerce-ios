import Foundation
import protocol Yosemite.StoresManager

/// Content for a local notification to be converted to `UNNotificationContent`.
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
        case storeCreationComplete
        case oneDayAfterStoreCreationNameWithoutFreeTrial(storeName: String)
        case oneDayBeforeFreeTrialExpires(siteID: Int64, expiryDate: Date)
        case oneDayAfterFreeTrialExpires(siteID: Int64)
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
                return IdentifierPrefix.oneDayAfterStoreCreationNameWithoutFreeTrial
            case let .oneDayBeforeFreeTrialExpires(siteID, _):
                return IdentifierPrefix.oneDayBeforeFreeTrialExpires + "\(siteID)"
            case .oneDayAfterFreeTrialExpires(let siteID):
                return IdentifierPrefix.oneDayAfterFreeTrialExpires + "\(siteID)"
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

        enum IdentifierPrefix {
            static let oneDayAfterStoreCreationNameWithoutFreeTrial = "one_day_after_store_creation_name_without_free_trial"
            static let oneDayBeforeFreeTrialExpires = "one_day_before_free_trial_expires"
            static let oneDayAfterFreeTrialExpires = "one_day_after_free_trial_expires"
        }

        /// Helper method to remove postfix from notification identifiers if needed.
        static func identifierForAnalytics(_ identifier: String) -> String {
            if identifier.hasPrefix(IdentifierPrefix.oneDayBeforeFreeTrialExpires) {
                return IdentifierPrefix.oneDayBeforeFreeTrialExpires
            } else if identifier.hasPrefix(IdentifierPrefix.oneDayAfterFreeTrialExpires) {
                return IdentifierPrefix.oneDayAfterFreeTrialExpires
            }
            return identifier
        }
    }

    /// The category of actions for a local notification.
    enum Category: String {
        case storeCreation
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
    }
}

extension LocalNotification {
    init?(scenario: Scenario,
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
        case .storeCreationComplete:
            title = Localization.StoreCreationComplete.title
            body = String.localizedStringWithFormat(Localization.StoreCreationComplete.body, name)

        case .oneDayAfterStoreCreationNameWithoutFreeTrial(let storeName):
            title = Localization.OneDayAfterStoreCreationNameWithoutFreeTrial.title
            body = String.localizedStringWithFormat(
                Localization.OneDayAfterStoreCreationNameWithoutFreeTrial.body,
                name,
                storeName
            )

        case let .oneDayBeforeFreeTrialExpires(_, expiryDate):
            title = Localization.OneDayBeforeFreeTrialExpires.title
            let dateFormatStyle = Date.FormatStyle(locale: locale, timeZone: timeZone)
                .weekday(.wide)
                .month(.wide)
                .day(.defaultDigits)
            let displayDate = expiryDate.formatted(dateFormatStyle)
            body = String.localizedStringWithFormat(Localization.OneDayBeforeFreeTrialExpires.body, displayDate)

        case .oneDayAfterFreeTrialExpires:
            title = Localization.OneDayAfterFreeTrialExpires.title
            body = String.localizedStringWithFormat(Localization.OneDayAfterFreeTrialExpires.body, name)

        default:
            return nil
        }

        self.init(title: title,
                  body: body,
                  scenario: scenario,
                  actions: actions,
                  userInfo: userInfo)
    }
}

extension LocalNotification {
    enum Localization {
        enum StoreCreationComplete {
            static let title = NSLocalizedString(
                "🎉 Your store is ready!",
                comment: "Title of the local notification about a newly created store"
            )
            static let body = NSLocalizedString(
                "Hi %1$@, Welcome to your 14-day free trial of Woo Express – " +
                "everything you need to start and grow a successful online business, " +
                "all in one place. Ready to explore?",
                comment: "Message on the local notification about a newly created store." +
                "The placeholder is the name of the user."
            )
        }

        enum OneDayAfterStoreCreationNameWithoutFreeTrial {
            static let title = NSLocalizedString(
                "🛍️ Your store is waiting!",
                comment: "Title of the local notification suggesting a trial plan subscription."
            )
            static let body = NSLocalizedString(
                "Hi %1$@, %2$@ is ready for you! Start your 14-day free trial " +
                "of Woo Express right in just one click to start your online business.",
                comment: "Message on the local notification suggesting a trial plan subscription." +
                "The placeholders are the name of the user and the store name."
            )
        }

        enum OneDayBeforeFreeTrialExpires {
            static let title = NSLocalizedString(
                "⏰ Time’s running out on your free trial!",
                comment: "Title of the local notification to remind the user of expiring free trial plan."
            )
            static let body = NSLocalizedString(
                "Your free trial of Woo Express ends tomorrow (%1$@). Now’s the time to own your future – pick a plan and get ready to grow.",
                comment: "Message on the local notification to remind the user of the expiring free trial plan." +
                "The placeholder is the expiry date of the trial plan."
            )
        }

        enum OneDayAfterFreeTrialExpires {
            static let title = NSLocalizedString(
                "🌟 Keep your business going with our plan!",
                comment: "Title of the local notification to remind the user of the expired free trial plan."
            )
            static let body = NSLocalizedString(
                "%1$@, we have paused your store, but you can continue by picking a plan that suits you best.",
                comment: "Message on the local notification to remind the user of the expired free trial plan." +
                "The placeholder is the name of the user."
            )
        }
    }
}
