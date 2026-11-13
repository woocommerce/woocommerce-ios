@testable import WooCommerce
@testable import Yosemite

/// Mock Product SKU Validation Store Manager
///
final class MockProductSKUValidationStoresManager: DefaultStoresManager {
    private let existingSKUs: [String]

    init(existingSKUs: [String]) {
        self.existingSKUs = existingSKUs
        super.init(sessionManager: SessionManager.testingInstance)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? ProductAction {
            handleProductVariationAction(action)
        }
    }

    private func handleProductVariationAction(_ action: ProductAction) {
        switch action {
        case let .validateProductSKU(sku, _, onCompletion):
            let isValid = sku.map { existingSKUs.contains($0) == false } ?? true
            MainActor.assumeIsolated {
                onCompletion(isValid)
            }
        default:
            fatalError("Not implemented yet")
        }
    }
}
