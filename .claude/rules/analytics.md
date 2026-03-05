# Analytics Rules

Based on `docs/tracking-events.md`.

## Adding a New Event
1. Add a new case to `WooAnalyticsStat` in `Modules/Sources/WooFoundationCore/Analytics/WooAnalyticsStat.swift`
2. If the event has custom properties, add a static factory method on `WooAnalyticsEvent` in `WooCommerce/Classes/Analytics/WooAnalyticsEvent+<Feature>.swift`

## Tracking Events
Inject `analytics: Analytics` via constructor (default to `ServiceLocator.analytics`):
```swift
import protocol WooFoundation.Analytics

final class ViewController {
    private let analytics: Analytics
    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }
}
```

- Simple event: `analytics.track(.eventName)`
- Event with properties: `analytics.track(event: .eventName(param: value))`

## WooAnalyticsEvent Factory Pattern
```swift
extension WooAnalyticsEvent {
    enum SomeAction: String {
        case tapped
        case dismissed
    }
    static func someFeatureEvent(action: SomeAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .someFeatureEvent,
                          properties: ["action": action.rawValue])
    }
}
```

## Naming
- Enum cases in `WooAnalyticsStat`: camelCase
- Raw string values: snake_case (for Android parity)
- Property keys: snake_case strings

## Testing Analytics
- Use `MockAnalyticsProvider` to verify tracked events
- Assert on event name and properties in tests
