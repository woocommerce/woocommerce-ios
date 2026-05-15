import EventHorizonSDK
@testable import ParcelFittingCheck

final class MockParcelFittingAnalytics: ParcelFittingAnalyticsTracking {
    struct TrackedEvent {
        let name: String
        let properties: [String: String]
    }

    private(set) var trackedEvents: [TrackedEvent] = []

    var lastTrackedEventName: String? {
        trackedEvents.last?.name
    }

    func track(_ event: Event) {
        let props = event.properties.mapValues { "\($0)" }
        trackedEvents.append(TrackedEvent(name: event.name, properties: props))
    }

    func trackedEventNames() -> [String] {
        trackedEvents.map(\.name)
    }
}
