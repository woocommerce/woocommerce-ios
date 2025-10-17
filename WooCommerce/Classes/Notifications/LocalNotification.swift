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
        case blazeNoCampaignReminder
        case blazeAbandonedCampaignCreationReminder
        case productImageBackgroundUpload
        case pointOfSalePotentialMerchant
        case pointOfSaleCurrentMerchant
        case unknown(siteID: Int64)

        var identifier: String {
            switch self {
            case .blazeNoCampaignReminder:
                return "blaze_no_campaign_reminder"
            case .blazeAbandonedCampaignCreationReminder:
                return "blaze_abandoned_campaign_reminder"
            case .productImageBackgroundUpload:
                return "product_image_background_upload"
            case .pointOfSalePotentialMerchant:
                return "woo_pos_survey_potential_user_survey"
            case .pointOfSaleCurrentMerchant:
                return "woo_pos_survey_current_user_survey"
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
        // periphery:ignore - will be removed on PR-16128
        static let isIAPAvailable = WooAnalyticsEvent.LocalNotification.Key.isIAPAvailable
        static let surveyURL = "surveyURL"
    }

    enum SurveyURL {
        static let pointOfSalePotentialMerchant = "https://automattic.survey.fm/pos-survey-potential-users"
        static let pointOfSaleCurrentMerchant = "https://automattic.survey.fm/pos-survey-existing-users"
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
        case .blazeNoCampaignReminder:
            title = Localization.BlazeNoCampaignReminder.title
            body = String.localizedStringWithFormat(Localization.BlazeNoCampaignReminder.body, name)
        case .blazeAbandonedCampaignCreationReminder:
            title = Localization.AbandonedCampaignCreation.title
            body = String.localizedStringWithFormat(Localization.AbandonedCampaignCreation.body, name)
        case .productImageBackgroundUpload:
            title = Localization.ProductImageBackgroundUpload.title
            body = Localization.ProductImageBackgroundUpload.body
        case .pointOfSalePotentialMerchant:
            title = Localization.PointOfSalePotentialMerchant.title
            body = Localization.PointOfSalePotentialMerchant.body
        case .pointOfSaleCurrentMerchant:
            title = Localization.PointOfSaleCurrentMerchant.title
            body = Localization.PointOfSaleCurrentMerchant.body
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

extension LocalNotification {
    enum Localization {
        enum BlazeNoCampaignReminder {
            static let title = NSLocalizedString(
                "localNotification.BlazeNoCampaignReminder.title",
                value: "Boost your sales",
                comment: "Title of the local notification to remind scheduling a Blaze campaign."
            )
            static let body = NSLocalizedString(
                "localNotification.BlazeNoCampaignReminder.body",
                value: "Promote your products with Blaze Ads and increase your sales now.",
                comment: "Message on the local notification to remind scheduling a Blaze campaign."
            )
        }
        enum AbandonedCampaignCreation {
            static let title = NSLocalizedString(
                "localNotification.AbandonedCampaignCreation.title",
                value: "Thinking about boosting your sales?",
                comment: "Title of the local notification to remind to continue the Blaze campaign creation."
            )
            static let body = NSLocalizedString(
                "localNotification.AbandonedCampaignCreation.body",
                value: "Get your products seen by millions with Blaze and boost your sales",
                comment: "Message on the local notification to remind to continue the Blaze campaign creation."
            )
        }
        enum ProductImageBackgroundUpload {
            static let title = NSLocalizedString(
                "localNotification.ProductImageUploader.title",
                value: "Image Upload in Progress",
                comment: "Title of the local notification to inform the user that product images are uploading in the background."
            )
            static let body = NSLocalizedString(
                "localNotification.ProductImageUploader.message",
                value: "Your product images are still uploading in the background. Upload speed may be slower, and errors could occur." +
                " For best results, please keep the app open until uploads are complete.",
                comment: "Message on the local notification to inform the user about the background upload of product images."
            )
        }
        enum PointOfSalePotentialMerchant {
            static let title = NSLocalizedString(
                "localNotification.PointOfSalePotentialMerchant.title",
                value: "Thinking about in-person sales?",
                comment: "Title of the local notification sent to potential Point of Sale merchants"
            )
            static let body = NSLocalizedString(
                "localNotification.PointOfSalePotentialMerchant.body",
                value: "Take a quick 2-minute survey to help us shape features you’ll love.",
                comment: "Message body of the local notification sent to potential Point of Sale merchants"
            )
        }
        enum PointOfSaleCurrentMerchant {
            static let title = NSLocalizedString(
                "localNotification.PointOfSaleCurrentMerchant.title",
                value: "How’s POS working for you?",
                comment: "Title of the local notification for current POS merchants survey."
            )
            static let body = NSLocalizedString(
                "localNotification.PointOfSaleCurrentMerchant.body",
                value: "Share your experience in a quick 2-minute survey and help us improve.",
                comment: "Body of the local notification for current POS merchants survey."
            )
        }
    }
}
