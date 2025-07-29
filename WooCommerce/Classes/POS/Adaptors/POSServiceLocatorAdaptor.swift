import PointOfSale
import WooFoundation
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import protocol Yosemite.SessionManagerProtocol
import protocol Storage.StorageManagerType
import protocol Yosemite.Action
import struct Yosemite.Site

/// Adaptor that bridges main app ServiceLocator to POS dependency abstraction to support POS modularization
final class POSServiceLocatorAdaptor: POSDependencyProviding {
    var analytics: POSAnalyticsProviding {
        return POSAnalyticsAdaptor()
    }

    var stores: POSStoresProviding {
        return POSStoresAdaptor(stores: ServiceLocator.stores)
    }

    var currency: CurrencySettings {
        return ServiceLocator.currencySettings
    }

    var featureFlags: POSFeatureFlagProviding {
        return POSFeatureFlagAdaptor(featureFlagService: ServiceLocator.featureFlagService)
    }

    var session: POSSessionManagerProviding {
        return POSSessionManagerAdaptor(sessionManager: ServiceLocator.stores.sessionManager)
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
    func track(event: WooAnalyticsEvent) {
        let mainAppEvent = WooAnalyticsEvent(statName: event.statName, properties: event.properties, error: event.error)
        ServiceLocator.analytics.track(event: mainAppEvent)
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
