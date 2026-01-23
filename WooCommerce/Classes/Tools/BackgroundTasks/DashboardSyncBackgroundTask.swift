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
                case .topPerformers:
                    group.addTask { try await topPerformersTask() }
                case .blaze, .coupons, .googleAds, .inbox, .lastOrders, .onboarding, .reviews, .stock:
                    DDLogInfo("⚠️ Synchronizing \(card.type.name) card in the background is not yet supported...")
                    return
                case .inAppFeedback, .shareStore, .newCardsNotice, .connectWPCom:
                    // no syncing needed
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

    /// Run the performance card update task.
    ///
    @MainActor
    private func performanceTask() async throws {
        do {
            DDLogInfo("📱 Synchronizing Performance card in the background...")
            let useCase = PerformanceCardDataSyncUseCase(siteID: siteID, siteTimezone: siteTimezone, stores: stores)
            try await useCase.sync()
            DDLogInfo("📱 Successfully synchronized Performance card in the background")
        } catch {
            DDLogError("⛔️ Error synchronizing Performance card in the background: \(error)")
            throw error
        }
    }

    /// Run the top performers card update task.
    ///
    @MainActor
    private func topPerformersTask() async throws {
        do {
            DDLogInfo("📱 Synchronizing Top Performers card in the background...")
            let useCase = TopPerformersCardDataSyncUseCase(siteID: siteID, siteTimezone: siteTimezone, stores: stores)
            try await useCase.sync()
            DDLogInfo("📱 Successfully synchronized Top Performers card in the background")
        } catch {
            DDLogError("⛔️ Error synchronizing Top Performers card in the background: \(error)")
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
