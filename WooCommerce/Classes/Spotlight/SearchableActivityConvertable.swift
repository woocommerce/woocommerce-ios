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
            return NSLocalizedString("My Store in Woo", comment: "Siri Suggestion to open Dasboard")
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

        if let activityDescription = activityDescription {
            let contentAttributeSet = CSSearchableItemAttributeSet(contentType: UTType.text)
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
