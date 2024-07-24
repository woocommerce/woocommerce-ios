import Foundation
import Yosemite

/// Task to sync orders in the background
///
struct OrderListSyncBackgroundTask {

    /// The last time we successfully run a sync update.
    ///
    static var latestSyncDate: Date {
        get {
            return UserDefaults.standard[.latestBackgroundOrderSyncDate] as? Date ?? Date.distantPast
        }
        set {
            return UserDefaults.standard[.latestBackgroundOrderSyncDate] = newValue
        }
    }

    let siteID: Int64

    let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Runs the sync task.
    ///
    @MainActor
    func dispatch() async throws {
        do {
            DDLogInfo("📱 Synchronizing orders in the background...")

            let useCase = CurrentOrderListSyncUseCase(siteID: siteID, stores: stores)
            try await useCase.sync()
            Self.latestSyncDate = Date.now

            DDLogInfo("📱 Successfully synchronized orders in the background")
        } catch {
            DDLogError("⛔️ Error synchronizing orders in the background: \(error)")
            throw error
        }
    }
}

/// UseCase to sync the order list with the current store filters.
///
private struct CurrentOrderListSyncUseCase {

    let siteID: Int64

    let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Syncs the order list with the current store filters.
    ///
    func sync() async throws {
        let filters = await fetchFilters()
        try await syncOrders(filters: filters)
    }

    /// Fetch the stored filters settings.
    /// Needed to request the correct type of orders.
    ///
    @MainActor
    private func fetchFilters() async -> FilterOrderListViewModel.Filters {
        return await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadOrdersSettings(siteID: siteID) { (result) in
                switch result {
                case .success(let settings):
                    let filters = FilterOrderListViewModel.Filters(orderStatus: settings.orderStatusesFilter,
                                                                   dateRange: settings.dateRangeFilter,
                                                                   product: settings.productFilter,
                                                                   customer: settings.customerFilter,
                                                                   numberOfActiveFilters: settings.numberOfActiveFilters())
                    continuation.resume(returning: filters)
                case .failure:
                    continuation.resume(returning: .init()) // No filters found
                }
            }
            stores.dispatch(action)
        }
    }

    /// Syncs(fetch and stores) the latest orders for a given site and filters.
    ///
    @MainActor
    private func syncOrders(filters: FilterOrderListViewModel.Filters) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let useCase = OrderListSyncActionUseCase(siteID: siteID, filters: filters)
            let action = useCase.actionFor(pageNumber: SyncingCoordinator.Defaults.pageFirstIndex,
                                           pageSize: SyncingCoordinator.Defaults.pageSize,
                                           reason: .backgroundFetch,
                                           lastFullSyncTimestamp: OrderListSyncBackgroundTask.latestSyncDate,
                                           completionHandler: { timeInterval, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
            stores.dispatch(action)
        }
    }
}
