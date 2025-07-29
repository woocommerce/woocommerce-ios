import SwiftUI
import WooFoundation
import Experiments
import protocol Yosemite.Action

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

/// Environment key for POS currency settings
public struct POSCurrencySettingsKey: EnvironmentKey {
    public static let defaultValue: CurrencySettings = CurrencySettings()
}

/// Environment key for POS stores service
public struct POSStoresKey: EnvironmentKey {
    public static let defaultValue: POSStoresProviding = DefaultPOSStores()
}

/// Environment key for POS feature flags service
public struct POSFeatureFlagsKey: EnvironmentKey {
    public static let defaultValue: POSFeatureFlagProviding = DefaultPOSFeatureFlags()
}

/// Environment key for POS storage service
public struct POSStorageKey: EnvironmentKey {
    public static let defaultValue: POSStorageProviding = DefaultPOSStorage()
}

// Default implementations for testing/previews
private struct DefaultPOSStores: POSStoresProviding {
    func dispatch(_ action: Yosemite.Action) {}
}

private struct DefaultPOSSessionManager: POSSessionManagerProviding {
    var defaultSite: POSSiteProviding? = nil
}

private struct DefaultPOSStorage: POSStorageProviding {
}

private struct DefaultPOSFeatureFlags: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { false }
}

public extension EnvironmentValues {
    var posAnalytics: POSAnalyticsProviding {
        get { self[POSAnalyticsKey.self] }
        set { self[POSAnalyticsKey.self] = newValue }
    }

    var posCurrencySettings: CurrencySettings {
        get { self[POSCurrencySettingsKey.self] }
        set { self[POSCurrencySettingsKey.self] = newValue }
    }

    var posStores: POSStoresProviding {
        get { self[POSStoresKey.self] }
        set { self[POSStoresKey.self] = newValue }
    }

    var posFeatureFlags: POSFeatureFlagProviding {
        get { self[POSFeatureFlagsKey.self] }
        set { self[POSFeatureFlagsKey.self] = newValue }
    }

    var posStorage: POSStorageProviding {
        get { self[POSStorageKey.self] }
        set { self[POSStorageKey.self] = newValue }
    }
}
