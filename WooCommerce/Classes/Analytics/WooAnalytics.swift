import Foundation


public enum WooAnalyticsStat: String {
    case applicationOpened = "application_opened"
    case applicationClosed = "application_closed"
}


public class WooAnalytics {

    /// Shared Instance
    ///
    static let shared = WooAnalytics(analyticsProvider: TracksProvider())

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

    /// Initialize the analytics engine
    ///
    func initialize() {
        refreshUserData()
        startObservingNotifications()
    }

    /// Refresh the tracking metadata for the currently logged-in or anonymous user.
    /// It's good to call this function after a user logs in or out of the app.
    ///
    func refreshUserData() {
        analyticsProvider.refreshUserData()
    }

    /// Track a spcific event without any associated properties
    ///
    /// - Parameter stat: the event name
    ///
    func track(_ stat: WooAnalyticsStat) {
        track(stat, withProperties: nil)
    }

    /// Track a spcific event with associated properties
    ///
    /// - Parameters:
    ///   - stat: the event name
    ///   - properties: a collection of properties related to the event
    ///
    func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        if let properties = properties {
            analyticsProvider.track(stat.rawValue, withProperties: properties)
        } else {
            analyticsProvider.track(stat.rawValue)
        }
    }

    /// Track a specific event with an associated error (that is translated to properties)
    ///
    /// - Parameters:
    ///   - stat: the event name
    ///   - error: the error to track
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
