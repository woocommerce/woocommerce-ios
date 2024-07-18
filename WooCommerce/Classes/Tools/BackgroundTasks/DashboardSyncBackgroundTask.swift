import BackgroundTasks
import Foundation
import Yosemite

/// Task to sync dashboard card data in the background.
///
struct DashboardSyncBackgroundTask {

    let siteID: Int64

    let siteTimezone: TimeZone

    let stores: StoresManager

    let backgroundTask: BGAppRefreshTask?

    init(siteID: Int64, siteTimezone: TimeZone = .siteTimezone, backgroundTask: BGAppRefreshTask?, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        self.backgroundTask = backgroundTask
        self.stores = stores
    }

    /// Runs the sync task.
    /// Marks the `backgroundTask` as completed when finished.
    /// Returns a `task` to be canceled when required.
    ///
    func dispatch() -> Task<Void, Never> {
        Task { @MainActor in
            do {
                DDLogInfo("📱 Synchronizing dashboard cards in the background...")

                let dashboardCards = await loadDashboardCardsFromStorage()
                for card in dashboardCards {

                    switch card.type {
                    case .performance:

                        DDLogInfo("📱 Synchronizing Performance card in the background...")
                        let useCase = PerformanceCardDataSyncUseCase(siteID: siteID, siteTimezone: siteTimezone)
                        try await useCase.sync()
                        DDLogInfo("📱 Successfully synchronized \(card.type.name) in the background")
                        backgroundTask?.setTaskCompleted(success: true)

                    case .blaze, .coupons, .googleAds, .inbox, .lastOrders, .onboarding, .reviews, .stock, .topPerformers:
                        DDLogInfo("⚠️ Synchronizing \(card.type.name) card in the background is not yet supported...")
                        return
                    }
                }
            } catch {
                DDLogError("⛔️ Error synchronizing dashboard cards in the background: \(error)")
                backgroundTask?.setTaskCompleted(success: false)
            }
        }
    }

    /// Load the supposed visible cards from storage.
    ///
    @MainActor
    private func loadDashboardCardsFromStorage() async -> [DashboardCard] {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadDashboardCards(siteID: siteID, onCompletion: { cards in
                let visibleCards = cards?.filter { $0.enabled && $0.availability == .show }
                continuation.resume(returning: visibleCards ?? [])
            }))
        }
    }
}
