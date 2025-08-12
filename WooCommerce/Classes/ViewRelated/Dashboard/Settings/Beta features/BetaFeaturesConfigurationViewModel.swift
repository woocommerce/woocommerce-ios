import SwiftUI
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage

final class BetaFeaturesConfigurationViewModel: ObservableObject {
    @Published private(set) var availableFeatures: [BetaFeature] = []
    private let appSettings: GeneralAppSettingsStorage
    private let featureFlagService: FeatureFlagService

    init(appSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.appSettings = appSettings
        self.featureFlagService = featureFlagService
        availableFeatures = BetaFeature.allCases.filter { betaFeature in
            switch betaFeature {
                case .viewAddOns:
                    return true
            }
        }
    }

    func isOn(feature: BetaFeature) -> Binding<Bool> {
        appSettings.betaFeatureEnabledBinding(feature)
    }
    
    #if DEBUG
    // MARK: - POS Catalog Sync Testing
    
    func triggerPOSFullSync() {
        DDLogInfo("🔧 [DEV] [FULL-SYNC] Triggering POS full catalog sync from beta features menu...")
        POSCatalogSyncDevelopmentHelper.triggerManualSync()
    }
    
    func triggerPOSIncrementalSync() {
        DDLogInfo("🔧 [DEV] [INCREMENTAL-SYNC] Triggering POS incremental sync from beta features menu...")
        POSCatalogSyncController.shared.triggerIncrementalSync()
    }
    
    func logPOSSyncStatus() {
        DDLogInfo("🔧 [DEV] [STATUS] Logging POS sync status from beta features menu...")
        POSCatalogSyncDevelopmentHelper.logCurrentSyncState()
    }
    #endif
}
