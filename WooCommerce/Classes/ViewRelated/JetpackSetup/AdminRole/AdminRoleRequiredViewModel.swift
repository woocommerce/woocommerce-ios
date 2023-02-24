import Foundation
import Yosemite

/// View model for `AdminRoleRequiredView`
///
final class AdminRoleRequiredViewModel {
    let username: String
    let roleName: String

    private let siteID: Int64

    private let stores: StoresManager
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.username = stores.sessionManager.defaultCredentials?.username ?? ""
        self.roleName = stores.sessionManager.defaultRoles
            .map { $0.displayString() }
            .joined(separator: ", ")
    }

    @MainActor
    func reloadRoles() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let action = UserAction.retrieveUser(siteID: siteID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    let roles = user.roles.compactMap { User.Role(rawValue: $0) }
                    self.stores.updateDefaultRoles(roles)
                    if roles.contains(.administrator) {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }
}
