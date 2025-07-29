import Foundation
import WooFoundation
import Experiments
import protocol Yosemite.Action
import struct Yosemite.Site

/// Main dependency provider protocol for POS module
/// This abstracts away direct ServiceLocator access
public protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var stores: POSStoresProviding { get }
    var currency: CurrencySettings { get }
    var featureFlags: POSFeatureFlagProviding { get }
    var session: POSSessionManagerProviding { get }
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
    var defaultSite: Site? { get }
}

/// Feature flag service abstraction
public protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}
