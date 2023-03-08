import CoreSpotlight
import UIKit
import MobileCoreServices

/// Custom NSUSerActivity types for the Woo app. Primarily used for navigation points.
///
enum WooActivityType: String {
    case dashboard               = "com.automattic.woocommerce.dashboard"
    case orders                  = "com.automattic.woocommerce.orders"
    case products                = "com.automattic.woocommerce.products"
    case hubMenu                 = "com.automattic.woocommerce.hubMenu"
    case payments                = "com.automattic.woocommerce.payments"
}

extension WooActivityType {
    var suggestedInvocationPhrase: String {
        switch self {
        case .dashboard:
            return NSLocalizedString("Dashboard in Woo", comment: "Siri Suggestion to open Dasboard")
        case .orders:
            return NSLocalizedString("Orders in Woo", comment: "Siri Suggestion to open Orders")
        case .products:
            return NSLocalizedString("Products in Woo", comment: "Siri Suggestion to open Products")
        case .hubMenu:
            return NSLocalizedString("Menu in Woo", comment: "Siri Suggestion to open the Menu")
        case .payments:
            return NSLocalizedString("Payments in Woo", comment: "Siri Suggestion to open the Menu")

        }
    }
}

/// NSUserActivity userInfo keys
///
enum WooActivityUserInfoKeys: String {
    case siteId = "siteid"
}

@objc protocol SearchableActivityConvertable {
    /// Type name used to uniquly indentify this activity.
    ///
    @objc var activityType: String {get}

    /// Activity title to be displayed in spotlight search.
    ///
    @objc var activityTitle: String {get}

    // MARK: Optional Vars
    /// A set of localized keywords that can help users find the activity in search results.
    ///
    @objc optional var activityKeywords: Set<String>? {get}

    /// The date after which the activity is no longer eligible for indexing. If not set,
    /// the expiration date will default to one week from the current date.
    ///
    @objc optional var activityExpirationDate: Date? {get}

    /// A dictionary containing state information related to this indexed activity.
    ///
    @objc optional var activityUserInfo: [String: String]? {get}

    /// Activity description
    ///
    @objc optional var activityDescription: String? {get}
}

extension SearchableActivityConvertable where Self: UIViewController {
    internal func registerUserActivity() {
        let activity = NSUserActivity(activityType: activityType)
        activity.title = activityTitle

        if let keywords = activityKeywords as? Set<String>, !keywords.isEmpty {
            activity.keywords = keywords
        }

        if let expirationDate = activityExpirationDate {
            activity.expirationDate = expirationDate
        } else {
            let oneWeekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
            activity.expirationDate = oneWeekFromNow
        }

        if let activityUserInfo = activityUserInfo {
            activity.userInfo = activityUserInfo
            activity.requiredUserInfoKeys = Set([WooActivityUserInfoKeys.siteId.rawValue])
        }

        if let activityDescription = activityDescription {
            let contentAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            contentAttributeSet.contentDescription = activityDescription
            contentAttributeSet.contentCreationDate = nil // Set this to nil so it doesn't display in spotlight
            activity.contentAttributeSet = contentAttributeSet
        }

        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        activity.isEligibleForHandoff = false

        activity.isEligibleForPrediction = true

        if let wooActivityType = WooActivityType(rawValue: activityType) {
            activity.suggestedInvocationPhrase = wooActivityType.suggestedInvocationPhrase
        }

        // Set the UIViewController's userActivity property, which is defined in UIResponder. Doing this allows
        // UIKit to automagically manage this user activity (e.g. making it current when needed)
        userActivity = activity
    }
}
