import Foundation

public final class MockAnalyticsPreview: Analytics {
    public init(userHasOptedIn: Bool = true, analyticsProvider: AnalyticsProvider = MockAnalyticsProviderPreview()) {
        self.userHasOptedIn = userHasOptedIn
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

    public var userHasOptedIn: Bool

    public var analyticsProvider: AnalyticsProvider
}
