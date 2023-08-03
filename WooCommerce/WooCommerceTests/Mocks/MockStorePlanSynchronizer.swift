import Combine
import Foundation
import Yosemite
@testable import WooCommerce

final class MockStorePlanSynchronizer: StorePlanSynchronizing {
    var planStatePublisher: AnyPublisher<StorePlanSyncState, Never> {
        $planState.eraseToAnyPublisher()
    }

    @Published private(set) var planState: StorePlanSyncState = .notLoaded

    var site: Site?

    func reloadPlan() {
        // no-op
    }

    func setState(_ state: StorePlanSyncState) {
        planState = state
    }
}
