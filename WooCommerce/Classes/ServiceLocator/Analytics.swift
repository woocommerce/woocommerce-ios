import Foundation

protocol Analytics {
    func initialize()
    func track(_ stat: WooAnalyticsStat)
    func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable: Any]?)
    func track(_ stat: WooAnalyticsStat, withError error: Error)
    func refreshUserData()
    func setUserHasOptedOut(_ optedOut: Bool)
    var userHasOptedIn: Bool { get set }
    var analyticsProvider: AnalyticsProvider { get }
}

extension WooAnalytics: Analytics {}
