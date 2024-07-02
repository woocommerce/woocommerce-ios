import Foundation
@testable import WooCommerce

final class MockInboxEligibilityChecker: InboxEligibilityChecker {
    var isEligible = false
    private(set) var isSiteEligibleInvoked = false

    func isEligibleForInbox(siteID: Int64, completion: @escaping (Bool) -> Void) {
        completion(isEligible)
        isSiteEligibleInvoked = true
    }

    func isEligibleForInbox(siteID: Int64) async -> Bool {
        isSiteEligibleInvoked = true
        return isEligible
    }
}
