import Foundation
@testable import WooCommerce

final class MockInboxEligibilityChecker: InboxEligibilityChecker {
    var isEligible = false

    func isEligibleForInbox(siteID: Int64) -> Bool {
        isEligible
    }
}
