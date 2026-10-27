import Foundation
import os

public final class MockAnalyticsPreview: Analytics {
    public init(userHasOptedIn: Bool = true, analyticsProvider: AnalyticsProvider = MockAnalyticsProviderPreview()) {
        self.userHasOptedInState = OSAllocatedUnfairLock(initialState: userHasOptedIn)
        self.analyticsProvider = analyticsProvider
    }

    public func initialize() {
        //
    }

    public func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        //
    }

    public func refreshUserData() {
        //
    }

    public func setUserHasOptedOut(_ optedOut: Bool) {
        //
    }

    private let userHasOptedInState: OSAllocatedUnfairLock<Bool>

    public var userHasOptedIn: Bool {
        get { userHasOptedInState.withLock { $0 } }
        set { userHasOptedInState.withLock { $0 = newValue } }
    }

    public let analyticsProvider: AnalyticsProvider
}
