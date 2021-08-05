import Yosemite

/// Encapsulates the logic for checking the eligibility of user roles.
protocol RoleEligibilityUseCaseProtocol {
    /// Checks whether the current authenticated session has the correct role to manage the store.
    /// Any error returned from the block means that the user is not eligible.
    ///
    /// - Parameters:
    ///   - storeID: The dotcom site ID of the store.
    ///   - completion: The block to be called when the check completes, with an optional RoleEligibilityError.
    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void)
}

/// This component checks user's eligibility to access/manage the store, It saves the eligibility error data when the user has insufficient role
/// and populates the session manager with the role information for the default store.
/// Currently, user eligibility check is performed from:
///     1. The store picker screen, when the user tapped "Continue".
///     2. App launch, to check if the current user is still eligible to access the store.
///
final class RoleEligibilityUseCase {
    // MARK: Properties

    private let stores: StoresManager

    // MARK: Initialization

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    // MARK: Private Methods

    /// Saves `EligibilityErrorInfo` locally.
    ///
    private func saveErrorInfo(_ errorInfo: StorageEligibilityErrorInfo) {
        let action = AppSettingsAction.setEligibilityErrorInfo(errorInfo: errorInfo) { _ in }
        stores.dispatch(action)
    }

    /// Clears any existing `EligibilityErrorInfo` from local storage.
    ///
    private func resetErrorInfo() {
        let action = AppSettingsAction.resetEligibilityErrorInfo
        stores.dispatch(action)
    }
}

// MARK: - Protocol Implementation

extension RoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {
    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void) {
        guard stores.isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }

        // handle edge case to prevent extra, unnecessary request.
        guard storeID > 0 else {
            completion(.failure(.invalidStoreId(id: storeID)))
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                let roles = user.roles.compactMap { User.Role(rawValue: $0) }
                self.stores.updateDefaultRoles(roles)

                guard user.hasEligibleRoles() else {
                    let errorInfo = StorageEligibilityErrorInfo(name: user.displayName(), roles: user.roles)

                    // Remember the error info if the user is ineligible to access the *current* store.
                    // This will be used on future app launches.
                    if let defaultStoreID = self.stores.sessionManager.defaultStoreID, defaultStoreID == storeID {
                        self.saveErrorInfo(errorInfo)
                    }

                    // report back with the display information for the error page.
                    completion(.failure(.insufficientRole(info: errorInfo)))
                    break
                }

                // When user is eligible, always clear any existing error info.
                self.resetErrorInfo()
                completion(.success(()))

            case .failure(let error):
                completion(.failure(.unknown(error: error)))
            }
        }
        stores.dispatch(action)
    }
}

/// Convenient error class that helps with categorizing errors related to role eligibility checks.
enum RoleEligibilityError: Error {
    /// The user's role is insufficient to manage the store.
    /// Additional information is provided for the error page to display more information.
    case insufficientRole(info: StorageEligibilityErrorInfo)

    /// The user has not yet authenticated with the app.
    /// This should not happen, and may indicate an implementation error.
    case notAuthenticated

    /// Submitted store ID is most likely invalid.
    /// This should not happen, and may indicate an implementation error.
    case invalidStoreId(id: Int64)

    /// An unknown error caused from other sources.
    case unknown(error: Error)
}
