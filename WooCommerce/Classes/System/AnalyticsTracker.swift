import Foundation
import AutomatticTracks

enum WCAnalyticsStat {
    case applicationOpened
    case applicationClosed
}

class AnalyticsTracker { //}: NSObject, WPAnalyticsTracker {
    var applicationOpenedTime: Date?

    init() {
//        super.init()
//        WPAnalytics.register(AnalyticsTracker())
    }

    func track(_ stat: WCAnalyticsStat) {
//        WPAnalytics.track(stat)
    }

    func track(_ stat: WCAnalyticsStat, withProperties properties: [AnyHashable : Any]?) {
//        WPAnalytics.track(stat, withProperties: properties)
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
//            analyticsProperties[WPAppAnalyticsKeyTimeInApp] = timeInApp
        }
    }
}
