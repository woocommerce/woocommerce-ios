import SwiftUI
import WooFoundationCore
import WooFoundation
import protocol Experiments.FeatureFlag

/// Protocol that provides analytics tracking capabilities for POS
public protocol POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent)
    func track(_ stat: WooAnalyticsStat)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType])
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: Error)
}

/// Protocol that provides currency settings access for POS
public protocol POSCurrencySettingsProviding {
    var currencySettings: CurrencySettings { get }
}

/// Protocol that provides feature flag checking capabilities for POS
public protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}

/// Protocol that provides connectivity monitoring for POS
public protocol POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver { get }
}

/// Protocol that provides main app navigation capabilities for POS
public protocol POSExternalNavigationProviding {
    func navigateToCreateOrder()
}

/// Protocol that provides external view creation capabilities for POS
public protocol POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>) -> AnyView
}

/// Main protocol that combines all POS dependency providers
/// This enables dependency injection for POS code while maintaining clean separation from ServiceLocator
public protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var currency: POSCurrencySettingsProviding { get }
    var featureFlags: POSFeatureFlagProviding { get }
    var connectivity: POSConnectivityProviding { get }
    var externalNavigation: POSExternalNavigationProviding { get }
    var externalViews: POSExternalViewProviding { get }
}