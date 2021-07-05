import XCTest
import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

class ReviewOrderViewModelTests: XCTestCase {

    private let productID: Int64 = 1_00

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_productDetailsCellViewModel_returns_correct_item_details() {
        // Given
        let item = makeOrderItem(productID: productID)
        let order = MockOrders().makeOrder(status: .processing, items: [item])
        let product = Product().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)
        let productCellModel = viewModel.productDetailsCellViewModel(for: item)

        // Then
        XCTAssertEqual(productCellModel.name, item.name)
    }
}

private extension ReviewOrderViewModelTests {
    func makeOrderItem(productID: Int64) -> OrderItem {
        OrderItem(itemID: 1,
                  name: "Order Item Name",
                  productID: productID,
                  variationID: 0,
                  quantity: 1,
                  price: NSDecimalNumber(integerLiteral: 1),
                  sku: nil,
                  subtotal: "1",
                  subtotalTax: "1",
                  taxClass: "TaxClass",
                  taxes: [],
                  total: "1",
                  totalTax: "1",
                  attributes: [])
    }
}
