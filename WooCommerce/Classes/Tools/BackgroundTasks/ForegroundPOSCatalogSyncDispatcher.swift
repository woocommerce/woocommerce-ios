import Foundation
import UIKit
import CocoaLumberjackSwift
import Yosemite
import Experiments

/// Periodically syncs POS catalog while the app is in the foreground.
/// Triggers `catalogCoordinator.performSmartSync()` every hour when active.
///
final actor ForegroundPOSCatalogSyncDispatcher {
    private enum Constants {
        static let syncInterval: TimeInterval = 60 * 60 // 1 hour
        static let leeway: Int = 5 // 5 seconds leeway to give a system more flexibility in managing resources
    }

    private let interval: TimeInterval
    private let notificationCenter: NotificationCenter
    private let timerProvider: DispatchTimerProviding
    private let featureFlagService: FeatureFlagService
    private let storeProvider: POSCatalogStoreProviding
    private let isAppActive: () async -> Bool
    private var observers: [NSObjectProtocol] = []
    private var timer: DispatchTimerProtocol?

    private var isRunning: Bool {
        syncSiteID != nil
    }
    private var syncSiteID: Int64?

    init(interval: TimeInterval = Constants.syncInterval,
         notificationCenter: NotificationCenter = .default,
         timerProvider: DispatchTimerProviding = DefaultDispatchTimerProvider(),
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         storeProvider: POSCatalogStoreProviding = DefaultPOSCatalogStoreProvider(),
         isAppActive: @escaping () async -> Bool = UIApplication.isApplicationActive) {
        self.interval = interval
        self.notificationCenter = notificationCenter
        self.timerProvider = timerProvider
        self.featureFlagService = featureFlagService
        self.storeProvider = storeProvider
        self.isAppActive = isAppActive
    }

    func start() async {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI) else {
            return
        }

        if syncSiteID != nil, syncSiteID != storeProvider.defaultStoreID {
            DDLogInfo("🔄 ForegroundPOSCatalogSyncDispatcher: Site has changed, resetting the sync")
            stop()
        }

        guard !isRunning else { return }

        DDLogInfo("🔄 ForegroundPOSCatalogSyncDispatcher: Starting foreground sync dispatcher for site \(storeProvider.defaultStoreID ?? 0)")

        let activeObserver = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.startTimer()
            }
        }

        let backgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.stopTimer()
            }
        }

        let defaultSiteObserver = notificationCenter.addObserver(
            forName: .StoresManagerDidUpdateDefaultSite,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.stop()
            }
        }

        observers = [activeObserver, backgroundObserver, defaultSiteObserver]

        if await isAppActive() {
            startTimer()
        }

        syncSiteID = storeProvider.defaultStoreID
    }

    func stop() {
        guard isRunning else { return }

        DDLogInfo("🛑 ForegroundPOSCatalogSyncDispatcher: Stopping foreground sync dispatcher for site \(syncSiteID ?? 0)")
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
        stopTimer()
        syncSiteID = nil
    }

    private func startTimer() {
        guard timer == nil else { return }

        DDLogInfo("⏱️ ForegroundPOSCatalogSyncDispatcher: Starting timer (interval: \(Int(interval))s")

        let queue = DispatchQueue(label: "com.automattic.woocommerce.posCatalogForegroundSync.timer", qos: .utility)
        let timer = timerProvider.makeTimer(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .seconds(Constants.leeway))
        timer.setEventHandler { [weak self] in
            Task {
                await self?.performSync()
            }
        }
        timer.resume()
        self.timer = timer
    }

    private func stopTimer() {
        guard timer != nil else { return }
        DDLogInfo("⏱️ ForegroundPOSCatalogSyncDispatcher: Stopping timer")
        timer?.cancel()
        timer = nil
    }

    private func performSync() {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI) else {
            DDLogInfo("📋 ForegroundPOSCatalogSyncDispatcher: Feature flag disabled, skipping sync")
            stop()
            return
        }

        guard let siteID = storeProvider.defaultStoreID else {
            DDLogInfo("📋 ForegroundPOSCatalogSyncDispatcher: No default store, skipping sync")
            stop()
            return
        }

        guard let coordinator = storeProvider.posCatalogSyncCoordinator else {
            DDLogInfo("📋 ForegroundPOSCatalogSyncDispatcher: Coordinator unavailable, skipping sync")
            stop()
            return
        }

        DDLogInfo("🔄 ForegroundPOSCatalogSyncDispatcher: Starting sync for site \(siteID)")

        Task.detached(priority: .utility) {
            do {
                try await coordinator.performSmartSync(for: siteID, isBackgroundSync: false)
                DDLogInfo("✅ ForegroundPOSCatalogSyncDispatcher: Sync completed for site \(siteID)")
            } catch let error as POSCatalogSyncError {
                switch error {
                case .syncAlreadyInProgress:
                    DDLogInfo("ℹ️ ForegroundPOSCatalogSyncDispatcher: Sync already in progress for site \(siteID)")
                case .negativeMaxAge:
                    DDLogError("⛔️ ForegroundPOSCatalogSyncDispatcher: Invalid max age for site \(siteID)")
                case .invalidData:
                    DDLogError("⛔️ ForegroundPOSCatalogSyncDispatcher: Invalid data encountered during sync for site \(siteID)")
                case .timeout:
                    DDLogError("⛔️ ForegroundPOSCatalogSyncDispatcher: Sync timed out for site \(siteID)")
                case .generationFailed:
                    DDLogError("⛔️ ForegroundPOSCatalogSyncDispatcher: Sync generation failed for site \(siteID)")
                case .requestCancelled:
                    DDLogInfo("ℹ️ ForegroundPOSCatalogSyncDispatcher: Sync request was cancelled for site \(siteID)")
                case .shouldNotSync:
                    DDLogInfo("ℹ️ ForegroundPOSCatalogSyncDispatcher: Should not sync site \(siteID) at this time")
                }
            } catch {
                DDLogError("⛔️ ForegroundPOSCatalogSyncDispatcher: Sync failed for site \(siteID): \(error)")
            }
        }
    }
}

