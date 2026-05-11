import Foundation
@testable import WooCommerce

final class MockWooPushNotificationEligibilityChecker: WooPushNotificationEligibilityChecking {
    var isEligible: Bool = false

    @MainActor
    func checkEligibility() async -> Bool {
        return isEligible
    }
}
