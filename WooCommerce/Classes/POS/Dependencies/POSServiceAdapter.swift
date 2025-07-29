import PointOfSale
import WooFoundation
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import protocol Yosemite.SessionManagerProtocol
import protocol Storage.StorageManagerType

/// Adapter that bridges main app ServiceLocator to POS dependency abstraction to support POS modularization
final class POSServiceAdapter: POSDependencyProviding {

    var analytics: POSAnalyticsProviding {
        return POSAnalyticsAdapter()
    }

    var stores: POSStoresProviding {
        return POSStoresAdapter(stores: ServiceLocator.stores)
    }

    var currency: CurrencySettings {
        return ServiceLocator.currencySettings
    }

    var storage: POSStorageProviding {
        return POSStorageAdapter(storage: ServiceLocator.storageManager)
    }

    var featureFlags: POSFeatureFlagProviding {
        return POSFeatureFlagAdapter(featureFlagService: ServiceLocator.featureFlagService)
    }
}

// MARK: - Individual Service Adapters

private struct POSStoresAdapter: POSStoresProviding {
    private let storesManager: StoresManager

    init(stores: StoresManager) {
        self.storesManager = stores
    }

    var sessionManager: POSSessionManagerProviding {
        return POSSessionManagerAdapter(sessionManager: storesManager.sessionManager)
    }
}

private struct POSSessionManagerAdapter: POSSessionManagerProviding {
    private let sessionManager: SessionManagerProtocol

    init(sessionManager: SessionManagerProtocol) {
        self.sessionManager = sessionManager
    }

    var defaultSite: POSSiteProviding? {
        guard let site = sessionManager.defaultSite else { return nil }
        return POSSiteAdapter(site: site)
    }
}

private struct POSSiteAdapter: POSSiteProviding {
    private let site: Site

    init(site: Site) {
        self.site = site
    }

    // Add site properties as needed during migration
}

private struct POSStorageAdapter: POSStorageProviding {
    private let storageManager: StorageManagerType

    init(storage: StorageManagerType) {
        self.storageManager = storage
    }

    // Storage methods will be added as we migrate files
}

private struct POSFeatureFlagAdapter: POSFeatureFlagProviding {
    private let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService) {
        self.featureFlagService = featureFlagService
    }

    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        return featureFlagService.isFeatureFlagEnabled(flag)
    }
}