// MARK: - Helpers

/// Simplified protocol for dispatch source timers, only exposing methods actually used.
protocol DispatchTimerProtocol {
    func schedule(deadline: DispatchTime, repeating: Double, leeway: DispatchTimeInterval)
    func setEventHandler(handler: (() -> Void)?)
    func resume()
    func cancel()
}

extension DispatchSourceTimer {
    func asTimer() -> DispatchTimerProtocol {
        DispatchTimerWrapper(timer: self)
    }
}

private struct DispatchTimerWrapper: DispatchTimerProtocol {
    let timer: DispatchSourceTimer

    func schedule(deadline: DispatchTime, repeating: Double, leeway: DispatchTimeInterval) {
        timer.schedule(deadline: deadline, repeating: repeating, leeway: leeway)
    }

    func setEventHandler(handler: (() -> Void)?) {
        timer.setEventHandler(handler: handler)
    }

    func resume() {
        timer.resume()
    }

    func cancel() {
        timer.cancel()
    }
}

/// Protocol for creating dispatch timers, enabling testability.
protocol DispatchTimerProviding {
    func makeTimer(queue: DispatchQueue) -> DispatchTimerProtocol
}

/// Default implementation using system DispatchSource.
struct DefaultDispatchTimerProvider: DispatchTimerProviding {
    func makeTimer(queue: DispatchQueue) -> DispatchTimerProtocol {
        DispatchSource.makeTimerSource(queue: queue).asTimer()
    }
}

extension UIApplication {
    static func isApplicationActive() async -> Bool {
        shared.applicationState == .active
    }
}

/// Protocol for accessing store ID and POS catalog sync coordinator.
protocol POSCatalogStoreProviding {
    var defaultStoreID: Int64? { get }
    var posCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? { get }
}

/// Default implementation using StoresManager.
struct DefaultPOSCatalogStoreProvider: POSCatalogStoreProviding {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    var defaultStoreID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    var posCatalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? {
        stores.posCatalogSyncCoordinator
    }
}
