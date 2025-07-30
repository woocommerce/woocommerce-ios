import PointOfSale
import WooFoundation
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import protocol Yosemite.SessionManagerProtocol
import protocol Storage.StorageManagerType
import protocol Yosemite.Action

/// Adaptor that bridges main app ServiceLocator to POS dependency abstraction to support POS modularization
final class POSServiceLocatorAdaptor: POSDependencyProviding {
    private let featureFlagService: FeatureFlagService
    private let storesManager: StoresManager
    private let connectivityObserver: ConnectivityObserver
    private let currencySettings: CurrencySettings
    private let serviceAnalytics: Analytics

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         storesManager: StoresManager = ServiceLocator.stores,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics
    ) {
        self.featureFlagService = featureFlagService
        self.storesManager = storesManager
        self.connectivityObserver = connectivityObserver
        self.currencySettings = currencySettings
        self.serviceAnalytics = analytics
    }

    var analytics: POSAnalyticsProviding {
        POSAnalyticsAdaptor(analytics: serviceAnalytics)
    }

    var stores: POSStoresProviding {
        POSStoresAdaptor(stores: storesManager)
    }

    var currency: CurrencySettings {
        currencySettings
    }

    var featureFlags: POSFeatureFlagProviding {
        POSFeatureFlagAdaptor(featureFlagService: featureFlagService)
    }

    var session: POSSessionManagerProviding {
        POSSessionManagerAdaptor(sessionManager: storesManager.sessionManager)
    }

    var connectivity: ConnectivityObserver {
        connectivityObserver
    }
}

// MARK: - Individual Service Adaptors

private struct POSStoresAdaptor: POSStoresProviding {
    private let storesManager: StoresManager

    init(stores: StoresManager) {
        self.storesManager = stores
    }

    func dispatch(_ action: any Action) {
        storesManager.dispatch(action)
    }
}

private struct POSSessionManagerAdaptor: POSSessionManagerProviding {
    private let sessionManager: SessionManagerProtocol

    init(sessionManager: SessionManagerProtocol) {
        self.sessionManager = sessionManager
    }

    var defaultSite: Site? {
        return sessionManager.defaultSite
    }
}

private struct POSFeatureFlagAdaptor: POSFeatureFlagProviding {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        return featureFlagService.isFeatureFlagEnabled(flag)
    }
}

private struct POSAnalyticsAdaptor: POSAnalyticsProviding {
    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func track(event: WooAnalyticsEvent) {
        analytics.track(event: event)
    }

    func track(_ stat: WooAnalyticsStat) {
        track(stat, parameters: [:])
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        analytics.track(stat, withProperties: parameters)
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:], error: Error) {
        analytics.track(stat, properties: parameters, error: error)
    }
}
