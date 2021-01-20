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
            case .setStatsVersionLastShown:
                // This case needs to be handled to avoid crashing when running screenshots
                // Once the enum is removed, this can be as well.
                success()
            case .loadFeedbackVisibility(let type, let onCompletion):
                loadFeedbackVisibility(type: type, onCompletion: onCompletion)
            case .setInstallationDateIfNecessary(let date, let onCompletion):
                setInstallationDateIfNecessary(date: date, onCompletion: onCompletion)
            case .loadProductsSettings(let siteId, let onCompletion):
                loadProductSettings(siteId: siteId, onCompletion: onCompletion)
            default: unimplementedAction(action: action)
        }
    }

    func loadInitialStatsVersionToShow(siteId: Int64, onCompletion: (StatsVersion?) -> Void) {
        onCompletion(.v4)
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }

    func setInstallationDateIfNecessary(date: Date, onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(true))
    }

    func loadProductSettings(siteId: Int64, onCompletion: (Result<StoredProductSettings.Setting, Error>) -> Void) {
        let emptySetting = StoredProductSettings.Setting(siteID: siteId, sort: nil, stockStatusFilter: nil, productStatusFilter: nil, productTypeFilter: nil)
        onCompletion(.success(emptySetting))
    }
}
