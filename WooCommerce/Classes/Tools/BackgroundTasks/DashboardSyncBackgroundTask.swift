import BackgroundTasks
import Foundation
import Yosemite

/// Task to sync dashboard card data in the background.
///
struct DashboardSyncBackgroundTask {

    let siteID: Int64

    let siteTimezone: TimeZone

    let stores: StoresManager

    init(siteID: Int64, siteTimezone: TimeZone = .siteTimezone, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        self.stores = stores
    }

    /// Runs the sync task.
    ///
    @MainActor
    func dispatch() async throws {
        DDLogInfo("📱 Synchronizing dashboard cards in the background...")
        let dashboardCards = await loadDashboardCardsFromStorage()

        try await withThrowingTaskGroup(of: Void.self) { group in

            for card in dashboardCards {

                switch card.type {
                case .performance:
                    group.addTask { try await performanceTask() }

                case .blaze, .coupons, .googleAds, .inbox, .lastOrders, .onboarding, .reviews, .stock, .topPerformers:
                    DDLogInfo("⚠️ Synchronizing \(card.type.name) card in the background is not yet supported...")
                    return
                }
            }

            // Rethrows any failure.
            for try await _ in group {
                // No-op
            }
        }

        DDLogInfo("📱 Finished synchronizing dashboard cards in the background...")
    }

    /// Load the supposed visible cards from storage.
    ///
    @MainActor
    private func performanceTask() async throws {
        do {
            DDLogInfo("📱 Synchronizing Performance card in the background...")
            let useCase = PerformanceCardDataSyncUseCase(siteID: siteID, siteTimezone: siteTimezone)
            try await useCase.sync()
            DDLogInfo("📱 Successfully synchronized Performance card in the background")
        } catch {
            DDLogError("⛔️ Error synchronizing Performance card in the background: \(error)")
            throw error
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
