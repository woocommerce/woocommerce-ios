import Foundation
import UIKit

/// This is only kept for Spotlight search conformance, as the SwiftUI code for InPersonPaymentsMenu to be searchable is never called.
/// (Error: Cannot use Scene methods for URL, NSUserActivity, and other External Events without using SwiftUI Lifecycle.
/// Without SwiftUI Lifecycle, advertising and handling External Events wastes resources, and will have unpredictable results.)
/// Instead, we call `registerUserActivity` on this empty VC from the new View Model.
class InPersonPaymentsMenuViewController: UIViewController {

}

// MARK: - SearchableActivity Conformance
extension InPersonPaymentsMenuViewController: SearchableActivityConvertible {
    var activityType: String {
        return WooActivityType.payments.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Payments", comment: "Title of the 'Payments' screen - used for spotlight indexing on iOS.")
    }

    var activityDescription: String? {
        return NSLocalizedString("Collect payments, setup Tap to Pay, order card readers and more.",
                                 comment: "Description of the 'Payments' screen - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("payments, tap to pay, woocommerce, woo, in-person payments, in person payments" +
                                              "collect payment, payments, reader, card reader, order card reader",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Payments' screen.")

        return keyWordString.setOfTags()
    }
}
