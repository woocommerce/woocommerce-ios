import Experiments
import Foundation
import UIKit
import WordPressShared
import WidgetKit
import enum Alamofire.AFError
import Yosemite
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider

final class WooAnalytics: Analytics {

    // MARK: - Properties

    /// AnalyticsProvider: Interface to the actual analytics implementation
    ///
    private(set) var analyticsProvider: AnalyticsProvider

    /// Time when app was opened — used for calculating the time-in-app property
    ///
    private var applicationOpenedTime: Date?

    /// Check user opt-in for analytics
    ///
    var userHasOptedIn: Bool {
        get {
            let isUITesting: Bool = CommandLine.arguments.contains("-ui_testing")
            let optedIn: Bool? = UserDefaults.standard.object(forKey: .userOptedInAnalytics)
            return ( optedIn ?? true ) && !isUITesting // analytics tracking on by default, but disabled for UI tests
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .userOptedInAnalytics)
        }
    }


    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(analyticsProvider: AnalyticsProvider & WPAnalyticsTracker) {
        self.analyticsProvider = analyticsProvider
        WPAnalytics.register(analyticsProvider)
    }
}


// MARK: - Public Interface
//
extension WooAnalytics {

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
        guard userHasOptedIn == true else {
            return
        }

        // Skips refreshing user data when user is authenticated without WPCom
        // since they are still identified with anonymous ID.
        if ServiceLocator.stores.isAuthenticatedWithoutWPCom == false {
            analyticsProvider.refreshUserData()
        }

        // Refreshes A/B experiments since `ExPlat.shared` is reset after each `TracksProvider.refreshUserData` call
        // and any A/B test assignments that come back after the shared instance is reset won't be saved for later
        // access.
        let context: ExperimentContext = ServiceLocator.stores.isAuthenticated ?
            .loggedIn: .loggedOut
        Task { @MainActor in
            await ABTest.start(for: context)
        }
    }

    /// Consider calling `track(_ stat:properties:error:)` with the `WooAnalyticsStat` enum.
    /// Track a specific event with associated properties and an associated error (that is translated to properties)
    ///
    /// - Parameters:
    ///   - eventName: the event name
    ///   - properties: a collection of properties related to the event
    ///   - error: the error to track
    ///
    func track(_ eventName: String, properties passedProperties: [AnyHashable: Any]?, error: Error?) {
        guard userHasOptedIn == true else {
            return
        }
        let properties = combinedProperties(from: error, with: passedProperties)
        if let properties {
            analyticsProvider.track(eventName, withProperties: properties)
        } else {
            analyticsProvider.track(eventName)
        }
    }
}


// MARK: - Opt Out
//
extension WooAnalytics {

    func setUserHasOptedOut(_ optedOut: Bool) {
        userHasOptedIn = !optedOut

        if optedOut {
            analyticsProvider.clearEvents()
            analyticsProvider.clearUsers()
            DDLogInfo("🔴 Tracking opt-out complete.")
        } else {
            refreshUserData()
            DDLogInfo("🔵 Tracking started.")
        }
    }
}

extension Analytics {
    /// Track a specific event.
    ///
    /// - Parameter event: The event to track along with its properties.
    ///
    func track(event: WooAnalyticsEvent) {
        track(event.statName, properties: event.properties, error: event.error)
    }
}

extension Analytics {
    /// Track a specific event without any associated properties
    ///
    /// - Parameter stat: the event name
    ///
    func track(_ stat: WooAnalyticsStat) {
        guard userHasOptedIn == true else {
            return
        }

        track(stat, withProperties: nil)
    }

    /// Track a specific event with associated properties
    ///
    /// - Parameters:
    ///   - stat: the event name
    ///   - properties: a collection of properties related to the event
    ///
    func track(_ stat: WooAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        track(stat, properties: properties, error: nil)
    }

    /// Track a specific event with an associated error (that is translated to properties)
    ///
    /// - Parameters:
    ///   - stat: the event name
    ///   - error: the error to track
    ///
    func track(_ stat: WooAnalyticsStat, withError error: Error) {
        track(stat, properties: nil, error: error)
    }

