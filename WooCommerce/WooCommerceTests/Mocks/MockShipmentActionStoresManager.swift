import Yosemite
@testable import WooCommerce

/// Allows mocking for `ShipmentAction`.
///
final class MockShipmentActionStoresManager: DefaultStoresManager {
    private let syncSuccessfully: Bool

    init(syncSuccessfully: Bool) {
        self.syncSuccessfully = syncSuccessfully
        super.init(sessionManager: SessionManager.testingInstance)
    }

    // MARK: - Overridden Methods
    override func dispatch(_ action: Action) {
        if let action = action as? ShipmentAction {
            onShipmentAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    /// Mock action
    private func onShipmentAction(action: ShipmentAction) {
        switch action {
        case .synchronizeShipmentTrackingData(_, _, let onCompletion):
            if syncSuccessfully {
                onCompletion(nil)
            } else {
                let error = NSError(domain: "Test", code: 400, userInfo: nil)
                onCompletion(error)
            }
        default:
            break
        }
    }
}
