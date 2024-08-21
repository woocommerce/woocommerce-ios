import Foundation

public final class MockAnalyticsProviderPreview: AnalyticsProvider {
    public init() {}

    public func refreshUserData() {
        //
    }

    public func track(_ eventName: String) {
        //
    }

    public func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        //
    }

    public func clearEvents() {
        //
    }

    public func clearUsers() {
        //
    }
}
