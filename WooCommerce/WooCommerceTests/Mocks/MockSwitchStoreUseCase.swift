import Foundation
import XCTest

@testable import WooCommerce

/// Mock for `SwitchStoreUseCase`.
///
/// This currently just calls `onCompletion()` with `true` as the `storeChanged` result.
///
final class MockSwitchStoreUseCase: SwitchStoreUseCaseProtocol {

    /// The IDs of stores that `switchStore` was called with.
    private(set) var destinationStoreIDs = [Int64]()
}

/// MARK: - SwitchStoreUseCaseProtocol
extension MockSwitchStoreUseCase {

    func switchStore(with storeID: Int64, onCompletion: @escaping (Bool) -> Void) {
        destinationStoreIDs.append(storeID)

        DispatchQueue.main.async {
            onCompletion(true)
        }
    }
}
