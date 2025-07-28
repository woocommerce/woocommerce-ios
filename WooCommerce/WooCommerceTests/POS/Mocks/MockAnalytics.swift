import Foundation
import WooFoundation
@testable import WooCommerce

final class MockAnalytics: Analytics {
    struct TrackedEvent {
        let eventName: String
        let properties: [AnyHashable: Any]
        let error: Error?
    }

    func initialize() {}
    func refreshUserData() {}
    func setUserHasOptedOut(_ optedOut: Bool) {}
    var userHasOptedIn: Bool = true
    var analyticsProvider: AnalyticsProvider { fatalError("Not implemented") }
    var events: [TrackedEvent] = []

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        events.append(TrackedEvent(eventName: eventName, properties: properties ?? [:], error: error))
    }
}
