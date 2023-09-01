import Yosemite
@testable import WooCommerce

/// Allows mocking for `TaxAction`.
///
final class MockTaxClassStoresManager: DefaultStoresManager {
    private var missingTaxClass: TaxClass?

    init(missingTaxClass: TaxClass?, sessionManager: SessionManager) {
        self.missingTaxClass = missingTaxClass
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let action = action as? TaxAction {
            onTaxAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onTaxAction(action: TaxAction) {
        switch action {
        case .requestMissingTaxClasses(_, let onCompletion):
            onCompletion(missingTaxClass, nil)
        default:
            fatalError("Not available")
        }
    }
}
