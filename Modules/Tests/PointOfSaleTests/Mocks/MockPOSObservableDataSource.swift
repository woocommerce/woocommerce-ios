import Foundation
import Observation
import Yosemite

/// Mock implementation for testing and development
@Observable
final class MockPOSObservableDataSource: POSObservableDataSourceProtocol {
    var productItems: [POSItem] = []
    var variationItems: [POSItem] = []
    var isLoadingProducts: Bool = false
    var isLoadingVariations: Bool = false
    var hasMoreProducts: Bool = false
    var hasMoreVariations: Bool = false
    var productError: Error? = nil
    var variationError: Error? = nil

    init() {}

    func loadProducts() {
        // Tests set properties directly - no async behavior needed
    }

    func loadMoreProducts() {
        // Tests set properties directly - no async behavior needed
    }

    func loadVariations(for parentProduct: POSVariableParentProduct) {
        // Tests set properties directly - no async behavior needed
    }

    func loadMoreVariations() {
        // Tests set properties directly - no async behavior needed
    }
}
