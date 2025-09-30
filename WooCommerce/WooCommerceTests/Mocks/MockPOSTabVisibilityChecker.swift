import Foundation
@testable import WooCommerce

final class MockPOSTabVisibilityChecker: POSTabVisibilityCheckerProtocol {
    var initialVisibility: Bool = false
    var visibility: Bool = false

    func checkInitialVisibility() -> Bool {
        initialVisibility
    }

    @MainActor
    func checkVisibility() async -> Bool {
        visibility
    }
}
