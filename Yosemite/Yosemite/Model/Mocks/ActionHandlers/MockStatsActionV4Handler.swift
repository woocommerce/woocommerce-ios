import Foundation
import Storage
import Networking

struct MockStatsActionV4Handler: MockActionHandler {
    typealias ActionType = StatsActionV4

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveStats(let siteID, let timeRange, _, _, _, let onCompletion):
                retrieveStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            case .retrieveSiteVisitStats(let siteID, _, let timeRange, _, let onCompletion):
                retrieveSiteVisitStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            case .retrieveTopEarnerStats(let siteID, let timeRange, _, _, let onCompletion):
                retrieveTopEarnerStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            default: unimplementedAction(action: action)
        }
    }

    func retrieveStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Error?) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
            case .today:
                success(onCompletion)
            case .thisWeek:
                success(onCompletion)
            case .thisMonth:
                success(onCompletion)
            case .thisYear:
                store.upsertStoredOrderStats(readOnlyStats: objectGraph.thisYearOrderStats, timeRange: timeRange)
                onCompletion(nil)
        }
    }

    func retrieveSiteVisitStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Error?) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
            case .today:
                success(onCompletion)
            case .thisWeek:
                success(onCompletion)
            case .thisMonth:
                success(onCompletion)
            case .thisYear:
                store.upsertStoredSiteVisitStats(readOnlyStats: objectGraph.thisYearVisitStats)
                onCompletion(nil)
        }
    }

    func retrieveTopEarnerStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Error?) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
            case .today:
                success(onCompletion)
            case .thisWeek:
                success(onCompletion)
            case .thisMonth:
                success(onCompletion)
            case .thisYear:
                store.upsertStoredTopEarnerStats(readOnlyStats: objectGraph.thisYearTopProducts)
                onCompletion(nil)
        }
    }
}
