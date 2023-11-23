import Foundation
import Storage
import Networking

struct MockSystemStatusActionHandler: MockActionHandler {
    typealias ActionType = SystemStatusAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .synchronizeSystemInformation(let siteID, let onCompletion):
            synchronizeSystemPlugins(siteID: siteID) { result in
                onCompletion(result.map { SystemInformation(systemPlugins: $0) })
            }
        default:
            break
        }
    }

    private func synchronizeSystemPlugins(siteID: Int64, onCompletion: @escaping (Result<[SystemPlugin], Error>) -> Void) {
        let systemPlugins = objectGraph.systemPlugins(for: siteID)

        save(mocks: systemPlugins, as: StorageSystemPlugin.self) { error in
            if let error = error {
                onCompletion(.failure(error))
            } else {
                onCompletion(.success([]))
            }
        }
    }
}
