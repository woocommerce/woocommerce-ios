import Foundation
@testable import WooCommerce

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var result: POSEligibilityState = .eligible

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        result
    }
}
