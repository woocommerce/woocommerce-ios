import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider

final class PointOfSaleAnalytics: Analytics {
    init(userHasOptedIn: Bool, analyticsProvider: WooFoundation.AnalyticsProvider) {
        self.userHasOptedIn = userHasOptedIn
        self.analyticsProvider = analyticsProvider
    }

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        analyticsProvider.track(eventName)
    }
    
    func initialize() {
        // Not implemented
    }
    
    func refreshUserData() {
        // Not implemented
    }
    
    func setUserHasOptedOut(_ optedOut: Bool) {
        // Not implemented
    }
    
    var userHasOptedIn: Bool

    var analyticsProvider: WooFoundation.AnalyticsProvider
}
