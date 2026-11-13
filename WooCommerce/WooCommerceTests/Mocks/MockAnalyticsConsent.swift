@testable import WooCommerce
import os

final class MockAnalyticsConsent: AnalyticsConsentProviding {
    private let optedIn = OSAllocatedUnfairLock(initialState: true)

    var userHasOptedIn: Bool {
        get { optedIn.withLock { $0 } }
        set { optedIn.withLock { $0 = newValue } }
    }
}
