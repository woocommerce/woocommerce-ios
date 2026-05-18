import EventHorizonSDK
@testable import ParcelFittingCheck

final class MockParcelFittingAnalytics: ParcelFittingAnalyticsTracking {
    struct TrackedEvent {
        let name: String
        let properties: [String: String]

        func hasProperty(_ key: String, value: String) -> Bool {
            properties[key] == value
        }
    }

    private(set) var trackedEvents: [TrackedEvent] = []

    var lastEvent: TrackedEvent? {
        trackedEvents.last
    }

    func track(_ event: Event) {
        let props = event.properties.mapValues { "\($0)" }
        trackedEvents.append(TrackedEvent(name: event.name, properties: props))
    }
}
