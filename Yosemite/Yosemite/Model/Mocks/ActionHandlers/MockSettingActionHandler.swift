import Foundation
import Storage
import Networking

struct MockSettingActionHandler: MockActionHandler {
    typealias ActionType = SettingAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    private let settingStore: SettingStore

    init(objectGraph: MockObjectGraph, storageManager: StorageManagerType) {
        self.objectGraph = objectGraph
        self.storageManager = storageManager

        settingStore = SettingStore(dispatcher: Dispatcher(), storageManager: storageManager, network: NullNetwork())
    }

    func handle(action: ActionType) {
        switch action {
        case .retrieveSiteAPI(let siteID, let onCompletion):
            retrieveSiteAPI(siteId: siteID, onCompletion: onCompletion)
        case .synchronizeGeneralSiteSettings(let siteID, let onCompletion):
            synchronizeGeneralSiteSettings(siteID: siteID, onCompletion: onCompletion)

        default: unimplementedAction(action: action)
        }
    }

    func retrieveSiteAPI(siteId: Int64, onCompletion: (Result<SiteAPI, Error>) -> Void) {
        onCompletion(.success(objectGraph.defaultSiteAPI))
    }

    func synchronizeGeneralSiteSettings(siteID: Int64, onCompletion: @escaping (Error?) -> Void) {
        let settings = objectGraph.siteSettings(for: siteID)
        save(mocks: settings, as: StorageSiteSetting.self, onCompletion: onCompletion)
    }
}
