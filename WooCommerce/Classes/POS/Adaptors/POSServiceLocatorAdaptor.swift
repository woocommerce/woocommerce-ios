import SwiftUI
import WooFoundationCore
import WooFoundation
import Yosemite
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import protocol Storage.StorageManagerType

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

    var connectivity: POSConnectivityProviding {
        POSConnectivityAdaptor()
    }

    var externalNavigation: POSExternalNavigationProviding {
        POSExternalNavigationAdaptor()
    }

    var externalViews: POSExternalViewProviding {
        POSExternalViewAdaptor()
    }
}

// MARK: - Individual Service Adaptors

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

private struct POSConnectivityAdaptor: POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver {
        ServiceLocator.connectivityObserver
    }
}

private struct POSExternalNavigationAdaptor: POSExternalNavigationProviding {
    func navigateToCreateOrder() {
        AppDelegate.shared.tabBarController?.navigate(to: OrdersDestination.createOrder)
    }
}

private struct POSExternalViewAdaptor: POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>, sourceTag: String) -> AnyView {
        AnyView(
            SupportForm(isPresented: isPresented,
                        viewModel: SupportFormViewModel(sourceTag: sourceTag,
                                                        defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
        )
    }
}
