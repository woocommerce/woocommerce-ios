# Tracking Events

To add a new event, the event name has to be added as a `case` in the [`WooAnalyticsStat` enum](../WooCommerce/Classes/Analytics/WooAnalyticsStat.swift). Tracking the event looks like this:

```swift
final class ViewController {
    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    private func onUpdateButtonPress() {
        analytics.track(.productDetailUpdateButtonTapped)
    }
}
```

Having the `String` values in the `WooAnalyticsStat` enum helps us with comparing the events being tracked in WooCommerce Android.

## Custom Properties

If the event has custom properties, add a corresponding `static func` [`WooAnalyticsEvent`](../WooCommerce/Classes/Analytics/WooAnalyticsEvent.swift) constructor of the event. Add the custom properties as parameters of the function. For example:

```swift
extension WooAnalyticsEvent {

    public enum AppFeedbackPromptAction: String {
        case shown
        case liked
        case didntLike = "didnt_like"
    }

    static func appFeedbackPrompt(action: AppFeedbackPromptAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .appFeedbackPrompt,
                          properties: ["action": action.rawValue])
    }
}
```

Tracking the event would now look like this:

```swift
analytics.track(event: .appFeedbackPrompt(action: .liked))
```

Organizing events and their custom properties this way helps us with:

- Answering what custom properties are available for an event and what the valid values are.
- Decreasing the risk of costly typos. A typo in an event name or its property would set us back in analyzing the correct data.
