import Foundation
@testable import WooCommerce

final class MockInboxEligibilityChecker: InboxEligibilityChecker {
    var isEligible = false

    func isEligibleForInbox(siteID: Int64, completion: @escaping (Bool) -> Void) {
        completion(isEligible)
    }

    func isEligibleForInbox(siteID: Int64) async -> Bool {
        return isEligible
    }
}
