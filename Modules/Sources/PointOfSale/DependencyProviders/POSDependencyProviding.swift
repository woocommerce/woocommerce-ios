import Foundation
import SwiftUI
import WooFoundation
import Experiments
import protocol Yosemite.Action
import struct Yosemite.Site

/// Main dependency provider protocol for POS module
/// This abstracts away dependencies from the main Woo app
public protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var currency: POSCurrencySettingsProviding { get }
    var featureFlags: POSFeatureFlagProviding { get }
    var session: POSSessionManagerProviding { get }
    var connectivity: POSConnectivityProviding { get }
    var externalNavigation: POSExternalNavigationProviding { get }
    var externalViews: POSExternalViewProviding { get }
}

public protocol POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: Error)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType])
    func track(_ stat: WooAnalyticsStat)
}

public protocol POSSessionManagerProviding {
    var defaultSite: Site? { get }
}

public protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}

public protocol POSCurrencySettingsProviding {
    var currencySettings: CurrencySettings { get }
}

public protocol POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver { get }
}

/// Navigation to the Woo app service abstraction
public protocol POSExternalNavigationProviding {
    func navigateToCreateOrder()
}

/// External view service abstraction
public protocol POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>) -> AnyView
}
