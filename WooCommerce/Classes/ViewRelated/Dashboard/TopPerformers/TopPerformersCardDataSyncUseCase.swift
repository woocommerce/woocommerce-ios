import Foundation
import Yosemite

/// Abstracts the code needed to sync the information for the Dashboard performance card.
///
struct TopPerformersCardDataSyncUseCase {

    static let topEarnerStatsLimit: Int = 5

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

        try await syncTopPerformersStats(timeRange: timeRange)
    }

    /// Loads the last selected time range in any. If there isn't any returns the `.today` range.
    ///
    @MainActor
    private func loadLastTimeRange() async -> StatsTimeRangeV4 {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedTopPerformersTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange ?? .today)
            }
            stores.dispatch(action)
        }
    }

    /// Syncs top performance stats for a given time range.
    ///
    @MainActor
    func syncTopPerformersStats(timeRange: StatsTimeRangeV4) async throws {
        let currentDate = Date()
        let latestDateToInclude = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                                 timeRange: timeRange,
                                                                 timeZone: siteTimezone,
                                                                 earliestDateToInclude: earliestDateToInclude,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 quantity: Self.topEarnerStatsLimit,
                                                                 forceRefresh: true,
                                                                 saveInStorage: true,
                                                                 onCompletion: { result in
                let voidResult = result.map { _ in () } // Caller expects no entity in the result.
                continuation.resume(with: voidResult)
            }))
        }

        DashboardTimestampStore.saveTimestamp(.now, for: .topPerformers, at: timeRange.timestampRange)
    }
}
