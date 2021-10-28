import Yosemite
@testable import WooCommerce

/// Mock Product Category Store Manager
///
 final class MockProductCategoryStoresManager: DefaultStoresManager {

    /// Set mock responses to be dispatched upon Product Category Actions.
    ///
    var productCategoryResponse: ProductCategoryActionError?

    /// Indicates how many times respones where consumed
    ///
    private(set) var numberOfResponsesConsumed = 0

    init() {
        super.init(sessionManager: SessionManager.testingInstance)
    }

    override func dispatch(_ action: Action) {
        if let productCategoryAction = action as? ProductCategoryAction {
            handleProductCategoryAction(productCategoryAction)
        }
    }

    private func handleProductCategoryAction(_ action: ProductCategoryAction) {
        switch action {
        case let .synchronizeProductCategories(_, _, onCompletion):
            numberOfResponsesConsumed = numberOfResponsesConsumed + 1
            onCompletion(productCategoryResponse)
        default:
            return
        }
    }
}