    /// Track a specific event with associated properties and an associated error (that is translated to properties)
    ///
    /// - Parameters:
    ///   - stat: the event name
    ///   - properties: a collection of properties related to the event
    ///   - error: the error to track
    ///
    func track(_ stat: WooAnalyticsStat, properties passedProperties: [AnyHashable: Any]?, error: Error?) {
        guard userHasOptedIn == true else {
            return
        }

        let updatedProperties = updatePropertiesIfNeeded(for: stat, properties: passedProperties)
        track(stat.rawValue, properties: updatedProperties, error: error)
    }
}

private extension Analytics {
    /// This function appends any additional properties to the provided properties dict if needed.
    ///
    func updatePropertiesIfNeeded(for stat: WooAnalyticsStat, properties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard stat.shouldSendSiteProperties, ServiceLocator.stores.isAuthenticated else {
            return properties
        }

        var updatedProperties = properties ?? [:]
        let site = ServiceLocator.stores.sessionManager.defaultSite
        updatedProperties[PropertyKeys.blogIDKey] = site?.siteID
        updatedProperties[PropertyKeys.wpcomStoreKey] = site?.isWordPressComStore
        updatedProperties[PropertyKeys.ecommerceTrialKey] = site?.wasEcommerceTrial
        updatedProperties[PropertyKeys.planKey] = site?.plan
        updatedProperties[PropertyKeys.siteURL] = site?.url
        updatedProperties[PropertyKeys.storeID] = ServiceLocator.stores.sessionManager.defaultStoreUUID
        return updatedProperties
    }

    func combinedProperties(from error: Error?, with passedProperties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        let properties: [AnyHashable: Any]?
        let errorProperties = errorProperties(from: error)

        if let passedProperties = passedProperties {
            properties = passedProperties.merging(errorProperties ?? [:], uniquingKeysWith: { current, _ in
                current
            })
        } else {
            properties = errorProperties
        }
        return properties
    }

    func errorProperties(from error: Error?) -> [AnyHashable: Any]? {
        guard let error = error else {
            return nil
        }

        let err = error as NSError
        let errorCode: String = {
            if let networkError = error as? AFError {
                return "\(networkError.responseCode ?? 0)"
            } else if let loginError = error as? SiteCredentialLoginError {
                return "\(loginError.underlyingError.code)"
            }
            return "\(err.code)"
        }()
        let errorDomain = err.domain
        let errorDescription = err.description

        return [
            Constants.errorKeyCode: errorCode,
            Constants.errorKeyDomain: errorDomain,
            Constants.errorKeyDescription: errorDescription
        ]
    }
}

// MARK: - Private Helpers
//
private extension WooAnalytics {

    func startObservingNotifications() {
        guard userHasOptedIn == true else {
            return
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackApplicationOpened),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackApplicationClosed),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc func trackApplicationOpened() {
        WidgetCenter.shared.getCurrentConfigurations { [weak self] configurationResult in
            guard let self = self else { return }
            self.track(.applicationOpened, withProperties: self.applicationOpenedProperties(configurationResult))
        }
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

    /// Builds the necesary properties for the `application_opened` event.
    ///
    func applicationOpenedProperties(_ configurationResult: Result<[WidgetInfo], Error>) -> [String: String] {
        guard let installedWidgets = try? configurationResult.get() else {
            return ["widgets": ""]
        }

        // Translate the widget kind into a name recognized by tracks.
        let widgetAnalyticNames: [String] = installedWidgets.map { widgetInfo in
            switch widgetInfo.kind {
            case WooConstants.storeInfoWidgetKind:
                return "\(WooAnalyticsEvent.Widgets.Name.todayStats.rawValue)-\(widgetInfo.family)"
            case WooConstants.appLinkWidgetKind:
                return WooAnalyticsEvent.Widgets.Name.appLink.rawValue
            default:
                DDLogWarn("⚠️ Make sure the widget: \(widgetInfo.kind), has the correct tracks name.")
                return widgetInfo.kind
            }
        }

        return ["widgets": widgetAnalyticNames.joined(separator: ",")]
    }
}


// MARK: - Constants!
//
private enum Constants {
    static let errorKeyCode         = "error_code"
    static let errorKeyDomain       = "error_domain"
    static let errorKeyDescription  = "error_description"
}

private enum PropertyKeys {
    static let propertyKeyTimeInApp = "time_in_app"
    static let blogIDKey            = "blog_id"
    static let wpcomStoreKey        = "is_wpcom_store"
    static let ecommerceTrialKey    = "was_ecommerce_trial"
    static let planKey              = "plan"
    static let siteURL              = "site_url"
    static let storeID              = "store_id"
}
