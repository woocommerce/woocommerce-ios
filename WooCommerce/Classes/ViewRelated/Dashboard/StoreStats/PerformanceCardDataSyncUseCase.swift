import Foundation
import Yosemite

/// Abstracts the code needed to sync the information for the Dashboard performance card.
///
struct PerformanceCardDataSyncUseCase {

    let siteID: Int64
    let siteTimezone: TimeZone
    let timeRange: StatsTimeRangeV4?
    let stores: StoresManager

    /// The provided `timeRange` will be used. If non is provided, the last used one(stored in settings) will be used.
    ///
    init(siteID: Int64, siteTimezone: TimeZone, timeRange: StatsTimeRangeV4? = nil, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.siteTimezone = siteTimezone
        self.timeRange = timeRange
        self.stores = stores
    }

    /// Sync all stats needed for the performance card.
    ///
    @MainActor
    func sync() async throws {
        let timeRange = await {
            guard let initialTimeRange = self.timeRange else {
                return await loadLastTimeRange()
            }
            return initialTimeRange
        }()

        try await syncAllStats(timeRange: timeRange)
    }

    /// Loads the last selected time range in any. If there isn't any returns the `.today` range.
    ///
    @MainActor
    private func loadLastTimeRange() async -> StatsTimeRangeV4 {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedPerformanceTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange ?? .today)
            }
            stores.dispatch(action)
        }
    }

    /// Orchestrate all networks request needed for the performance card.
    ///
    @MainActor
    private func syncAllStats(timeRange: StatsTimeRangeV4) async throws {
        let currentDate = Date()
        let latestDateToInclude = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.syncStats(timeRange: timeRange, latestDateToInclude: latestDateToInclude)
            }

            group.addTask {
                try await self.syncSiteVisitStats(timeRange: timeRange, latestDateToInclude: latestDateToInclude)
            }

            group.addTask {
                try await self.syncSiteSummaryStats(timeRange: timeRange, latestDateToInclude: latestDateToInclude)
            }

            // rethrow any failure.
            for try await _ in group {
                // no-op if result doesn't throw any error
            }
        }

        DashboardTimestampStore.saveTimestamp(.now, for: .performance, at: timeRange.timestampRange)
    }

    /// Syncs store stats for dashboard UI.
    @MainActor
    func syncStats(timeRange: StatsTimeRangeV4, latestDateToInclude: Date) async throws {
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveStats(siteID: siteID,
                                                        timeRange: timeRange,
                                                        timeZone: siteTimezone,
                                                        earliestDateToInclude: earliestDateToInclude,
                                                        latestDateToInclude: latestDateToInclude,
                                                        quantity: timeRange.maxNumberOfIntervals,
                                                        forceRefresh: true,
                                                        onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    /// Syncs visitor stats for dashboard UI.
    @MainActor
    func syncSiteVisitStats(timeRange: StatsTimeRangeV4, latestDateToInclude: Date) async throws {
        guard stores.isAuthenticatedWithoutWPCom == false else { // Visit stats are only available for stores connected to WPCom
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                                 siteTimezone: siteTimezone,
                                                                 timeRange: timeRange,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 onCompletion: { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                }
                continuation.resume(with: result)
            }))
        }
    }

    /// Syncs summary stats for dashboard UI.
    @MainActor
    func syncSiteSummaryStats(timeRange: StatsTimeRangeV4, latestDateToInclude: Date) async throws {
        guard stores.isAuthenticatedWithoutWPCom == false else { // Summary stats are only available for stores connected to WPCom
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveSiteSummaryStats(siteID: siteID,
                                                                   siteTimezone: siteTimezone,
                                                                   period: timeRange.summaryStatsGranularity,
                                                                   quantity: 1,
                                                                   latestDateToInclude: latestDateToInclude,
                                                                   saveInStorage: true) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing summary stats: \(error)")
                }

                let voidResult = result.map { _ in () } // Caller expects no entity in the result.
                continuation.resume(with: voidResult)
            })
        }
    }
}
