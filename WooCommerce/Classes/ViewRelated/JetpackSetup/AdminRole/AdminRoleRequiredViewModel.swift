import Foundation
import Yosemite

/// View model for `AdminRoleRequiredView`
///
final class AdminRoleRequiredViewModel {
    let username: String
    let roleName: String

    private let stores: StoresManager
    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.username = stores.sessionManager.defaultCredentials?.username ?? ""
        self.roleName = stores.sessionManager.defaultRoles
            .map { $0.displayString() }
            .joined(separator: ", ")
    }

    func reloadRoles() {
        // TODO
    }
}
