import SwiftUI
import WooFoundation
import Experiments

/// Environment key for POS analytics service
public struct POSAnalyticsKey: EnvironmentKey {
    public static let defaultValue: POSAnalyticsProviding = DefaultPOSAnalytics()
}

/// Default implementation that does nothing (for previews/testing)
private struct DefaultPOSAnalytics: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooAnalyticsStat) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooFoundationCore.WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: any Error) {
        // No-op implementation for previews/testing
    }
}

/// Environment key for POS services adapter
public struct POSServicesKey: EnvironmentKey {
    public static let defaultValue: POSDependencyProviding = DefaultPOSServices()
}

/// Default implementation for previews/testing
private struct DefaultPOSServices: POSDependencyProviding {
    var analytics: POSAnalyticsProviding = DefaultPOSAnalytics()
    var stores: POSStoresProviding = DefaultPOSStores()
    var currency: CurrencySettings = CurrencySettings()
    var storage: POSStorageProviding = DefaultPOSStorage()
    var featureFlags: POSFeatureFlagProviding = DefaultPOSFeatureFlags()
    var pushNotifications: POSPushNotificationProviding = DefaultPOSPushNotifications()
}

// Default implementations for testing
private struct DefaultPOSStores: POSStoresProviding {
    var sessionManager: POSSessionManagerProviding = DefaultPOSSessionManager()
}

private struct DefaultPOSSessionManager: POSSessionManagerProviding {
    var defaultSite: POSSiteProviding? = nil
}

private struct DefaultPOSStorage: POSStorageProviding {
}

private struct DefaultPOSFeatureFlags: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { false }
}

private struct DefaultPOSPushNotifications: POSPushNotificationProviding {
}

public extension EnvironmentValues {
    var posAnalytics: POSAnalyticsProviding {
        get { self[POSAnalyticsKey.self] }
        set { self[POSAnalyticsKey.self] = newValue }
    }

    var posServices: POSDependencyProviding {
        get { self[POSServicesKey.self] }
        set { self[POSServicesKey.self] = newValue }
    }
}
