import Foundation
@testable import WooCommerce

final class MockPOSEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    var initialVisibility: Bool = false
    var result: POSEligibilityState = .eligible

    func checkInitialVisibility() async -> Bool {
        initialVisibility
    }

    @MainActor
    func checkEligibility() async -> POSEligibilityState {
        result
    }
}
