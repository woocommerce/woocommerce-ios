import Foundation
import Storage

struct MockShippingMethodActionHandler: MockActionHandler {

    typealias ActionType = ShippingMethodAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .synchronizeShippingMethods(_, let completion):
            completion(.success(()))
        }
    }
}
