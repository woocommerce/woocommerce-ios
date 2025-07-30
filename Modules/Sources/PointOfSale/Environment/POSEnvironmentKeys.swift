import SwiftUI
import Combine
import WooFoundation
import Experiments
import protocol Yosemite.Action
import struct Yosemite.Site

/// Environment key for POS analytics service in SwiftUI
public struct POSAnalyticsKey: EnvironmentKey {
    public static let defaultValue: POSAnalyticsProviding = EmptyPOSAnalytics()
}

/// Environment key for POS currency settings
public struct POSCurrencySettingsKey: EnvironmentKey {
    public static let defaultValue: POSCurrencySettingsProviding = EmptyPOSCurrencySettings()
}

/// Environment key for POS feature flags service
public struct POSFeatureFlagsKey: EnvironmentKey {
    public static let defaultValue: POSFeatureFlagProviding = EmptyPOSFeatureFlags()
}

/// Environment key for POS session manager
public struct POSSessionManagerKey: EnvironmentKey {
    public static let defaultValue: POSSessionManagerProviding = EmptyPOSSessionManager()
}

/// Environment key for POS connectivity
public struct POSConnectivityKey: EnvironmentKey {
    public static let defaultValue: POSConnectivityProviding = EmptyPOSConnectivityProvider()
}

/// Environment key for POS navigation service
public struct POSExternalNavigationKey: EnvironmentKey {
    public static let defaultValue: POSExternalNavigationProviding = EmptyPOSExternalNavigation()
}

/// Environment key for POS external view service
public struct POSExternalViewKey: EnvironmentKey {
    public static let defaultValue: POSExternalViewProviding = EmptyPOSExternalView()
}

public extension EnvironmentValues {
    var posAnalytics: POSAnalyticsProviding {
        get { self[POSAnalyticsKey.self] }
        set { self[POSAnalyticsKey.self] = newValue }
    }

    var posCurrencyProvider: POSCurrencySettingsProviding {
        get { self[POSCurrencySettingsKey.self] }
        set { self[POSCurrencySettingsKey.self] = newValue }
    }

    var posFeatureFlags: POSFeatureFlagProviding {
        get { self[POSFeatureFlagsKey.self] }
        set { self[POSFeatureFlagsKey.self] = newValue }
    }

    var posSession: POSSessionManagerProviding {
        get { self[POSSessionManagerKey.self] }
        set { self[POSSessionManagerKey.self] = newValue }
    }

    var posConnectivityProvider: POSConnectivityProviding {
        get { self[POSConnectivityKey.self] }
        set { self[POSConnectivityKey.self] = newValue }
    }

    var posExternalNavigation: POSExternalNavigationProviding {
        get { self[POSExternalNavigationKey.self] }
        set { self[POSExternalNavigationKey.self] = newValue }
    }

    var posExternalViews: POSExternalViewProviding {
        get { self[POSExternalViewKey.self] }
        set { self[POSExternalViewKey.self] = newValue }
    }
}

// MARK: - Empty Default Values

public struct EmptyPOSExternalNavigation: POSNavigationProviding {
    public func navigateToCreateOrder() {}
}

public struct EmptyPOSSessionManager: POSSessionManagerProviding {
    public var defaultSite: Site? = nil
    public init() {}
}

public struct EmptyPOSFeatureFlags: POSFeatureFlagProviding {
    public func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { false }
    public init() {}
}

public struct EmptyPOSCurrencySettings: POSCurrencySettingsProviding {
    public var currencySettings = CurrencySettings()
    public init() {}
}

public class EmptyPOSConnectivityProvider: POSConnectivityProviding {
    public var connectivityObserver: WooFoundation.ConnectivityObserver = EmptyPOSConnectivity()
    public init() {}
}

public class EmptyPOSConnectivity: ConnectivityObserver {
    @Published private(set) public var currentStatus: ConnectivityStatus = .reachable(type: .ethernetOrWiFi)
    public var statusPublisher: AnyPublisher<ConnectivityStatus, Never> { $currentStatus.eraseToAnyPublisher() }
    public func startObserving() {}
    public func stopObserving() {}
    public init() {}
}

public struct EmptyPOSAnalytics: POSAnalyticsProviding {
    public func track(event: WooAnalyticsEvent) {}
    public func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {}
    public func track(_ stat: WooAnalyticsStat) {}
    public func track(_ stat: WooFoundationCore.WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: any Error) {}
    public init() {}
}

public struct EmptyPOSExternalView: POSExternalViewProviding {
    public func createSupportFormView(isPresented: Binding<Bool>) -> AnyView { AnyView(EmptyView()) }
}
