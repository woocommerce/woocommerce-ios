import SwiftUI
import protocol Experiments.FeatureFlagService
import struct Storage.GeneralAppSettingsStorage
import BackgroundTasks

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

    func forceScheduleFullSync() {
        DDLogInfo("🔧 [DEV] [FORCE-SCHEDULE] Forcing full sync task to be scheduled...")
        AppDelegate.shared.posCatalogSyncManager.scheduleFullCatalogSync()
    }

    func forceScheduleIncrementalSync() {
        DDLogInfo("🔧 [DEV] [FORCE-SCHEDULE] Forcing incremental sync task to be scheduled...")
        AppDelegate.shared.posCatalogSyncManager.scheduleIncrementalSync()
    }

    func forceScheduleMainAppRefresh() {
        DDLogInfo("🔧 [DEV] [FORCE-SCHEDULE] Forcing main app refresh task to be scheduled...")
        AppDelegate.shared.appRefreshHandler.scheduleAppRefresh()
    }

    func forceScheduleAllTasks() {
        DDLogInfo("🔧 [DEV] [FORCE-SCHEDULE] Forcing all background tasks to be scheduled...")
        AppDelegate.shared.appRefreshHandler.scheduleAppRefresh()
        AppDelegate.shared.posCatalogSyncManager.scheduleFullCatalogSync()
        AppDelegate.shared.posCatalogSyncManager.scheduleIncrementalSync()
    }

    // MARK: - Cancel Background Tasks

    func cancelFullSyncTask() {
        DDLogInfo("🔧 [DEV] [CANCEL] Cancelling full sync task...")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: POSCatalogSyncBackgroundTaskManager.fullCatalogSyncIdentifier)
    }

    func cancelIncrementalSyncTask() {
        DDLogInfo("🔧 [DEV] [CANCEL] Cancelling incremental sync task...")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: POSCatalogSyncBackgroundTaskManager.incrementalSyncIdentifier)
    }

    func cancelMainAppRefreshTask() {
        DDLogInfo("🔧 [DEV] [CANCEL] Cancelling main app refresh task...")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskRefreshDispatcher.taskIdentifier)
    }

    func cancelAllBackgroundTasks() {
        DDLogInfo("🔧 [DEV] [CANCEL] Cancelling ALL background tasks...")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskRefreshDispatcher.taskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: POSCatalogSyncBackgroundTaskManager.fullCatalogSyncIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: POSCatalogSyncBackgroundTaskManager.incrementalSyncIdentifier)
    }
#endif
}
