import Foundation
import UIKit


public class WooAnalytics {

    // MARK: - Properties

    /// Shared Instance
    ///
    static let shared = WooAnalytics(analyticsProvider: TracksProvider())

    /// AnalyticsProvider: Interface to the actual analytics implementation
    ///
    private(set) var analyticsProvider: AnalyticsProvider

    /// Time when app was opened — used for calculating the time-in-app property
    ///
    private var applicationOpenedTime: Date?


    // MARK: - Initialization

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
        if let updatedProperties = updatePropertiesIfNeeded(for: stat, properties: properties) {
            analyticsProvider.track(stat.rawValue, withProperties: updatedProperties)
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
        let updatedProperties = updatePropertiesIfNeeded(for: stat, properties: errorDictionary)
        analyticsProvider.track(stat.rawValue, withProperties: updatedProperties)
    }
}


// MARK: - Private Helpers
//
private extension WooAnalytics {

    func startObservingNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationOpened), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackApplicationClosed), name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        return [PropertyKeys.propertyKeyTimeInApp: timeInApp.description]
    }

    /// This function appends any additional properties to the provided properties dict if needed.
    ///
    func updatePropertiesIfNeeded(for stat: WooAnalyticsStat, properties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard stat.shouldSendSiteProperties, StoresManager.shared.isAuthenticated else {
            return properties
        }

        var updatedProperties = properties ?? [:]
        let site = StoresManager.shared.sessionManager.defaultSite
        updatedProperties[PropertyKeys.blogIDKey] = site?.siteID
        updatedProperties[PropertyKeys.wpcomStoreKey] = site?.isWordPressStore
        return updatedProperties
    }
}


// MARK: - Constants!
//
private extension WooAnalytics {

    enum Constants {
        static let errorKeyCode         = "error_code"
        static let errorKeyDomain       = "error_domain"
        static let errorKeyDescription  = "error_description"
    }

    enum PropertyKeys {
        static let propertyKeyTimeInApp = "time_in_app"
        static let blogIDKey            = "blog_id"
        static let wpcomStoreKey        = "is_wpcom_store"
    }
}
