import PointOfSale
import WooFoundation
import SwiftUI
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import protocol Yosemite.SessionManagerProtocol
import protocol Storage.StorageManagerType
import protocol Yosemite.Action

/// Adaptor that bridges main app ServiceLocator to POS dependency abstraction to support POS modularization
/// ServiceLocator is used directly in getters to always get the latest version of services at the moment they are used
///
final class POSServiceLocatorAdaptor: POSDependencyProviding {
    var analytics: POSAnalyticsProviding {
        POSAnalyticsAdaptor()
    }

    var currency: POSCurrencySettingsProviding {
        POSCurrencySettingsAdaptor()
    }

    var featureFlags: POSFeatureFlagProviding {
        POSFeatureFlagAdaptor()
    }

    var session: POSSessionManagerProviding {
        POSSessionManagerAdaptor()
    }

    var connectivity: POSConnectivityProviding {
        POSConnectivityAdaptor()
    }

    var externalNavigation: POSExternalNavigationProviding {
        POSExternalNavigationAdaptor(deepLinkNavigator: deepLinkNavigator)
    }

    var externalViews: POSExternalViewProviding {
        POSExternalViewAdaptor()
    }
}

// MARK: - Individual Service Adaptors

private struct POSSessionManagerAdaptor: POSSessionManagerProviding {
    var defaultSite: Site? {
        return ServiceLocator.stores.sessionManager.defaultSite
    }
}

private struct POSCurrencySettingsAdaptor: POSCurrencySettingsProviding {
    var currencySettings: CurrencySettings {
        ServiceLocator.currencySettings
    }
}

private struct POSFeatureFlagAdaptor: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        return ServiceLocator.featureFlagService.isFeatureFlagEnabled(flag)
    }
}

private struct POSAnalyticsAdaptor: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {
        ServiceLocator.analytics.track(event: event)
    }

    func track(_ stat: WooAnalyticsStat) {
        track(stat, parameters: [:])
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        ServiceLocator.analytics.track(stat, withProperties: parameters)
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:], error: Error) {
        ServiceLocator.analytics.track(stat, properties: parameters, error: error)
    }
}

private struct POSConnectivityAdaptor: POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver {
        ServiceLocator.connectivityObserver
    }
}

private struct POSExternalNavigationAdaptor: POSExternalNavigationProviding {
    func navigateToCreateOrder() {
        AppDelegate.shared.tabBarController.navigate(to: OrdersDestination.createOrder)
    }
}

private struct POSExternalViewAdaptor: POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>) -> AnyView {
        AnyView(
            SupportForm(isPresented: isPresented,
                       viewModel: SupportFormViewModel(sourceTag: "pos",
                                                     defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
        )
    }
}
