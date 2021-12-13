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
            guard let sku = sku else {
                onCompletion(true)
                return
            }
            onCompletion(existingSKUs.contains(sku) == false)
        default:
            fatalError("Not implemented yet")
        }
    }
}
