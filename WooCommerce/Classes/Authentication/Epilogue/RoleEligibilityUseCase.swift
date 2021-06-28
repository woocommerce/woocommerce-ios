import Combine
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
    func checkEligibility(for storeID: Int64, completion: @escaping (RoleEligibilityError?) -> Void)

    /// Returns the last error information encountered by the authenticated user.
    func lastEligibilityErrorInfo() -> EligibilityErrorInfo?

    /// Removes any stored error information.
    func reset()
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
        didSet {
            defaults.setValue(lastErrorInfo?.toDictionary(), forKey: Constants.eligibilityErrorInfoKey)
        }
    }

    /// Convenient method that checks whether the current user has previous eligibility errors.
    var isPreviouslyIneligible: Bool {
        lastErrorInfo == nil
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

        checkEligibility(for: storeID) { error in
            guard let error = error else {
                // If the user is eligible, reset the stored error information.
                self.lastErrorInfo = nil
                return
            }

            guard case .insufficientRole(let errorInfo) = error else {
                // For errors other than `insufficientRole` (e.g. network errors), do nothing for now.
                // In case of network errors, it's best to depend on currently available information.
                // i.e., if the user is previously ineligible, then assume they are still ineligible now.
                return
            }

            // store the user information locally.
            self.lastErrorInfo = errorInfo
        }
    }

    func checkEligibility(for storeID: Int64, completion: @escaping (RoleEligibilityError?) -> Void) {
        guard stores.isAuthenticated else {
            // TODO: It's not expected to enter this path. Maybe log something here?
            completion(.notAuthenticated)
            return
        }

        let action = UserAction.retrieveUser(siteID: storeID) { result in
            switch result {
            case .success(let user):
                guard self.isEligible(with: user.roles) else {
                    // Report back with the display information for the error page.
                    let errorInfo = EligibilityErrorInfo(name: user.nickname, roles: user.roles)
                    completion(.insufficientRole(info: errorInfo))
                    return
                }
                // reaching this means there's nothing else to do, as the user is eligible to access the store.
                completion(nil)

            case .failure(let error):
                completion(.unknown(error: error))
            }
        }
        stores.dispatch(action)
    }

    func lastEligibilityErrorInfo() -> EligibilityErrorInfo? {
        return lastErrorInfo
    }

    func reset() {
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

    /// This method does a simple match to check if the provided `roles` contain *any* role defined in
    /// EligibleRole. `roles` from the parameter are lowercased just in case.
    func isEligible(with roles: [String]) -> Bool {
        return roles.firstIndex { EligibleRole.allRoles.contains($0.lowercased()) } != nil
    }
}

// MARK: - Constants

private extension RoleEligibilityUseCase {
    struct Constants {
        static let eligibilityErrorInfoKey = "wc_eligibility_error_info"
    }

    enum EligibleRole: String, CaseIterable {
        case administrator
        case shopManager = "shop_manager"

        /// Convenience method that returns the collection in raw value instead of in enum type.
        static let allRoles: [String] = {
            allCases.map { $0.rawValue }
        }()
    }
}
