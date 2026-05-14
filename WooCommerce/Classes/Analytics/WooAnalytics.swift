import EventHorizonSDK
import Experiments
import Foundation
import UIKit
import WordPressShared
import WidgetKit
import enum Alamofire.AFError
import enum Networking.NetworkError
import Yosemite
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
import WooFoundationCore

final class WooAnalytics: Analytics {

    // MARK: - Properties

    /// AnalyticsProvider: Interface to the actual analytics implementation
    ///
    private(set) var analyticsProvider: AnalyticsProvider

    /// Time when app was opened — used for calculating the time-in-app property
    ///
    private var applicationOpenedTime: Date?

    private lazy var widgetSetupChangeTracker = WidgetSetupChangeTracker()

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

// MARK: - EventHorizon Event Bridge

extension Analytics {
    func track(_ event: Event) {
        let properties = event.properties as [AnyHashable: Any]
        let enrichedProperties = appendSiteProperties(to: properties)
        track(event.name, properties: enrichedProperties, error: nil)
    }

    func track(_ eventName: String, withEventProperties properties: [String: any CustomStringConvertible]) {
        let enrichedProperties = appendSiteProperties(to: properties as [AnyHashable: Any])
        track(eventName, properties: enrichedProperties, error: nil)
    }
}

// MARK: - Site Property Enrichment

fileprivate extension Analytics {
    /// Appends site properties (blog_id, is_wpcom_store, etc.) to the given properties dictionary,
    /// using the currently selected site from the session. Delegates the per-site property mapping
    /// to `Site.analyticsProperties` so per-target-site event factories can share the same logic.
    func appendSiteProperties(to properties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard ServiceLocator.stores.isAuthenticated else {
            return properties
        }

        var updatedProperties = properties ?? [:]
        if let site = ServiceLocator.stores.sessionManager.defaultSite {
            for (key, value) in site.analyticsProperties {
                updatedProperties[key] = value
            }
        }
        updatedProperties[PropertyKeys.storeID] = ServiceLocator.stores.sessionManager.defaultStoreUUID
        updatedProperties[PropertyKeys.cachedWooCommerceVersionKey] = ServiceLocator.stores.sessionManager.cachedWooCommerceVersion
        return updatedProperties
    }
}

private extension Analytics {
    func updatePropertiesIfNeeded(for stat: WooAnalyticsStat, properties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard stat.shouldSendSiteProperties else {
            return properties
        }
        return appendSiteProperties(to: properties)
    }

    func combinedProperties(from error: Error?, with passedProperties: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        let properties: [AnyHashable: Any]?
        let errorProperties = errorProperties(from: error)

        if let passedProperties {
            properties = passedProperties.merging(errorProperties ?? [:], uniquingKeysWith: { current, _ in
                current
            })
        } else {
            properties = errorProperties
        }
        return properties
    }

    func errorProperties(from error: Error?) -> [AnyHashable: Any]? {
        guard let error else {
            return nil
        }
        return [
            Constants.errorKeyCode: error.errorCode.description,
            Constants.errorKeyDomain: error.errorDomain,
            Constants.errorKeyDescription: (error as NSError).description
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
            guard let self else { return }

            let applicationProperties = self.applicationOpenedProperties(configurationResult)

            guard let infos = try? configurationResult.get() else {
                self.track(.applicationOpened, withProperties: applicationProperties)
                return
            }

            let snapshot = WidgetSnapshot(from: infos)
            var properties = applicationProperties.merging(snapshot.analyticsProperties) { _, new in new }
            if let diff = self.widgetSetupChangeTracker.evaluate(currentSnapshot: snapshot) {
                properties.merge(diff.analyticsProperties) { _, new in new }
            }
            self.track(.applicationOpened, withProperties: properties)
        }
        applicationOpenedTime = Date()
    }

    @objc func trackApplicationClosed() {
        track(.applicationClosed, withProperties: applicationClosedProperties())
        applicationOpenedTime = nil
    }

    func applicationClosedProperties() -> [String: Any]? {
        guard let applicationOpenedTime else {
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
    static let storeID              = "store_id"
    static let cachedWooCommerceVersionKey = "cached_woo_core_version"
}
