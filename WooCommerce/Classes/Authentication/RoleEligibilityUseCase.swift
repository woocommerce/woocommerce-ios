import Yosemite

/// Encapsulates the logic for checking the eligibility of user roles.
protocol RoleEligibilityUseCaseProtocol {
    /// Synchronize the latest eligibility status for an authenticated user with selected store ID.
    func syncEligibilityStatusIfNeeded()

    /// Checks whether the current authenticated session has the correct role to manage the store.
    /// Any error returned from the block means that the user is not eligible.
    ///
    /// - Parameters:
    ///   - storeID: The dotcom site ID of the store.
    ///   - completion: The block to be called when the check completes, with an optional RoleEligibilityError.
    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void)

    /// Returns the last error information encountered by the authenticated user.
    func lastEligibilityErrorInfo() -> EligibilityErrorInfo?
}


/// This component checks user's eligibility to access/manage the store, and *only* saves the data when the user has insufficient role.
/// Currently, user eligibility check is performed from:
///     1. The store picker screen, when the user tapped "Continue".
///     2. App launch, to check if the current user is still eligible to access the store.
///
final class RoleEligibilityUseCase {
    // MARK: Properties

    private let stores: StoresManager

    private let defaults: UserDefaults

    /// The last eligibility error info encountered by the user.
    private var lastErrorInfo: EligibilityErrorInfo? {
        get {
            loadLastErrorInfo()
        }
        set {
            defaults.setValue(newValue?.toDictionary(), forKey: Constants.eligibilityErrorInfoKey)
        }
    }

    // MARK: Initialization

    init(stores: StoresManager = ServiceLocator.stores, defaults: UserDefaults = UserDefaults.standard) {
        self.stores = stores
        self.defaults = defaults
        self.lastErrorInfo = loadLastErrorInfo()
    }
}

// MARK: - Protocol Implementation

extension RoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {
    func syncEligibilityStatusIfNeeded() {
        guard stores.isAuthenticated, let storeID = stores.sessionManager.defaultStoreID else {
            return
        }

        checkEligibility(for: storeID) { result in
            // We only care when an error occurs during sync. if the request is successful, then do nothing.
            switch result {
            case .failure(let error):
                // For errors other than `insufficientRole` (e.g. network errors), do nothing for now.
                // In case of network errors, it's best to depend on currently available information.
                // i.e., if the user is previously ineligible, then assume they are still ineligible now.
                guard case let .insufficientRole(errorInfo) = error else {
                    break
                }
                // store the information locally.
                self.lastErrorInfo = errorInfo

            default:
                break
            }
        }
    }

    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void) {
        guard stores.isAuthenticated else {
            // TODO: It's not expected to enter this path. Maybe log something here?
            completion(.failure(.notAuthenticated))
            return
        }

        // handle edge case to prevent extra, unnecessary request.
        guard storeID > 0 else {
            completion(.failure(.invalidStoreId(id: storeID)))
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { result in
            switch result {
            case .success(let user):
                guard user.hasEligibleRoles() else {
                    // Report back with the display information for the error page.
                    let errorInfo = EligibilityErrorInfo(name: user.displayName(), roles: user.roles)
                    completion(.failure(.insufficientRole(info: errorInfo)))
                    return
                }
                // reaching this means there's nothing else to do, as the user is eligible to access the store.
                self.resetErrorInfo()
                completion(.success(()))

            case .failure(let error):
                completion(.failure(.unknown(error: error)))
            }
        }
        stores.dispatch(action)
    }

    func lastEligibilityErrorInfo() -> EligibilityErrorInfo? {
        return lastErrorInfo
    }

    /// Removes any stored error information.
    private func resetErrorInfo() {
        lastErrorInfo = nil
    }
}

/// Convenient error class that helps with categorizing errors related to role eligibility checks.
enum RoleEligibilityError: Error {
    /// The user's role is insufficient to manage the store.
    /// Additional information is provided for the error page to display more information.
    case insufficientRole(info: EligibilityErrorInfo)

    /// The user has not yet authenticated with the app.
    /// This should not happen, and may indicate an implementation error.
    case notAuthenticated

    /// Submitted store ID is most likely invalid.
    /// This should not happen, and may indicate an implementation error.
    case invalidStoreId(id: Int64)

    /// An unknown error caused from other sources.
    case unknown(error: Error)
}

// MARK: - Private Methods

private extension RoleEligibilityUseCase {
    /// Load the last ineligible user info from user defaults.
    /// This information is typically used to display error information.
    /// - Returns: A named tuple containing the name and roles of the ineligible user.
    func loadLastErrorInfo() -> EligibilityErrorInfo? {
        guard let errorInfoDictionary = defaults.object(forKey: Constants.eligibilityErrorInfoKey) as? [String: String] else {
            return nil
        }

        return EligibilityErrorInfo(from: errorInfoDictionary)
    }
}

// MARK: - Constants

private extension RoleEligibilityUseCase {
    struct Constants {
        static let eligibilityErrorInfoKey = "wc_eligibility_error_info"
    }
}
