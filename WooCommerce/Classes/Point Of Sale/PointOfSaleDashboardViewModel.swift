import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    // Another option is to inject the product data here, and use the adapter to transform from productData to productList (POS-specific)
    // private let productData: [Data]
    @Published private(set) var productList: [POSProduct]

    init() {
        self.productList = []
    }

    func setup() {
        productList = POSProductAdapter.makePOSProductList()
    }
}
