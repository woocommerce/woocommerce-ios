import Foundation
import WooFoundation
import Experiments
import protocol Yosemite.Action

/// Main dependency provider protocol for POS module
/// This abstracts away direct ServiceLocator access
public protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var stores: POSStoresProviding { get }
    var currency: CurrencySettings { get }
    var storage: POSStorageProviding { get }
    var featureFlags: POSFeatureFlagProviding { get }
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
    func dispatch(_ action: Yosemite.Action)
}

/// Session manager abstraction
public protocol POSSessionManagerProviding {
    var defaultSite: POSSiteProviding? { get }
}

/// Site abstraction
public protocol POSSiteProviding {
    // Add site properties as needed during migration
}

/// Storage manager abstraction
public protocol POSStorageProviding {
    // Storage methods will be added as we migrate files
}

/// Feature flag service abstraction
public protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}
