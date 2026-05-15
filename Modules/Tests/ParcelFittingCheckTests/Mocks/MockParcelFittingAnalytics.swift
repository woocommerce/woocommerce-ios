import Testing
import EventHorizonSDK
@testable import ParcelFittingCheck

final class MockParcelFittingAnalytics: ParcelFittingAnalyticsTracking {
    struct TrackedEvent {
        let name: String
        let properties: [String: String]

        func hasProperty(_ key: String, value: String, sourceLocation: SourceLocation = #_sourceLocation) {
            let actual = properties[key]
            #expect(actual == value, "Expected property \"\(key)\" to be \"\(value)\", got \"\(actual ?? "nil")\"",
                    sourceLocation: sourceLocation)
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
