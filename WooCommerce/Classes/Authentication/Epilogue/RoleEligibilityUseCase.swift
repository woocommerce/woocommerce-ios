import Yosemite

protocol RoleEligibilityUseCaseProtocol {
    func checkEligibility(for storeID: Int64, completion: @escaping (RoleEligibilityError?) -> Void)
}

/// Encapsulates the logic for checking the eligibility of user roles.
///
final class RoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {

    private let stores: StoresManager

    init(stores: StoresManager) {
        self.stores = stores
    }

    /// Checks whether the current authenticated session has the correct role to manage the store.
    /// Any error returned from the block means that the user is not eligible.
    ///
    /// - Parameters:
    ///   - storeID: The dotcom site ID of the store.
    ///   - completion: The block to be called when the check completes, with an optional RoleEligibilityError.
    ///
    func checkEligibility(for storeID: Int64, completion: @escaping (RoleEligibilityError?) -> Void) {
        guard stores.isAuthenticated else {
            // TODO: (dvdchr) It's not expected to enter this path. Maybe log something here?
            completion(RoleEligibilityError.notAuthenticated)
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { result in
            switch result {
            case .success(let user):
                let isEligible = self.isEligible(with: user.roles)

                // TODO: (dvdchr) persist state in user defaults.

                guard isEligible else {
                    // Report back with the display information for the error page.
                    completion(RoleEligibilityError.insufficientRole(name: user.nickname, roles: user.roles))
                    return
                }

                // The user is eligible to manage the store.
                completion(nil)

            case .failure(let error):
                completion(RoleEligibilityError.unknown(error: error))
            }
        }
        stores.dispatch(action)
    }
}

/// Convenient error class that helps with categorizing errors related to role eligibility checks.
enum RoleEligibilityError: Error {
    /// The user's role is insufficient to manage the store.
    /// Additional information is provided for the error page to display more information.
    case insufficientRole(name: String, roles: [String])

    /// The user has not yet authenticated with the app.
    /// This should not happen, and may indicate an implementation error.
    case notAuthenticated

    /// Errors caused from other sources.
    case unknown(error: Error)
}

// MARK: - Private Methods

private extension RoleEligibilityUseCase {
    /// This method does a simple match to check if the provided `roles` contain *any* role defined in
    /// EligibleRole. `roles` from the parameter are lowercased just in case.
    func isEligible(with roles: [String]) -> Bool {
        return roles.firstIndex { EligibleRole.allRoles.contains($0.lowercased()) } != nil
    }
}

// MARK: - Private Types

private enum EligibleRole: String, CaseIterable {
    case administrator
    case shopManager = "shop_manager"

    /// Convenience method that returns the collection in raw value instead of in enum type.
    static var allRoles: [String] = {
        allCases.map { $0.rawValue }
    }()
}
