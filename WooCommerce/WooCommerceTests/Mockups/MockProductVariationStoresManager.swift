@testable import WooCommerce
@testable import Yosemite

/// Mock Product Variation Store Manager
///
final class MockProductVariationStoresManager: DefaultStoresManager {
    // Allows mocking the result on update
    private let updateResult: Result<ProductVariation, ProductUpdateError>

    init(updateResult: Result<ProductVariation, ProductUpdateError>) {
        self.updateResult = updateResult
        super.init(sessionManager: SessionManager.testingInstance)
    }

    override func dispatch(_ action: Action) {
        if let productVariationAction = action as? ProductVariationAction {
            handleProductVariationAction(productVariationAction)
        }
    }

    private func handleProductVariationAction(_ action: ProductVariationAction) {
        switch action {
        case let .updateProductVariation(_, onCompletion):
            onCompletion(updateResult)
        default:
            fatalError("Not implemented yet")
        }
    }
}
