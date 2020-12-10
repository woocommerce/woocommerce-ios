import Foundation
import Storage

struct MockStatsActionV4Handler: MockActionHandler {
    typealias ActionType = StatsActionV4

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .retrieveStats(_, _, _, _, _, let onCompletion):
                success(onCompletion)
            case .retrieveSiteVisitStats(_, _, _, _, let onCompletion):
                success(onCompletion)
            case .retrieveTopEarnerStats(_, _, _, _, let onCompletion):
                success(onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}
