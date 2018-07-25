import Foundation


public enum WooAnalyticsStat: String {
    case applicationOpened = "woocommerceios_application_opened"
    case applicationClosed = "woocommerceios_application_closed"
}


public class WooAnalytics {

    /// Shared Instance
    ///
    static var shared = WooAnalytics(analyticsProvider: TracksProvider())

    /// AnalyticsProvider: Interface to the actual analytics implementation
    ///
    private(set) var analyticsProvider: AnalyticsProvider

    /// Designated Initializer
    ///
    init(analyticsProvider: AnalyticsProvider) {
        self.analyticsProvider = analyticsProvider
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Public Interface
//
public extension WooAnalytics {

    /// Initialize the analytics
    ///
    func initialize() {
        self.analyticsProvider.beginSession()
        self.startObservingNotifications()
    }

    /// Pass through function to AnalyticsProvider.track(eventName:)
    ///
    func track(_ stat: WooAnalyticsStat) {
        track(stat, withProperties: nil)
    }


    /// Pass through function to AnalyticsProvider.track(eventName:withProperties:)
    ///
    func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable : Any]?) {
        if let properties = properties {
            analyticsProvider.track(stat.rawValue, withProperties: properties)
        } else {
            analyticsProvider.track(stat.rawValue)
        }
    }


    /// Track a spcific event with an associated error (that is translated to properties)
    ///
    func track(_ stat: WooAnalyticsStat, withError error: Error) {
        let err = error as NSError
        let errorDictionary = [Constants.errorKeyCode: "\(err.code)",
                               Constants.errorKeyDomain: err.domain,
                               Constants.errorKeyDescription: err.description]
        analyticsProvider.track(stat.rawValue, withProperties: errorDictionary)
    }
}


// MARK: - Notifications!
//
private extension WooAnalytics {

    func startObservingNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationOpened), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationClosed), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    @objc func trackApplicationOpened() {
        track(.applicationOpened)
    }

    @objc func trackApplicationClosed() {
        track(.applicationClosed)
    }
}


// MARK: - Constants!
//
private extension WooAnalytics {

    enum Constants {
        static let errorKeyCode        = "error_code"
        static let errorKeyDomain      = "error_domain"
        static let errorKeyDescription = "error_description"
    }
}
