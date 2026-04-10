@testable import PointOfSale

final class MockPOSSunsetWarningChecker: POSSunsetWarningChecking {
    var shouldShow: Bool
    var recordDismissalCalled = false

    init(shouldShow: Bool = false) {
        self.shouldShow = shouldShow
    }

    func shouldShowSunsetWarning(siteID: Int64) async -> Bool {
        shouldShow
    }

    func recordDismissal(siteID: Int64) {
        recordDismissalCalled = true
    }
}
