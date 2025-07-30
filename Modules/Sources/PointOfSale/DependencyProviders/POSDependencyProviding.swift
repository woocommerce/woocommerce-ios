import Foundation
import WooFoundation
import Experiments

/// Main dependency provider protocol for POS module
/// This abstracts away direct ServiceLocator access
public protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var stores: POSStoresProviding { get }
    var currency: POSCurrencyProviding { get }
    var storage: POSStorageProviding { get }
    var featureFlags: POSFeatureFlagProviding { get }
    var pushNotifications: POSPushNotificationProviding { get }
}

/// Analytics service abstraction
public protocol POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: Error)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType])
    func track(_ stat: WooAnalyticsStat)
}

/// Stores manager abstraction
public protocol POSStoresProviding {
    var sessionManager: POSSessionManagerProviding { get }
    // Add other stores manager methods as needed
}

/// Session manager abstraction
public protocol POSSessionManagerProviding {
    var defaultSite: POSSiteProviding? { get }
}

/// Site abstraction
public protocol POSSiteProviding {
    // Add site properties as needed during migration
}

/// Currency settings and formatting abstraction
public protocol POSCurrencyProviding {
    // Currency-related methods will be added as we migrate files
}

/// Storage manager abstraction
public protocol POSStorageProviding {
    // Storage methods will be added as we migrate files
}

/// Feature flag service abstraction
public protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}

/// Push notifications abstraction
public protocol POSPushNotificationProviding {
    // Push notification methods will be added as we migrate files
}
