import Foundation
import Storage

struct MockAppSettingsActionHandler: MockActionHandler {
    typealias ActionType = AppSettingsAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .loadInitialStatsVersionToShow(let siteId, let onCompletion):
                loadInitialStatsVersionToShow(siteId: siteId, onCompletion: onCompletion)
            case .setStatsVersionLastShown(let siteId, let statsVersion):
                setStatsVersionLastShown(siteId: siteId, statsVersion: statsVersion)
            case .loadFeedbackVisibility(let type, let onCompletion):
                loadFeedbackVisibility(type: type, onCompletion: onCompletion)
            case .setInstallationDateIfNecessary(let date, let onCompletion):
                setInstallationDateIfNecessary(date: date, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func loadInitialStatsVersionToShow(siteId: Int64, onCompletion: (StatsVersion?) -> Void) {
        onCompletion(.v4)
    }

    func setStatsVersionLastShown(siteId: Int64, statsVersion: StatsVersion) {
        // TODO – we should persist this somewhere
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }

    func setInstallationDateIfNecessary(date: Date, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }
}
