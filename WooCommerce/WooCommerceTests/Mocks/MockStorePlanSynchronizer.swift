import Combine
import Yosemite
@testable import WooCommerce

final class MockStorePlanSynchronizer: StorePlanSynchronizing {
    var planState: AnyPublisher<StorePlanSyncState, Never> {
        planStateSubject.eraseToAnyPublisher()
    }

    private let planStateSubject = CurrentValueSubject<StorePlanSyncState, Never>(.notLoaded)

    var site: Site?

    func reloadPlan() {
        // no-op
    }

    func setState(_ state: StorePlanSyncState) {
        planStateSubject.send(state)
    }
}
