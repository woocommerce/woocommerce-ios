import Foundation
import Storage

struct MockUserActionHandler: MockActionHandler {
    typealias ActionType = UserAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case .retrieveUser(let siteID, let onCompletion):
            onCompletion(.success(User(localID: 0,
                                       siteID: siteID,
                                       wpcomID: 0,
                                       email: "",
                                       username: "",
                                       firstName: "",
                                       lastName: "",
                                       nickname: "",
                                       roles: [User.Role.administrator.rawValue])))
        }
    }
}
