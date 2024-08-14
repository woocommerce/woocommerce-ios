import Foundation
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider

final class PointOfSaleAnalytics: Analytics {
    var userHasOptedIn: Bool {
        get {
            guard let _ : Bool? = UserDefaults.standard.object(forKey: .userOptedInAnalytics) else {
                return false
            }
            return true
        }
        set {
            // Q: Do we want to use the same value as the WooCommerce app for now?
            // or should we store it separately?
            UserDefaults.standard.set(newValue, forKey: .userOptedInAnalytics)
        }
    }
    var analyticsProvider: WooFoundation.AnalyticsProvider

    init(analyticsProvider: WooFoundation.AnalyticsProvider) {
        self.analyticsProvider = analyticsProvider
    }

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        // TODO: Actually track properties
        guard userHasOptedIn else {
            return
        }
        analyticsProvider.track(eventName, withProperties: properties)
    }
    
    func initialize() {
        refreshUserData()
        // TODO: Observe notifications and app state
    }
    
    func refreshUserData() {
        guard userHasOptedIn else {
            return
        }
        // TODO: Handle isAuthenticatedWithoutWPCom
    }
    
    func setUserHasOptedOut(_ optedOut: Bool) {
        // TODO: Not implemented
        switch userHasOptedIn {
        case true:
            DDLogInfo("🔵 Tracking started.")
        case false:
            DDLogInfo("🔴 Tracking opt-out.")
        }
    }
}
