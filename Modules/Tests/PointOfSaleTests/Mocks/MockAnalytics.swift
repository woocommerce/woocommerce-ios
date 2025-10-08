import Foundation
import WooFoundation
@testable import PointOfSale

final class MockPOSAnalytics: POSAnalyticsProviding {
    struct TrackedEvent {
        let eventName: String
        let properties: [AnyHashable: Any]
        let error: Error?
    }

    var events: [TrackedEvent] = []

    func track(event: WooAnalyticsEvent) {
        events.append(TrackedEvent(eventName: event.statName.rawValue, properties: event.properties, error: event.error))
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:], error: Error) {
        events.append(TrackedEvent(eventName: stat.rawValue, properties: parameters, error: error))
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        events.append(TrackedEvent(eventName: stat.rawValue, properties: parameters, error: nil))
    }

    func track(_ stat: WooAnalyticsStat) {
        events.append(TrackedEvent(eventName: stat.rawValue, properties: [:], error: nil))
    }
}
