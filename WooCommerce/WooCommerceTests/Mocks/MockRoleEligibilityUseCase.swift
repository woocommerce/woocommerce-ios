import Yosemite

@testable import WooCommerce

/// Convenient fake class for the RoleEligibilityUseCase protocol.
///
final class MockRoleEligibilityUseCase: RoleEligibilityUseCaseProtocol {
    var syncEligibilityCallCount = 0
    var lastCheckedStoreID: Int64 = -1
    var errorToReturn: RoleEligibilityError? = nil
    var errorInfoToReturn: StorageEligibilityErrorInfo? = nil

    func checkEligibility(for storeID: Int64, completion: @escaping (Result<Void, RoleEligibilityError>) -> Void) {
        lastCheckedStoreID = storeID
        if let error = errorToReturn {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}
