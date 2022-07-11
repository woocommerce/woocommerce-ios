import Foundation
import Storage
import Networking

struct MockSystemStatusActionHandler: MockActionHandler {
    typealias ActionType = SystemStatusAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .synchronizeSystemPlugins(let siteID, let onCompletion):
            synchronizeSystemPlugins(siteID: siteID, onCompletion: onCompletion)
        default:
            break
        }
    }

    private func synchronizeSystemPlugins(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let systemPlugins = objectGraph.systemPlugins(for: siteID)

        save(mocks: systemPlugins, as: StorageSystemPlugin.self) { error in
            if let error = error {
                onCompletion(.failure(error))
            } else {
                onCompletion(.success(()))
            }
        }
    }
}
