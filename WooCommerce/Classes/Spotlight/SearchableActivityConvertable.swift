import CoreSpotlight
import UIKit
import MobileCoreServices

/// Custom NSUSerActivity types for the Woo app. Primarily used for navigation points.
///
enum WooActivityType: String {
    case dashboard               = "com.automattic.woocommerce.dashboard"
    case orders                  = "com.automattic.woocommerce.orders"
    case products                = "com.automattic.woocommerce.products"
    case payments                = "com.automattic.woocommerce.payments"
}

@objc protocol SearchableActivityConvertable {
    /// Type name used to uniquly indentify this activity.
    ///
    @objc var activityType: String { get }

    /// Activity title to be displayed in spotlight search.
    ///
    @objc var activityTitle: String { get }

    /// A set of localized keywords that can help users find the activity in search results.
    ///
    @objc optional var activityKeywords: Set<String>? { get }

    /// Activity description
    ///
    @objc optional var activityDescription: String? { get }
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
            activity.contentAttributeSet = contentAttributeSet
        }

        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        activity.isEligibleForHandoff = false

        activity.isEligibleForPrediction = true

        // Set the UIViewController's userActivity property, which is defined in UIResponder. Doing this allows
        // UIKit to automagically manage this user activity (e.g. making it current when needed)
        userActivity = activity
    }
}
