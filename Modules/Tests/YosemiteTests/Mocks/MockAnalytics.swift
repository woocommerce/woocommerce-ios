import Foundation
import WooFoundation

/// Simple mock for Analytics protocol used in Yosemite tests
final class MockAnalytics: Analytics {
    struct TrackedEvent {
        let eventName: String
        let properties: [AnyHashable: Any]?
        let error: Error?
    }

    var trackedEvents: [TrackedEvent] = []
    var userHasOptedIn: Bool = true
    let analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()

    func initialize() {}

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        trackedEvents.append(TrackedEvent(eventName: eventName, properties: properties, error: error))
    }

    func refreshUserData() {}

    func setUserHasOptedOut(_ optedOut: Bool) {
        userHasOptedIn = !optedOut
    }
}

/// Minimal mock for AnalyticsProvider
final class MockAnalyticsProvider: AnalyticsProvider {
    func refreshUserData() {}
    func track(_ eventName: String) {}
    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {}
    func clearEvents() {}
    func clearUsers() {}
}
