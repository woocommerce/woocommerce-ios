import Yosemite
@testable import WooCommerce

/// Allows mocking for `TaxClassAction`.
///
final class MockTaxClassStoresManager: DefaultStoresManager {
    private var missingTaxClass: TaxClass?

    init(missingTaxClass: TaxClass?, sessionManager: SessionManager) {
        self.missingTaxClass = missingTaxClass
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let action = action as? TaxClassAction {
            onTaxClassAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onTaxClassAction(action: TaxClassAction) {
        switch action {
        case .requestMissingTaxClasses(_, let onCompletion):
            onCompletion(missingTaxClass, nil)
        default:
            fatalError("Not available")
        }
    }
}
