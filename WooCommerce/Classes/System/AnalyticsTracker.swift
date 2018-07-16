import Foundation
import WordPressShared


class AnalyticsTracker: NSObject, WPAnalyticsTracker {
    var applicationOpenedTime: Date?

    override init() {
        super.init()
        WPAnalytics.register(AnalyticsTracker())
    }

    func track(_ stat: WPAnalyticsStat) {
        WPAnalytics.track(stat)
    }

    func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable : Any]!) {
        WPAnalytics.track(stat, withProperties: properties)
    }

    func trackApplicationOpened() {
        applicationOpenedTime = Date()
        track(.applicationOpened)
    }

    func trackApplicationClosed() {
        let analyticsProperties = [String: Any]()
        if let openTime = applicationOpenedTime {
            let applicationClosedTime = Date()
            let timeInApp = round(applicationClosedTime.timeIntervalSince(openTime))
            analyticsProperties[WPAppAnalyticsKeyTimeInApp] = timeInApp
        }
    }
}
