import Yosemite

protocol RoleEligibilityUseCaseProtocol {
    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Bool, Error>) -> Void)
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
    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Bool, RoleEligibilityError>) -> Void) {
        guard stores.isAuthenticated else {
            completion(.failure(RoleEligibilityError.notAuthenticated))
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { result in
            switch result {
            case .success(let user):
                guard self.isEligible(with: user.roles) else {
                    // report back with the display information for the error page.
                    completion(.failure(RoleEligibilityError.insufficientRole(displayName: user.nickname, roles: user.roles)))
                    return
                }
                completion(.success(true))

            case .failure(let error):
                completion(.failure(RoleEligibilityError.unknown(error: error)))

            default:
                print("This should not happen")
            }
        }
        stores.dispatch(action)
    }

}

enum RoleEligibilityError: Error {
    /// The user's role is insufficient to manage the store.
    /// Additional information is provided for the error page to display more information.
    case insufficientRole(displayName: String, roles: [String])

    /// The user has not yet authenticated with the app.
    /// This should not happen, and may indicate an implementation error.
    case notAuthenticated

    /// Errors caused from other sources.
    case unknown(error: Error)
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
