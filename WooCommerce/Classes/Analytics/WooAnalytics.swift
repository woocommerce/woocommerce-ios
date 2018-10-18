import Foundation
import UIKit


public class WooAnalytics {

    // MARK: - Properties

    /// Shared Instance
    ///
    static let shared = WooAnalytics(analyticsProvider: TracksProvider())

    /// AnalyticsProvider: Interface to the actual analytics implementation
    ///
    private(set) var analyticsProvider: AnalyticsProvider?

    /// Time when app was opened — used for calculating the time-in-app property
    ///
    private var applicationOpenedTime: Date?


    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(analyticsProvider: AnalyticsProvider) {
        initializeOptOutTracking()

        if !userHasOptedOut() {
            self.analyticsProvider = analyticsProvider
        }
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
        analyticsProvider?.refreshUserData()
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
            analyticsProvider?.track(stat.rawValue, withProperties: properties)
        } else {
            analyticsProvider?.track(stat.rawValue)
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
        analyticsProvider?.track(stat.rawValue, withProperties: errorDictionary)
    }
}


// MARK: - Opt Out
//
extension WooAnalytics {
    /// Initialize the opt-out tracking
    ///
    func initializeOptOutTracking() {
        if userHasOptedOutIsSet() {
            // We've already configured the opt out setting
            return
        }

        // set the default to no, user has not opted out yet
        setUserHasOptedOutValue(false)
    }

    func userHasOptedOutIsSet() -> Bool {
        return UserDefaults.standard.object(forKey: UserDefaults.Key.userOptedOutOfAnalytics) != nil
    }

    /// This method just sets the user defaults value for UserOptedOut and doesn't
    /// do any additional configuration of sessions or trackers.
    func setUserHasOptedOutValue(_ optedOut: Bool) {
        UserDefaults.standard.set(optedOut, forKey: UserDefaults.Key.userOptedOutOfAnalytics)
    }

    func userHasOptedOut() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Key.userOptedOutOfAnalytics.rawValue)
    }

    func setUserHasOptedOut(_ optedOut: Bool) {
        if userHasOptedOutIsSet() {
            let currentValue = userHasOptedOut()
            if currentValue == optedOut {
                return
            }
        }

        // store the preference
        setUserHasOptedOutValue(optedOut)

        // now take action on the preference
        if (optedOut) {
            stopObservingNotifications()
            analyticsProvider?.clearTracksEvents()
            analyticsProvider = nil
        } else {
            if analyticsProvider == nil {
                analyticsProvider = TracksProvider()
                startObservingNotifications()
            }
        }
    }
}


// MARK: - Private Helpers
//
private extension WooAnalytics {

    func startObservingNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationOpened), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationClosed), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func stopObservingNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc func trackApplicationOpened() {
        track(.applicationOpened)
        applicationOpenedTime = Date()
    }

    @objc func trackApplicationClosed() {
        track(.applicationClosed, withProperties: applicationClosedProperties())
        applicationOpenedTime = nil
    }

    func applicationClosedProperties() -> [String: Any]? {
        guard let applicationOpenedTime = applicationOpenedTime else {
            return nil
        }

        let timeInApp = round(Date().timeIntervalSince(applicationOpenedTime))
        return [Constants.propertyKeyTimeInApp: timeInApp.description]
    }
}


// MARK: - Constants!
//
private extension WooAnalytics {

    enum Constants {
        static let errorKeyCode         = "error_code"
        static let errorKeyDomain       = "error_domain"
        static let errorKeyDescription  = "error_description"

        static let propertyKeyTimeInApp = "time_in_app"
    }
}
