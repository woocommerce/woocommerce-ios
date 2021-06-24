import Yosemite

protocol RoleEligibilityUseCaseProtocol {
    func checkEligibility(for storeID: Int64, completion: @escaping (Bool) -> Void)
}

/// Encapsulates the logic for checking the eligibility of user roles.
///
final class RoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {

    private let stores: StoresManager

    init(stores: StoresManager) {
        self.stores = stores
    }

    /// Checks whether the current authenticated session has the correct role to manage the store.
    /// - Parameters:
    ///   - storeID: The dotcom site ID of the store.
    ///   - completion: The block to be called when the check completes. The boolean argument contains true if the user has the proper role to manage the store.
    ///
    func checkEligibility(for storeID: Int64, completion: @escaping (Bool) -> Void) {
        guard stores.isAuthenticated else {
            completion(false)
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { result in
            switch result {
            case .success(let user):
                let isEligible = self.isEligible(with: user.roles)
                // TODO: David - persist result in user defaults.
                completion(isEligible)

            case .failure:
                completion(false)
            }
        }
        stores.dispatch(action)
    }

}

// MARK: - Private methods

private extension RoleEligibilityUseCase {

    /// This method does a simple match to check if the provided `roles` contain *any* role defined in
    /// EligibleRole. `roles` from the parameter are lowercased just in case :)
    ///
    func isEligible(with roles: [String]) -> Bool {
        return roles.firstIndex { EligibleRole.allRoles.contains($0.lowercased()) } != nil
    }

}

// MARK: - Constants

private enum EligibleRole: String, CaseIterable {
    case administrator
    case shopManager = "shop_manager"

    /// Convenience method that returns the collection in raw value instead of in enum type.
    static var allRoles: [String] = {
        allCases.map { $0.rawValue }
    }()
}
