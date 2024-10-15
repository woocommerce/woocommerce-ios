import Foundation
import Storage
import Networking

struct MockStatsActionV4Handler: MockActionHandler {
    typealias ActionType = StatsActionV4

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveStats(let siteID, let timeRange, _, _, _, _, _, let onCompletion):
                retrieveStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            case .retrieveSiteVisitStats(let siteID, _, let timeRange, _, let onCompletion):
                retrieveSiteVisitStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            case .retrieveTopEarnerStats(let siteID, let timeRange, _, _, _, _, _, _, let onCompletion):
                retrieveTopEarnerStats(siteID: siteID, timeRange: timeRange, onCompletion: onCompletion)
            default: unimplementedAction(action: action)
        }
    }

    func retrieveStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
            case .today:
                success(onCompletion)
            case .thisWeek:
                success(onCompletion)
            case .thisMonth:
            store.upsertStoredOrderStats(readOnlyStats: objectGraph.thisMonthOrderStats, timeRange: timeRange) {
                onCompletion(.success(()))
            }
            case .thisYear:
                success(onCompletion)
            case .custom:
                success(onCompletion)
        }
    }

    func retrieveSiteVisitStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Result<Void, Error>) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
            case .today:
                success(onCompletion)
            case .thisWeek:
                success(onCompletion)
            case .thisMonth:
            store.upsertStoredSiteVisitStats(readOnlyStats: objectGraph.thisMonthVisitStats, timeRange: timeRange) {
                onCompletion(.success(()))
            }
            case .thisYear:
                success(onCompletion)
            case .custom:
                success(onCompletion)
        }
    }

    func retrieveTopEarnerStats(siteID: Int64, timeRange: StatsTimeRangeV4, onCompletion: @escaping (Result<TopEarnerStats, Error>) -> ()) {
        let store = StatsStoreV4(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())

        switch timeRange {
        case .today:
            onCompletion(.success(objectGraph.thisMonthTopProducts))
        case .thisWeek:
            onCompletion(.success(objectGraph.thisMonthTopProducts))
        case .thisMonth:
            store.upsertStoredTopEarnerStats(readOnlyStats: objectGraph.thisMonthTopProducts) {
                onCompletion(.success(objectGraph.thisMonthTopProducts))
            }
        case .thisYear:
            onCompletion(.success(objectGraph.thisMonthTopProducts))
        case .custom:
            onCompletion(.success(objectGraph.thisMonthTopProducts))
        }
    }
}
